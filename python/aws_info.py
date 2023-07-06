#!/usr/bin/python3

import configparser
from base import ec2_info_new, instance_count_new, data_split, instance_split, instance_merge, to_excel_new
from base import rds_info_new

config = configparser.ConfigParser()
config.read('config.ini')
profile = config['config']['profile'].split(',')
ec2_type = config['config']['ec2_type'].split(',')
ec2_columns = config['config']['ec2_columns'].split(',')
rds_type = config['config']['rds_type'].split(',')
rds_columns = config['config']['rds_columns'].split(',')

# 通过此处的结构将可变换的实例修改为基础实例
tl,tl2,tl4,ml,ml2,ml4,cl,cl2,cl4 = ec2_type
ec2_tmp = {
  tl: [tl, 1],
  tl2: [tl, 2],
  tl4: [tl, 4],
  ml: [ml, 1],
  ml2: [ml, 2],
  ml4: [ml, 4],
  cl: [cl, 1],
  cl2: [cl, 2],
  cl4: [cl, 4]
}


# 元信息
ec2_infos, ec2_infos_change = ec2_info_new(profile)
# print(ec2_infos, ec2_infos_change)

# 单独账号统计 -> 信息裁剪 -> 基础实例转换 -> 账号合并统计
# ec2_infos_linux = ec2_count_new(ec2_infos)
ec2_infos_linux = instance_count_new(ec2_infos, profile)
data_split(ec2_infos_linux, profile, ec2_type)
# print(ec2_infos_linux)
instance_split(ec2_infos_linux, profile, ec2_tmp, 2)
ec2_data_linux = instance_merge(ec2_infos_linux)

# 单独账号统计 -> 信息裁剪 -> 账号合并统计
# ec2_infos_win = ec2_count_new(ec2_infos_change)
ec2_infos_win = instance_count_new(ec2_infos_change, profile)
data_split(ec2_infos_win, profile, ec2_type)
ec2_data_win = instance_merge(ec2_infos_win)


# 信息打印
print(ec2_infos_linux)
print(ec2_infos_win)
print(ec2_data_linux)
print(ec2_data_win)


# for k,v in ec2_data_linux.items():
#   print(k.split(',')+[v])

to_excel_new(ec2_data_linux, 'AWS_RI.xlsx', 'EC2_Flexible_RI', ec2_columns, 'w')
to_excel_new(ec2_data_win, 'AWS_RI.xlsx', 'EC2_Inflexible_RI', ec2_columns)

# 通过此处的结构将可变换的实例修改为基础实例
tm,tl,tl2,tl4,ml,ml2,ml4 = rds_type
rds_tmp = {
  tm: [tm, 1],
  tl: [tl, 1],
  tl2: [tl, 2],
  tl4: [tl, 4],
  ml: [ml, 1],
  ml2: [ml, 2],
  ml4: [ml, 4]
}

# 元信息
rds_infos = rds_info_new(profile)
print(rds_infos)

# 单独账号统计 -> 信息裁剪 -> 基础实例转换 -> 账号合并统计
rds_infos = instance_count_new(rds_infos, profile)
print(rds_infos)

instance_split(rds_infos, profile, rds_tmp, 3)
rds_data = instance_merge(rds_infos)

# 信息打印
print(rds_infos)
print(rds_data)
# print(ec2_data_win)

# to_excel_new(ec2_data_linux, 'AWS_RI.xlsx', 'EC2_Flexible_RI')
to_excel_new(rds_data, 'AWS_RI.xlsx', 'RDS_Inflexible_RI', rds_columns)