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

ec2_sort_new() {
  for i in $@;do
    echo $i ec2
    origin=`ec2_cli $i`
    echo $origin | jq -r '.[][]|.Instances[]|[.InstanceType, .PlatformDetails]|@tsv' |sort -k2|uniq -c
    echo -e "\n"
  done
}

ec2_ri() {
  echo 9913 ec2_ri
  origin=`aws --profile 9913 ec2 describe-reserved-instances`
  echo -e $origin |TZ=Asia/Shanghai jq -r '.[][]|select(.State=="active")|[.InstanceType,.InstanceCount,.ProductDescription,(.End|split("+")[0]+ "Z"|fromdate|strflocaltime("%Y-%m-%dT%H:%M:%S %Z"))]|@tsv'|sort -k3
}

rds_sort() {
  for i in $@;do
    echo $i rds
    origin=`rds_cli $i`
    echo $origin | jq -r '.DBInstances[]|[.DBInstanceClass, .MultiAZ, .Engine]|@tsv'|sort -k1 -k3|uniq -c
    echo -e "\n"
  done
}

rds_count_auto_version_update() {
  for i in $@;do
    echo $i "rds auto_version_update"
    origin=`rds_cli $i`
    echo $origin | jq '.[][]|select(.AutoMinorVersionUpgrade==true)|[.DBInstanceIdentifier]|@tsv'|awk -F\- '{print$3}'|tr a-z A-Z|uniq
    echo -e "\n"
  done
}

rds_ri() {
  echo 9913 rds_ri
  origin=`aws --profile 9913 rds describe-reserved-db-instances`
  echo -e $origin |TZ=Asia/Shanghai jq -r '.[][]|select(.State=="active")|[.DBInstanceClass,.DBInstanceCount,.ProductDescription,.MultiAZ,(.StartTime|split(".")[0]+ "Z"|fromdate + (60*60*24*365*2)| strflocaltime("%Y-%m-%dT%H:%M:%S %Z"))]|@tsv'|sort -k3
}

elasticache_sort() {
  for i in $@;do
    echo $i elasticache
    origin=`redis_cli $i`
    echo $origin | jq -r '.[][]|[.CacheNodeType, .NumCacheNodes]|@tsv'|sort -k1 | uniq -c
    echo -e "\n"
  done
}

redis_count_auto_version_update() {
  for i in $@;do
    echo -e $i "elasticache auto_version_update"
    origin=`redis_cli $i`
    echo $origin | jq '.[][]|select(.AutoMinorVersionUpgrade==true)|[.CacheClusterId]|@tsv'|awk -F\- '{print$3}'|tr a-z A-Z|uniq
    echo -e "\n"
  done
}

ri_coverage() {
  echo 9913 ri_coverage
  Start=`date +%Y-%m-%d -d '-2day'`
  End=`date +%Y-%m-%d -d '-1day'`
  origin=`aws --profile 9913 ce get-reservation-coverage --time-period Start=$Start,End=$End`
  echo $origin|jq '.CoveragesByTime[]'
}

echo "Enter your choice ==> "
echo "What do you do?"

select answer in ec2 ec2_ri rds rds_count_update rds_ri elasticache elasticache_count_update count_update ri_coverage;do
case $answer in
  ec2)
    ec2_sort_new $@;;
  ec2_ri)
    ec2_ri;;
  rds)
    rds_sort $@;;
  rds_ri)
    rds_ri;;
  rds_count_update)
    rds_count_auto_version_update $@;;
  elasticache)
    elasticache_sort $@;;
  elasticache_count_update)
    redis_count_auto_version_update $@;;
  count_update)
    rds_count_auto_version_update $@
    redis_count_auto_version_update $@;;
  ri_coverage)
    ri_coverage;;
  none)
    break;;
  *)
    ec2_sort_new $@
    rds_sort $@
    elasticache_sort $@;;
esac;done
  
