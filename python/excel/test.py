#!/usr/bin/python3

import openpyxl, configparser
import pandas as pd
from pandas import Series, DataFrame
# from openpyxl.styles import Font

config = configparser.ConfigParser()
config.read('config.ini')

for k,v in config['config'].items():
  globals()[k] = v.split(',')

c1, c2, c3, c4, c5 = col
  

def font_demo(path):
  wb = openpyxl.Workbook()
  sheet = wb.active

  df=DataFrame({ c1: r1, c2: r2, c3: r3, c4: r4, c5: r5})
  with pd.ExcelWriter(path) as writer:
      df.to_excel(writer)

font_demo("test.xlsx")