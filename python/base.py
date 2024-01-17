#!/usr/bin/python3

import boto3, collections, datetime
from dateutil.tz import tzutc
import pandas as pd
import openpyxl as opx

# 返回所有账号的ec2服务器的元信息
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
  # print(new_count)
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
  # print(data)
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
  # print(tmp)
  return tmp

# 输出excel表格
def to_excel_new(data, file, sheet_name, columns, mode = 'a'):
  # df=pd.DataFrame([[k[0],k[1],v ] for k,v in data.items()],columns=['os_type', 'ec2_type', 'total'])
  df=pd.DataFrame([k.split(',')+[v] for k,v in data.items()],columns=columns)
  with pd.ExcelWriter(file, mode=mode) as writer:
    df.to_excel(writer, sheet_name=sheet_name)

def ri_ec2():
  RI_now = datetime.datetime.now(tzutc())
  ec2_RI = []
  session = boto3.Session(profile_name = '9913')
  ec2 = session.client('ec2')
  response = ec2.describe_reserved_instances(Filters=[{'Name': 'state', 'Values': ['active']}])
  for i in response['ReservedInstances']:
    if i['End'] - RI_now > datetime.timedelta(days=15):
      ec2_RI.append([i['ProductDescription'],i['InstanceType'],i['InstanceCount']])
  return(ec2_RI)

def ri_rds():
  RI_now = datetime.datetime.now(tzutc())
  rds_RI = []
  session = boto3.Session(profile_name = '9913')
  ec2 = session.client('rds')
  response = ec2.describe_reserved_db_instances()
  for i in response['ReservedDBInstances']:
    if i['ProductDescription'] == 'postgresql':
      i['ProductDescription'] = 'postgres'
    if i['State'] == 'active' and RI_now - i['StartTime'] < datetime.timedelta(days=350):
      rds_RI.append([i['ProductDescription'],i['DBInstanceClass'],i['MultiAZ'],i['DBInstanceCount']])
  return(rds_RI)

def ri_merge(data):
  tmp = collections.defaultdict(int)
  for j in data:
    tmp[','.join(map(str,j[:-1]))]+=j[-1]
  # print(tmp)
  return tmp

# 需要购买的RI统计
def ri_buy(ri, *args):
  tmp = collections.defaultdict(int)
  for i in args:
    tmp.update(i)
  ri_tobuy = collections.defaultdict(int, {k: tmp[k] - ri[k] for k in tmp})
  # print('ri_tobuy:', ri_tobuy)
  return ri_tobuy

# 查询redis offer id，购买RI
def ri_buy_redis(ri):
  session = boto3.Session(profile_name = '9913')
  redis = session.client('elasticache')
  for k,v in ri.items():
    if v > 0:
      response = redis.describe_reserved_cache_nodes_offerings(
        CacheNodeType=k,
        Duration='31536000',
        ProductDescription='redis',
        OfferingType='No Upfront',
        )
      offer_id = response['ReservedCacheNodesOfferings'][0]['ReservedCacheNodesOfferingId']
      print('redis_offer_id: ', offer_id)
      ri_buy = redis.purchase_reserved_cache_nodes_offering(
        ReservedCacheNodesOfferingId=offer_id,
        CacheNodeCount=v,
        )
      print(ri_buy)
    else:
      print('no need to buy redis ri!')



# 返回所有账号的rds服务器的元信息，删除oracle信息
def rds_info_new(profile):
  rds_info = {}
  for p in profile:
    rds_origin = []
    session = boto3.Session(profile_name = p)
    rds = session.client('rds')
    response = rds.describe_db_instances()
    for i in response['DBInstances']:
      if i["Engine"] != 'oracle-se2' and i["Engine"] != 'docdb':
        rds_origin.append([i["Engine"], i["DBInstanceClass"], i["MultiAZ"]])
        rds_info[p] = rds_origin
  return rds_info

# 返回所有账号的elasticache服务器的元信息
def redis_info(profile):
  redis_info = {}
  for p in profile:
    redis_origin = []
    session = boto3.Session(profile_name = p)
    redis = session.client('elasticache')
    response = redis.describe_cache_clusters()
    for i in response['CacheClusters']:
      redis_origin.append([i['CacheNodeType'], i['NumCacheNodes']])
      redis_info[p] = redis_origin
  return redis_info

# 返回所有elasticache目前的RI信息
def ri_redis():
  RI_now = datetime.datetime.now(tzutc())
  redis_RI = []
  session = boto3.Session(profile_name = '9913')
  redis = session.client('elasticache')
  response = redis.describe_reserved_cache_nodes()
  for i in response['ReservedCacheNodes']:
    if i['State'] == 'active' and RI_now - i['StartTime'] < datetime.timedelta(days=350):
      redis_RI.append([i['CacheNodeType'],i['CacheNodeCount']])
  return(redis_RI)

# 返回所有账号的opensearch服务器的元信息
def opensearch_info(profile):
  opensearch_info, tmp = {}, {}
  for p in profile:
    opensearch_name = []
    session = boto3.Session(profile_name = p)
    opensearch = session.client('opensearch')
    response = opensearch.list_domain_names()
    for i in response['DomainNames']:
      opensearch_name.append([i['DomainName']])
      tmp[p] = opensearch_name
  for k,v in tmp.items():
    for i in v:
      es_name = []
      session = boto3.Session(profile_name = k)
      opensearch = session.client('opensearch')
      response = opensearch.describe_domain_config(DomainName=i[0])
      item = response['DomainConfig']['ClusterConfig']['Options']
      es_name.append([item['InstanceType'], item['InstanceCount']])
      opensearch_info[k] = es_name
  return opensearch_info

# 返回所有opensearch目前的RI信息
def ri_es():
  RI_now = datetime.datetime.now(tzutc())
  es_RI = []
  session = boto3.Session(profile_name = '9913')
  es = session.client('opensearch')
  response = es.describe_reserved_instances()
  for i in response['ReservedInstances']:
    if i['State'] == 'active' and RI_now - i['StartTime'] < datetime.timedelta(days=350):
      es_RI.append([i['InstanceType'],i['InstanceCount']])
  return(es_RI)