#!/usr/bin/python3

import configparser, argparse, datetime
from base import ec2_info_new, instance_count_new, data_split, instance_split, instance_merge, to_excel_new
from base import rds_info_new, ri_ec2, ri_merge, ri_buy, ri_rds, redis_info, ri_redis, opensearch_info, ri_es

parser = argparse.ArgumentParser(description='Get RI purchase info!')
parser.add_argument('-A', dest='func_name', metavar=('func_name'), help='ec2 or rds')

args = parser.parse_args()
func_name = args.func_name
config = configparser.ConfigParser()
config.read('config.ini')

# 批量赋值，变量名在config.ini中
for k,v in config['config'].items():
  globals()[k] = v.split(',')

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


def ec2_info_get():
  ec2_infos, ec2_infos_change = ec2_info_new(profile)
  ec2_infos_linux = instance_count_new(ec2_infos, profile)
  data_split(ec2_infos_linux, profile, ec2_type)
  instance_split(ec2_infos_linux, profile, ec2_tmp, 2)
  ec2_data_linux = instance_merge(ec2_infos_linux)
  ec2_infos_win = instance_count_new(ec2_infos_change, profile)
  # print(ec2_infos_win)
  data_split(ec2_infos_win, profile, ec2_type)
  ec2_data_win = instance_merge(ec2_infos_win)
  # print(ec2_data_linux)
  # print(ec2_data_win)

  ri_ec2_info = ri_ec2()
  ri_ec2_infos = ri_merge(ri_ec2_info)
  ec2_ri_buy = ri_buy(ri_ec2_infos, ec2_data_linux, ec2_data_win)

  print('ec2_ri_buy:', ec2_ri_buy)
  return ec2_ri_buy

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

def rds_info_get():
  rds_infos = rds_info_new(profile)
  rds_infos_new = instance_count_new(rds_infos, profile)
  instance_split(rds_infos_new, profile, rds_tmp, 3)
  rds_data = instance_merge(rds_infos_new)
  # print(rds_data)
  ri_rds_info = ri_rds()
  ri_rds_infos = ri_merge(ri_rds_info)
  # print(rds_data)
  rds_ri_buy = ri_buy(ri_rds_infos, rds_data)

  print('rds_ri_buy:', rds_ri_buy)
  return rds_ri_buy

def redis_info_get():
  redis_infos = redis_info(profile)
  redis_data = instance_merge(redis_infos)
  # print(redis_data)
  ri_redis_info = ri_redis()
  ri_redis_infos = ri_merge(ri_redis_info)
  # print(ri_redis_infos)
  redis_ri_buy = ri_buy(ri_redis_infos, redis_data)

  print('redis_ri_buy:', redis_ri_buy)
  return redis_ri_buy

def opensearch_info_get():
  es_infos = opensearch_info(profile)
  es_data = instance_merge(es_infos)
  print(es_data)
  ri_es_info = ri_es()
  ri_es_infos = ri_merge(ri_es_info)
  print(ri_es_infos)
  es_ri_buy = ri_buy(ri_es_infos, es_data)

  print('es_ri_buy:', es_ri_buy)
  return es_ri_buy

def all_info_get():
  ec2_info = ec2_info_get()
  rds_info = rds_info_get()
  redis_info = redis_info_get()
  es_info = opensearch_info_get()
  file = 'AWS_RI'+datetime.datetime.now().isoformat()[:10]+'.xlsx'
  to_excel_new(ec2_info, file, 'EC2_Flexible_RI', ec2_columns, 'w')
  to_excel_new(rds_info, file, 'RDS_Inflexible_RI', rds_columns)
  to_excel_new(redis_info, file, 'Redis_Inflexible_RI', redis_columns)
  to_excel_new(es_info, file, 'Opensearch_Inflexible_RI', es_columns)


def execute_fuction(func_name):
  return{
    'ec2': lambda: ec2_info_get(),
    'rds': lambda: rds_info_get(),
    'redis': lambda: redis_info_get(),
    'es': lambda: opensearch_info_get(),
    'all_np': lambda: [ec2_info_get(), rds_info_get(), redis_info_get(), opensearch_info_get()],
    'all': lambda: [all_info_get()],
  }[func_name]()

execute_fuction(func_name)
# redis_info_get()