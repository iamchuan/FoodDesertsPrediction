import pandas as pd
import sqlite3
import json


def get_geo_tweets(dbPath):
    con = sqlite3.connect(dbPath)
    df = pd.read_sql_query('SELECT * FROM tweetTable WHERE geo != "None"', con)
    get_coordinate = lambda x: json.loads(x.replace("'", "\"").replace('u', ''))[u'coordinates']
    coord = pd.DataFrame(df.geo.map(get_coordinate).tolist(), columns=['lat', 'lon'])
    con.close()
    print 'table size: ', df.size
    tbl = pd.concat([df, coord], axis=1)
    tbl.drop('geo', axis=1, inplace=True)
    return tbl