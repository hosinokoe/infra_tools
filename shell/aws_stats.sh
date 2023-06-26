#!/bin/bash
#
# usage: Get statistics of my aws instances
# example：./aws_stats.sh noprod prod
#

ec2_sort() {
  origin=`aws --profile $1 ec2 describe-instances --filter Name=instance-state-name,Values=running`
  item=(`echo $origin|grep KeyName |awk -F- '{print$2}'|sort|uniq`)
  for i in $item;do echo -n "$i ";echo $origin | jq -r ".Reservations[].Instances[]|select(.SecurityGroups[].GroupName | contains(\"$i\"))|.InstanceType" |sort|uniq -c;done
}

ec2_sort_new() {
  # account=($(echo "$@"))
  for i in $@;do
    echo $i ec2
    origin=`aws --profile $i ec2 describe-instances --filter Name=instance-state-name,Values=running`
    echo $origin | jq -r '.[][]|.Instances[]|[.InstanceType, .PlatformDetails]|@tsv' |sort -k2|uniq -c
  done
}

rds_sort() {
  for i in $@;do
    echo $i rds
    origin=`aws --profile $i rds describe-db-instances`
    echo $origin | jq -r '.DBInstances[]|[.DBInstanceClass, .MultiAZ, .Engine]|@tsv'|sort -k1 -k3|uniq -c
  done
}

elasticache_sort() {
  for i in $@;do
    echo $i elasticache
    origin=`aws --profile $i elasticache describe-cache-clusters`
    echo $origin | jq -r '.[][]|[.CacheNodeType, .NumCacheNodes]|@tsv'|sort -k1 | uniq -c
  done
}

# ec2_sort_new $@
# rds_sort $@
# elasticache_sort $@

echo "Enter your choice ==> "
echo "What do you do?"

select answer in ec2 rds elasticache;do
case $answer in
  ec2)
    ec2_sort_new $@;;
  rds)
    rds_sort $@;;
  elasticache)
    elasticache_sort $@;;
  none)
    break;;
  *)
    ec2_sort_new $@
    rds_sort $@
    elasticache_sort $@;;
esac;done
  
