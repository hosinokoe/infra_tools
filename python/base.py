#!/usr/bin/python3

import boto3, collections
import pandas as pd
import openpyxl as opx

# 返回所有账号的ec2 linux服务器的元信息
def ec2_info_new(profile):
  ec2_info, ec2_info_change = {}, {}
  for p in profile:
    ec2_origin, ec2_origin_change = [], []
    session = boto3.Session(profile_name = p)
    ec2 = session.client('ec2')
    response = ec2.describe_instances()
    for i in response['Reservations']:
      for j in i["Instances"]:
        if j["PlatformDetails"] == "Linux/UNIX":
          ec2_origin.append([j["PlatformDetails"], j["InstanceType"]])
          ec2_info[p] = ec2_origin
        else:
          ec2_origin_change.append([j["PlatformDetails"], j["InstanceType"]])
          ec2_info_change[p] = ec2_origin_change
  return ec2_info, ec2_info_change

# 原始数据去重
def instance_dedup(mylist):
  seen = set()
  newlist = []
  for i in mylist:
    t = tuple(i)
    if t not in seen:
      newlist.append(i)
      seen.add(t)
  return newlist

# 统计同一账号的instance数量
def instance_count_new(mylist, profile):
  new_count = {}
  for p in profile:
    newlist = instance_dedup(mylist[p])
    # print(newlist)
    for i in newlist:
      c_count = mylist[p].count(i)
      for j in mylist[p]:
        if j == i:
          j.append(c_count)
    new_count[p] = newlist
  return new_count

# 删除ec2实例中不符合要求的实例
def data_split(data, profile, ec2_type):
  for p in profile:
    b = data[p]
    for i in b:
      if i[1] not in ec2_type:
        b.pop(b.index(i))

# 修改可变实例为基础实例
def instance_split(data, profile, origin, order):
  for p in profile:
    for i in data[p]:
      i[order] *= origin[i[1]][1]
      i[1] = origin[i[1]][0]

# 统计可变实例总数
def instance_merge(data):
  tmp = collections.defaultdict(int)
  b = []
  [b.append(i) for k,v in data.items() for i in v]
  # for k,v in data.items():
  #   for i in v:
  #     b.append(i)
  for j in b:
    tmp[','.join(map(str,j[:-1]))]+=j[-1]
  # for j,k,l in b:
  #   tmp[j,k] += l
  return tmp

# 输出excel表格
def to_excel_new(data, file, sheet_name, columns, mode = 'a'):
  # df=pd.DataFrame([[k[0],k[1],v ] for k,v in data.items()],columns=['os_type', 'ec2_type', 'total'])
  df=pd.DataFrame([k.split(',')+[v] for k,v in data.items()],columns=columns)
  with pd.ExcelWriter(file, mode=mode) as writer:
    df.to_excel(writer, sheet_name=sheet_name)
        
# 返回所有账号的rds服务器的元信息，删除oracle信息
def rds_info_new(profile):
  rds_info = {}
  for p in profile:
    rds_origin = []
    session = boto3.Session(profile_name = p)
    rds = session.client('rds')
    response = rds.describe_db_instances()
    for i in response['DBInstances']:
      if i["Engine"] != 'oracle-se2':
        rds_origin.append([i["Engine"], i["DBInstanceClass"], i["MultiAZ"]])
        rds_info[p] = rds_origin
  return rds_info