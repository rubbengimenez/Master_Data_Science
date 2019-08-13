# -*- coding: utf-8 -*-
"""
Created on Fri Apr  26 13:48:04 2019

@author: Ruben Gimenez Martin

LIVERPOOL FC - HUDDERSFIELD TOWN
April 26, Friday, 2019
20:00:00 - 21:45:00
"""

from __future__ import absolute_import, print_function

from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream
import tweepy
import json
from pymongo import MongoClient

consumer_key = 'L7KARSeuiQGZgyY157GjuyUyM'
consumer_secret = 'cLR5rYTSoKogR96OxmRHtrAbsNVxWyloWiDzjhRsicJpwOR1tK'
access_token = '473233914-FL7fC3FKNml5GDnSmq1bOzhteI3ZBJKxSbRnSR85'
access_secret = 'BkDJRwIe2QNoblBvkIsXY3WRQSwaYFTZdvk1yfu7MGTx3'


class Simple_Raw_Listener(StreamListener):
    """
    A simple listener that handles tweets that are received from the stream.
    It inserts the tweets in a mongoDB collection of tweets.
    """
    def on_data(self, data):
          try:
              msg = json.loads( data )
              print(msg['text
              client = MongoClient('localhost', 27017)
              db = client['football']
              collection = db['liverpool']
              collection.insert(msg)
              return True
          except BaseException as e:
              print("Error on_data: %s" % str(e))

    def on_error(self, status):
        print(status)

if __name__ == '__main__':
    l = Simple_Raw_Listener()
    auth = OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_secret)
    api = tweepy.API(auth)
    print(api.me().name)
    stream = Stream(auth, l)
    stream.filter(track=['liverpool'])
