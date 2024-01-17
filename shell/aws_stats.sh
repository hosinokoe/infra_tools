#!/bin/bash
#
# usage: Get statistics of my aws instances
# example：./aws_stats.sh noprod prod
#

# ec2_sort() {
#   origin=`aws --profile $1 ec2 describe-instances --filter Name=instance-state-name,Values=running`
#   item=(`echo $origin|grep KeyName |awk -F- '{print$2}'|sort|uniq`)
#   for i in $item;do echo -n "$i ";echo $origin | jq -r ".Reservations[].Instances[]|select(.SecurityGroups[].GroupName | contains(\"$i\"))|.InstanceType" |sort|uniq -c;done
# }

ec2_cli() {
  aws --profile $i ec2 describe-instances --filter Name=instance-state-name,Values=running
}

rds_cli() {
  aws --profile $i rds describe-db-instances
}

redis_cli() {
  aws --profile $i elasticache describe-cache-clusters
}

alb_cli() {
  aws --profile $i elbv2 describe-load-balancers
}

account_org() {
  aws --profile $i organizations list-accounts
}

ec2_sort_new() {
  for i in $@;do
    echo $i ec2
    origin=`ec2_cli $i`
    echo $origin | jq -r '.[][]|.Instances[]|[.InstanceType, .PlatformDetails]|@tsv' |sort -k2|uniq -c
    echo ""
  done
}

ec2_ri() {
  echo 9913 ec2_ri
  origin=`aws --profile 9913 ec2 describe-reserved-instances`
  echo -e $origin |TZ=Asia/Shanghai jq -r '.[][]|select(.State=="active")|[(.End|split("+")[0]+ "Z"|fromdate|strflocaltime("%Y-%m-%dT%H:%M:%S %Z")),.InstanceType,.InstanceCount,.ProductDescription]|@tsv'|sort -k1
}

rds_sort() {
  for i in $@;do
    echo $i rds
    origin=`rds_cli $i`
    echo $origin | jq -r '.DBInstances[]|[.DBInstanceClass, .MultiAZ, .Engine]|@tsv'|sort -k1 -k3|uniq -c
    echo ""
  done
}

rds_count_auto_version_update() {
  for i in $@;do
    echo $i "rds auto_version_update"
    origin=`rds_cli $i`
    echo $origin | jq '.[][]|select(.AutoMinorVersionUpgrade==true)|[.DBInstanceIdentifier]|@tsv'|awk -F\- '{print$3}'|tr a-z A-Z|uniq
    echo ""
  done
}

rds_ri() {
  echo 9913 rds_ri
  origin=`aws --profile 9913 rds describe-reserved-db-instances`
  echo -e $origin |TZ=Asia/Shanghai jq -r '.[][]|select(.State=="active")|[(.StartTime|split(".")[0]+ "Z"|fromdate + (60*60*24*365)| strflocaltime("%Y-%m-%dT%H:%M:%S %Z")),.DBInstanceClass,.MultiAZ,.ProductDescription]|@tsv'|sort -k1
}

redis_sort() {
  for i in $@;do
    echo $i elasticache
    origin=`redis_cli $i`
    echo $origin | jq -r '.[][]|[.CacheNodeType, .NumCacheNodes]|@tsv'|sort -k1 | uniq -c
    echo ""
  done
}

redis_ri() {
  echo 9913 redis_ri
  origin=`aws --profile 9913 elasticache describe-reserved-cache-nodes`
  echo -e $origin | TZ=Asia/Shanghai jq -r '.[][]|[(.StartTime|split(".")[0]+ "Z"|fromdate+ (60*60*24*365)|strflocaltime("%Y-%m-%dT%H:%M:%S %Z")),.CacheNodeCount,.CacheNodeType]|@tsv'
}

redis_count_auto_version_update() {
  for i in $@;do
    echo -e $i "elasticache auto_version_update"
    origin=`redis_cli $i`
    echo $origin | jq '.[][]|select(.AutoMinorVersionUpgrade==true)|[.CacheClusterId]|@tsv'|awk -F\- '{print$3}'|tr a-z A-Z|uniq
    echo ""
  done
}

