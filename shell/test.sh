#/bin/bash
#
#

# tmp=$1

tmp=test

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

select answer in create del;do
case $answer in
  create)
    create_file $1;;
  del)
    delete_file;;
esac;done