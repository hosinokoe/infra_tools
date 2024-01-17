#/bin/bash
#
#

# tmp=$1

tmp=test
j1=$(cat << EOS
{
  "Key": "SERVICE", "Values": [$ser]
}
EOS
)

json=$(cat << EOS
{
  "Dimensions": $j1
}
EOS
)

# 在测试文件夹根据日期顺序生成相应数量的测试文件
create_file() {
  mkdir $tmp
  cd $tmp
  for i in $(seq $1 -1 1);do touch -t $(date -d "-${i}days" +%Y%m%d%H%M) $i;done
}

# 删除测试文件夹10天前的文件
delete_file() {
  cd $tmp
  find . -maxdepth 1 -mtime +10 | xargs -t -i rm {}
}

declare -A service=(
  ['ec2']='Amazon Elastic Compute Cloud - Compute'
  ['redis']='Amazon ElastiCache'
  ['rds']='Amazon Relational Database Service'
  ['es']='Amazon OpenSearch Service'
)
#ser="${service[$1]}"
#f='{ "Dimensions": { "Key": "SERVICE", "Values": ["'$ser'"] } }'
#echo $f
#j2=$(cat <<EOF
#{
#  "Dimensions": {
#    "Key": "SERVICE", "Values": ["$ser"]
#    }
#  }
#EOF
#)
#echo $j2

function ri_coverage()
{
  Start=`date +%Y-%m-%d -d '-2day'`
  End=`date +%Y-%m-%d -d '-1day'`
  local ser="${service[$1]}"
#  echo $ser
  local f='{ "Dimensions": { "Key": "SERVICE", "Values": ["'$ser'"] } }'
#  local tmpfile
#  tmpfile=`mktemp`
#  echo $f > $tmpfile
  echo -n "$1 coverage: "
#  echo -n "$j2"
  aws --profile 9913 ce get-reservation-coverage --time-period Start=$Start,End=$End --filter "$f"|jq -r '.Total.CoverageHours.CoverageHoursPercentage'
#  rm -f $tmpfile
}

sel='ec2 rds redis es all'

select answer in create del ri_coverage;do
case $answer in
  create)
    create_file $1;;
  del)
    delete_file;;
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
esac;done