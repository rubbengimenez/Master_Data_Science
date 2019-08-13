# -*- coding: utf-8 -*-
"""
Created on Fri Apr  26 21:06:04 2019

@author: Ruben Gimenez Martin

LIVERPOOL FC - HUDDERSFIELD TOWN
April 26, Friday, 2019
20:00:00 - 21:45:00
"""
import pandas as pd
from pymongo import MongoClient

# setting up the mongo client & importing the liverpool tweets collection
client = MongoClient('localhost', 27017)
db = client['football']
collection = db['liverpool']

# importing collected data base to a pandas data frame
data = pd.DataFrame(list(collection.find({})))

# importing df to a csv file
data.to_csv('liverpool.csv')
