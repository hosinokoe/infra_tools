#!/usr/bin/python3

import boto3, collections, datetime, jq
from dateutil.tz import tzutc

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


ec2_info_new(['709'])