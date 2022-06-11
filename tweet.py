import tweepy
import pytz
import os
from datetime import datetime,timezone
from pprint import pprint

bearer_token = os.environ['BEARER_TOKEN'] 
tweet_search = 'ベンチプレス'
tweet_max = 10

# 接続
def Client():
    client = tweepy.Client(bearer_token=bearer_token)
    return client

# ツイート検索
def SearchTweets(tweet_search,tweet_max):
    tweets = Client().search_recent_tweets(
            query = tweet_search,
            max_results = tweet_max,
            tweet_fields = ['author_id', 'created_at', 'public_metrics'],
            user_fields = 'profile_image_url',
            expansions = ['author_id', 'attachments.media_keys'],
            media_fields = 'url',
    )

    results = []
    tweets_data = tweets.data
    if tweets_data != None:
        for tweet in tweets_data:
            obj = {}
            obj["tweet_id"] = tweet.id
            obj["text"] = tweet.text
            obj["like_count"] = tweet.public_metrics['like_count']
            obj['author_id'] = tweet.author_id
            obj['created_at'] = change_time_JST(tweet.created_at)
            media_urls = []
            if tweet.attachments is not None:
                for i in range(len(tweets.includes['media'])):
                    for j in range(len(tweet.attachments['media_keys'])):
                        if tweets.includes['media'][i]['media_key'] == tweet.attachments['media_keys'][j]:
                            media_urls.append(tweets.includes['media'][i]['url'])

            obj['media_urls'] = media_urls

            for i in range(len(tweets.includes['users'])):
                if tweet.author_id == tweets.includes['users'][i]['id']:
                    obj['user'] = tweets.includes['users'][i]['name']
                    obj['username'] = tweets.includes['users'][i]['username']
                    obj['profile_image_url'] = tweets.includes['users'][i]['profile_image_url']

            results.append(obj)
    else:
        results.append('')

    return results

def change_time_JST(u_time):
    utc_time = datetime(u_time.year, u_time.month, u_time.day, u_time.hour, u_time.minute, u_time.second, tzinfo=timezone.utc)
    jst_time = utc_time.astimezone(pytz.timezone("Asia/Tokyo"))
    str_time = jst_time.strftime("%Y-%m-%d %H:%M:%S")
    return str_time

# ツイート検索
pprint(SearchTweets(tweet_search, tweet_max))
