#!/bin/bash

declare -A service=(
  ['ec2']='Amazon Elastic Compute Cloud - Compute'
  ['redis']='Amazon ElastiCache'
  ['rds']='Amazon Relational Database Service'
  ['es']='Amazon OpenSearch Service'
)

ser="${service[$1]}"
f='{ "Dimensions": { "Key": "SERVICE", "Values": ["'$ser'"] } }'
echo $f

function generate_filter()
{
  # local server=ElastiCache
  local f='{ "Dimensions": { "Key": "SERVICE", "Values": ["'$ser'"] } }'
  local tmpfile
  tmpfile=`mktemp`
  echo $f > $tmpfile
  # cat $tmpfile
  # echo $tmpfile
  aws --profile 9913 ce get-reservation-coverage --time-period Start='2023-08-08',End='2023-08-09' --filter "file://$tmpfile"|jq -r '.Total.CoverageHours.CoverageHoursPercentage'
  rm -f $tmpfile
}

# generate_filter
aws --profile 9913 ce get-reservation-coverage --time-period Start='2023-08-08',End='2023-08-09' --filter "$f"

