#!/usr/bin/python3

import uvicorn
from fastapi import FastAPI
from enum import Enum
from aws_info2 import ec2_info_get, rds_info_get, redis_info_get, opensearch_info_get

app = FastAPI()

class ec2_data(str, Enum):
  linux = "linux"
  win = "win"
  ri = "ri"
  all = "all"

@app.get("/ec2/{ec2_data}")
async def get_ec2_info(ec2_data: ec2_data):
  ec2_data_linux, ec2_data_win, ec2_ri_buy = ec2_info_get()
  tmp = {}
  for n in ['ec2_data_linux', 'ec2_data_win', 'ec2_ri_buy']:
    tmp[n] = dict(locals()[n])
  data = {'ec2': tmp}
  def f(ec2_data):
    return {
      'all': data,
      'linux': data['ec2']["ec2_data_linux"],
      'win': data['ec2']["ec2_data_win"],
      'ri': data['ec2']["ec2_ri_buy"]
    }[ec2_data]
  return f(ec2_data)

@app.get("/rds")
async def get_rds_info():
  rds_data, ri_rds_infos, rds_ri_buy = rds_info_get()
  tmp = {}
  for n in ['rds_data', 'ri_rds_infos', 'rds_ri_buy']:
    tmp[n] = dict(locals()[n])
  data = {'rds': tmp}
  return data

@app.get("/redis")
async def get_redis_info():
  redis_data, ri_redis_infos, redis_ri_buy = rds_info_get()
  tmp = {}
  for n in ['redis_data', 'ri_redis_infos', 'redis_ri_buy']:
    tmp[n] = dict(locals()[n])
  data = {'rds': tmp}
  return data

@app.get("/es")
async def es():
  es_data, ri_es_infos, es_ri_buy = opensearch_info_get()
  tmp = {}
  for n in ['es_data', 'ri_es_infos', 'es_ri_buy']:
    tmp[n] = dict(locals()[n])
  data = {'elaticache': tmp}
  return data


if __name__ == "__main__":
  uvicorn.run(app, host="127.0.0.1", port=5049)