import tweepy
import pandas as pd
import os
import sys
import psycopg2
from datetime import datetime,timedelta

DB_HOST = os.environ['DB_HOST']
DB_PORT = os.environ['DB_PORT']
DB_NAME = os.environ['DB_NAME']
DB_USER = os.environ['DB_USER']
DB_PASS = os.environ['DB_PASS']
BAERER = os.environ['BEARER_TOKEN']
args = sys.argv
if args[1] == "ベンチプレス":
    tbl = "tbl_benchpress"
elif args[1] == "スクワット":
    tbl = "tbl_squat"
elif args[1] == "デッドリフト":
    tbl = "tbl_deadlift"
elif args[1] == "bcaa":
    tbl = "tbl_bcaa"
elif args[1] == "eaa":
    tbl = "tbl_eaa"
elif args[1] == "クレアチン":
    tbl = "tbl_creatine"
else:
    print(args[1])
    print("augument error")
    exit()
print(args[1])
print(tbl)

query = '{subject} lang:ja -"コード" -"クーポン" -"楽天" -"Amazon" -is:retweet'.format(subject=args[1])
limit = 30000

def get_connection():
    return psycopg2.connect('postgresql://{user}:{password}@{host}:{port}/{dbname}'
        .format(
            user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT, dbname=DB_NAME
        ))

now = datetime.now() #- timedelta(days=5) #開始日を指定
now = now.replace(minute=0, second=0, microsecond=0)
end_time_tweepy = str(now.isoformat())+'+09:00'
start_time = now - timedelta(days=6) #終了日を指定
print(now,start_time)
start_time_tweepy = str(start_time.isoformat())+'+09:00'
print(end_time_tweepy,start_time_tweepy)
client = tweepy.Client(BAERER)

df_tweet = pd.DataFrame()
for tweet in tweepy.Paginator(client.search_recent_tweets, query=query, start_time=start_time_tweepy, end_time=end_time_tweepy,
                              tweet_fields=['id','created_at','text','author_id','lang',], 
                              max_results=100).flatten(limit=limit):
    #print(tweet.text)
    #print(tweet.data)
    tweet.data['text'] = tweet.data['text'].replace("'","''") #sqlで ' がエラーとなるため
    try:
        conn = get_connection()
        cur = conn.cursor()
        cur.execute(f"insert into {tbl} (tweet_id, author_id,created_at, contents) values ({tweet.data['id']},'{tweet.data['author_id']}','{tweet.data['created_at']}','{tweet.data['text']}')")
        conn.commit()
        cur.close()
        conn.close()
    except psycopg2.errors.UniqueViolation as e: #tweet_idが重複した場合のエラー
        print("error")
        print(e)
        cur.close()
        conn.close()
    df_tweet = pd.concat([df_tweet, pd.DataFrame([tweet.data])], ignore_index=True)

print(df_tweet)
print(type(df_tweet))
