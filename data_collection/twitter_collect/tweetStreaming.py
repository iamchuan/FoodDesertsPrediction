import tweepy
import time
import json
from streamWriter import MyStreamWriter


dbName = 'tweets.db'
tableName = 'tweetTable'
tableSchema = ['created_at',
               'geo',
               'id_str',
               'place',
               'retweet_count',
               'favorite_count',
               'source',
               'text',
               'user_description',
               'user_followers_count',
               'user_friends_count',
               'user_id_str',
               'user_location',
               'user_name',
               'user_time_zone']


class MyStreamListener(tweepy.StreamListener):

    def on_connect(self):
        self.writer = MyStreamWriter(dbName, tableName, tableSchema)

    def on_status(self, status):
        ## Create tableValue
        tableValue = list()
        for key in tableSchema:
            if key.find('user_') == 0:
                k1, k2 = key.split('_', 1)
                tableValue.append(unicode(status.__dict__[k1].__dict__[k2])
                                  .encode('ascii', 'ignore')
                                  .replace('"','')
                                  .strip())
            else:
                tableValue.append(unicode(status.__dict__[key])
                                  .encode('ascii', 'ignore')
                                  .replace('"','')
                                  .strip())
        ## Insert values into table
        print(status.id_str)
        try:
            self.writer.stream_in(tableValue)
        except:
            pass

    def on_error(self, status_code):
        if status_code == 420:
            print('error code: 420')
            pass
            # returning False in on_data disconnects the stream
            # return False


if __name__ == '__main__':
    ## Set auth
    with open('credentials.json', 'r') as f:
        credentials = json.load(f)

    auth = tweepy.OAuthHandler(credentials['consumer_token'], 
                               credentials['consumer_secret'])
    auth.set_access_token(credentials['access_token'], 
                          credentials['access_token_secret'])
    
    ## Init stream
    myStream = tweepy.Stream(auth=auth, listener=MyStreamListener())
    
    ## Read food list
    with open('./FoodList_cleaned.txt', 'rb') as f:
        food_list = [line.strip() for line in f]
    ## Start streaming
    while True:
        try:
            myStream.filter(track=food_list, languages=['en'], async=False)
        except:
            myStream.disconnect()
            time.sleep(60)