# ri_coverage() {
#   echo 9913 ri_coverage
#   Start=`date +%Y-%m-%d -d '-2day'`
#   End=`date +%Y-%m-%d -d '-1day'`
#   origin=`aws --profile 9913 ce get-reservation-coverage --time-period Start=$Start,End=$End`
#   echo $origin|jq '.CoveragesByTime[]'
# }

declare -A service=(
  ['ec2']='Amazon Elastic Compute Cloud - Compute'
  ['redis']='Amazon ElastiCache'
  ['rds']='Amazon Relational Database Service'
  ['es']='Amazon OpenSearch Service'
)

function ri_coverage()
{
  Start=`date +%Y-%m-%d -d '-2day'`
  End=`date +%Y-%m-%d -d '-1day'`
  local ser="${service[$1]}"
  local f='{ "Dimensions": { "Key": "SERVICE", "Values": ["'$ser'"] } }'
  local tmpfile
  tmpfile=`mktemp`
  echo $f > $tmpfile
  echo -n "$1 coverage: "
  aws --profile 9913 ce get-reservation-coverage --time-period Start=$Start,End=$End --filter "file://$tmpfile"|jq -r '.Total.CoverageHours.CoverageHoursPercentage'
  rm -f $tmpfile
}

accounts() {
  for i in {9913,odp};do
    echo $i accounts
    origin=`account_org $i`
    echo $origin|jq -r '.[][]|.Id'
    echo ""
  done
}

project_count() {
  for i in $@;do
    echo -e $i "project_sum"
    origin=`alb_cli $i`
    echo $origin | jq -r '.[][]|.LoadBalancerName'|awk -F- '{print$3}'|sort -u
    echo $origin | jq -r '.[][]|.LoadBalancerName'|awk -F- '{print$3}'|sort -u|wc -l
    echo ""
  done
}

alarms() {
  for i in $@;do
    echo -e $i "alarms"
    origin=`aws --profile $i cloudwatch describe-alarms --state-value ALARM`
    echo $origin | jq -r '.[][]|.AlarmName,.StateReason'
    echo ""
  done
}

vpc() {
  for i in {noprod,prod,infra,drms,709};do
    echo -e $i "vpcs"
    origin=`aws --profile $i ec2 describe-vpcs`
    echo $origin | jq -r  '.[][]|select(.Tags != null)|"\(.CidrBlock),\(.Tags|from_entries |.Name|ascii_upcase)"'|sort
    echo ""
  done
}

echo "Enter your choice ==> "
echo "What do you do?"

func="ec2 ec2_ri rds rds_ri rds_count_update redis_sort redis_ri redis_count_update count_update ri_coverage accounts project_count alarms vpc"
sel='ec2 rds redis es all'

select answer in $func;do
case $answer in
  ec2_type)
    ec2_sort_new $@;;
  ec2_ri)
    ec2_ri;;
  rds_type)
    rds_sort $@;;
  rds_ri)
    rds_ri;;
  rds_count_update)
    rds_count_auto_version_update $@;;
  redis_sort)
    redis_sort $@;;
  redis_ri)
    redis_ri;;
  redis_count_update)
    redis_count_auto_version_update $@;;
  count_update)
    rds_count_auto_version_update $@
    redis_count_auto_version_update $@;;
  ri_coverage)
    select opt in $sel;do
    case $opt in
      ec2)
        ri_coverage ec2;;
      rds)
        ri_coverage rds;;
      redis)
        ri_coverage redis;;
      es)
        ri_coverage es;;
      all)
        ri_coverage ec2
        ri_coverage rds
        ri_coverage redis
        ri_coverage es;;
      none)
        break;;
    esac;done
    ;;
  accounts)
    accounts;;
  project_count)
    project_count $@;;
  alarms)
    alarms $@;;
  vpc)
    vpc;;
  none)
    break;;
  *)
    ec2_sort_new $@
    rds_sort $@
    redis_sort $@;;
esac;done
  
