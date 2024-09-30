#!/bin/bash
#

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
  echo $f
  # local tmpfile
  # tmpfile=`mktemp`
  # echo $f > $tmpfile
  echo -n "$1 coverage: "
  aws --profile 9913 ce get-reservation-coverage --time-period Start=$Start,End=$End --filter "$f"|jq -r '.Total.CoverageHours.CoverageHoursPercentage'
  rm -f $tmpfile
}

ri_coverage $1