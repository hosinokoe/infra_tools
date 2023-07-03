#!/usr/bin/python3

import boto3, collections, configparser
config = configparser.ConfigParser()
config.read('config.ini')
profile = config['config']['profile'].split(',')
ec2_type = config['config']['ec2_type'].split(',')

tb,tb2,tb4,mb,mb2,mb4,cb,cb2,cb4 = ec2_type
tmp = {
  tb: [tb, 1],
  tb2: [tb, 2],
  tb4: [tb, 4],
  mb: [mb, 1],
  mb2: [mb, 2],
  mb4: [mb, 4],
  cb: [cb, 1],
  cb2: [cb, 2],
  cb4: [cb, 4]
}

# t = {
#   'linux': [0,2],
#   'win': [2,]
#   }

# 删除无关实例&账号ID
def data_split(data):
  unwanted = [2]
  for p in profile:
    b = data[p]
    for i in b:
      if i[1] not in ec2_type:
        b.pop(b.index(i))
      for j in sorted(unwanted, reverse = True):
        del i[j]

# 修改可变实例为基础实例
def ec2_split(data):
  for p in profile:
    for i in data[p]:
      i[2] *= tmp[i[1]][1]
      i[1] = tmp[i[1]][0]

# 统计可变linux总数
def ec2_merge(data):
  tmp = collections.defaultdict(int)
  b = []
  for k,v in data.items():
    for i in v:
      b.append(i)
  for j,k,l in b:
    tmp[j,k] += l
  return tmp

# ec2原始数据去重
def ec2_dedup(mylist):
  seen = set()
  newlist = []
  for i in mylist:
    t = tuple(i)
    if t not in seen:
      newlist.append(i)
      seen.add(t)
  return newlist

# 统计同一账号的ec2数量, k发生变化，因此newlist也跟着变化，不用再生成新的list
def ec2_count(mylist, newlist):
  ec2_type = set(i[1] for i in mylist)
  for i in ec2_type:
    c_count = sum(j.count(i) for j in mylist)
    for k in newlist:
      if k[1] == i:
        k.append(c_count)
  return newlist

def ec2_count_new(mylist):
  new_count = {}
  for p in profile:
    ec2_type = set(i[1] for i in mylist[p])
    newlist = ec2_dedup(mylist[p])
    for i in ec2_type:
      c_count = sum(j.count(i) for j in mylist[p])
      for k in newlist:
        if k[1] == i:
          k.append(c_count)
    new_count[p] = newlist
  return new_count
        
# 返回所有账号的ec2 linux服务器的元信息
def ec2_info_new():
  ec2_info = {}
  ec2_info_change = {}
  for p in profile:
    ec2_origin = []
    ec2_origin_change = []
    session = boto3.Session(profile_name = p)
    ec2 = session.client('ec2')
    response = ec2.describe_instances()
    for i in response['Reservations']:
      for j in i["Instances"]:
        if j["PlatformDetails"]=="Linux/UNIX":
          ec2_origin.append([j["PlatformDetails"], j["InstanceType"], i["OwnerId"]])
          ec2_info[p] = ec2_origin
        else:
          ec2_origin_change.append([j["PlatformDetails"], j["InstanceType"], i["OwnerId"]])
          ec2_info_change[p] = ec2_origin_change
  # print(ec2_info)
  return ec2_info, ec2_info_change

# 元信息
ec2_infos, ec2_infos_change = ec2_info_new()
# print(ec2_infos, ec2_infos_change)

# 单独账号统计 -> 信息裁剪 -> 基础实例转换 -> 账号合并统计
ec2_infos_linux = ec2_count_new(ec2_infos)
data_split(ec2_infos_linux)
ec2_split(ec2_infos_linux)
# ec2_count_new(ec2_infos_linux)
ec2_data_linux = ec2_merge(ec2_infos_linux)

# 单独账号统计 -> 信息裁剪 -> 账号合并统计
# ec2_infos_win = ec2_count_new(ec2_infos_change)
# data_split(ec2_infos_win, 'win')
# ec2_data_win = ec2_merge(ec2_infos_win, 'win')

# 信息打印
print(ec2_infos_linux)
print(ec2_data_linux)
# print(ec2_data_win)