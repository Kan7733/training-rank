import re
import MeCab
import pandas as pd
import os
import sys
import psycopg2
from statistics import mean
#from datetime import datetime,timedelta

DB_HOST = os.environ['DB_HOST']
DB_PORT = os.environ['DB_PORT']
DB_NAME = os.environ['DB_NAME']
DB_USER = os.environ['DB_USER']
DB_PASS = os.environ['DB_PASS']

def get_connection():
    return psycopg2.connect('postgresql://{user}:{password}@{host}:{port}/{dbname}'
        .format(
            user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT, dbname=DB_NAME
        ))

pn_df = pd.read_csv('./pn_ja.dic',\
                    sep=':',
                    encoding='utf-8',
                    names=('Word','Reading','POS', 'PN')
                   )

def get_diclist(text):
  #print("".join(row))
  parsed = m.parse("".join(text))
  lines = parsed.split('\n')
  lines = lines[0:-2]
  diclist = []
  #print(lines)
  for word in lines:
    l = re.split('\t|,',word)
    d = {'Surface':l[0], 'POS1':l[1], 'POS2':l[2], 'BaseForm':l[5]}
    diclist.append(d)
  return diclist

def add_pnvalue(diclist_old):
    diclist_new = []
    for word in diclist_old:
        base = word['BaseForm']        # 個々の辞書から基本形を取得
        if base in pn_dict:
            pn = float(pn_dict[base])  # 中身の型があれなので
        else:
            pn = 'notfound'            # その語がPN Tableになかった場合
        word['PN'] = pn
        diclist_new.append(word)
    return(diclist_new)

def get_pnmean(diclist):
    pn_list = []
    for word in diclist:
        pn = word['PN']
        if pn != 'notfound':
            pn_list.append(pn)  # notfoundだった場合は追加もしない            
    if len(pn_list) > 0:        # 「全部notfound」じゃなければ
        pnmean = mean(pn_list)
    else:
        pnmean = 0              # 全部notfoundならゼロにする
    return(pnmean)


word_list = list(pn_df['Word'])
pn_list = list(pn_df['PN'])  # 中身の型はnumpy.float64
pn_dict = dict(zip(word_list, pn_list))


m = MeCab.Tagger('')
conn = get_connection()
cur = conn.cursor()
cur.execute("select contents from tbl_creatine;")
rows = cur.fetchall()
for i in range(len(rows)):
  rows[i] = "".join(rows[i]).replace('\n','')

ave=0.0

for row in rows:
  num = get_diclist(row)
  num = add_pnvalue(num)
  pnmean = get_pnmean(num)
  ave += pnmean
  if not pnmean > 0:
    print(row)
    #print(pnmean)
print(len(rows))
print(ave/len(rows))
cur.close()
conn.close()
