# -*- coding: utf-8 -*-
"""
Created on Sat Apr  27 13:48:04 2019

@author: Ruben Gimenez Martin

LIVERPOOL FC 5-0 HUDDERSFIELD TOWN
April 26, Friday, 2019
20:00:00 - 21:45:00
"""
import os
import numpy as np
import pandas as pd
from itertools import product

import folium
from folium.plugins import MarkerCluster


import seaborn as sns; sns.set()
import matplotlib.pyplot as plt
from matplotlib import cm

import re
from nltk.corpus import stopwords
import string

from PIL import Image
from wordcloud import WordCloud
import random

from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import preprocessor as p #from the tweet-preprocessor package
# https://github.com/s/preprocessor


# importing the livverpool.csv file which includes the raw data collected by
# the listener previously
raw_path = "data/liverpool.csv"
raw_df = pd.read_csv(raw_path, header = 0, delimiter = ",", low_memory = False)
# importing country country_codes
country_codes_path = "data/country_codes.xlsx"
country_codes = pd.read_excel(country_codes_path, header = 0)


### BASIC ANALYSIS ###
raw_df.shape
raw_df.columns

# languages collected
raw_df.lang.unique()

lang_counts = raw_df.lang.value_counts()
lang_counts = pd.DataFrame({"code":lang_counts.index, "Count":lang_counts.values})
# merging for getting real languages names
lang_counts = pd.merge(lang_counts, country_codes, on = "code")#.loc[:,["language", "Count"]]

# adding log(Counts)
lang_counts["log_Count"] = np.log(lang_counts.Count.values)
lang_counts = lang_counts.sort_values(["Count"]).reset_index()


# plotting a simple barplot
x = np.arange(lang_counts.shape[0])
names = lang_counts.language.values
counts_ticks = lang_counts.Count.values
counts = lang_counts.log_Count.values

plt.figure(figsize=(10,8))
plt.barh(names, counts, edgecolor="grey", color=sns.cubehelix_palette(len(counts),start=.5, rot=-.75))
plt.yticks(x, names, fontsize=10)
plt.xticks(fontsize=10)
plt.title("Tweets Languages (count)", fontsize=15, y= 1.02)
plt.xlabel("Count",fontsize=10)
plt.ylabel("Languages", fontsize=10)
k = -1
for i, v in enumerate(counts):
    k += 1
    label = counts_ticks[k]
    plt.text(v  , i - 0.4 , s = str(label), color = "black", fontsize = 10)
plt.show()

# places
# tweets with place mark
len(raw_df.place[raw_df.place.notnull()])
# saving those places
places = raw_df.place[raw_df.place.notnull()].reset_index().loc[:,["place"]]
places = places.place.values
places_list = []
for i in range(len(places)):
    aux = places[i].split("full_name':")[1].split("', ")[0].split(" '")[1]
    places_list.append(aux)
# saving unique values & counting occurences
places = pd.DataFrame(pd.Series(places_list).value_counts())
places.reset_index(level=0, inplace=True)
places.columns = ["place", "count"]
places.loc[places.place == 'Ngapen, Indonesia', 'place'] = "Ngapa, Indonesia"
places.loc[places.place == 'El Gharbia, Egypt', 'place'] = "Gharbia"
# saving to plot map
# places.to_csv("places_counter.csv", index=False)
### The map should be placed here ###
# setting map
# m = folium.Map(location=[41.796005, 7.170161],zoom_start=2, tiles = "cartodbdark_matter")
# tooltip = 'Times tweeting'
# marker_cluster = MarkerCluster().add_to(m)
# # setting markers
# for i in range(places.shape[0]):
#     g = geocoder.osm(places.iloc[i,0])
# #     print(i)
#     lon = g.osm['x']
#     lat = g.osm['y']
#     coords= [lat, lon]
#     folium.Marker(coords, popup=str(places.iloc[i,1]), tooltip=tooltip, icon=folium.Icon(color='#14F074')).add_to(marker_cluster)

### TEXT ANALYSISI ###
# defining regular expressions to detect emoticon, links, mentions...
emoticons_str = r"""
    (?:
        [:=;] # Eyes
        [oO\-]? # Nose (optional)
        [D\)\]\(\]/\\OpP] # Mouth
        [:)]   # Single smile
        [:(]   # Single frown
        [:):)] # Two smiles
        [:(:(] # Two frowns
        [:):(] # Mix of a smile and a frown
    )"""

regex_str = [
    emoticons_str,
    r'<[^>]+>', # HTML tags
    r'(?:@[\w_]+)', # @-mentions
    r"(?:\#+[\w_]+[\w\'_\-]*[\w_]+)", # hash-tags
    r'http[s]?://(?:[a-z]|[0-9]|[$-_@.&amp;+]|[!*\(\),]|(?:%[0-9a-f][0-9a-f]))+', # URLs

    r'(?:(?:\d+,?)+(?:\.?\d+)?)', # numbers
    r"(?:[a-z][a-z'\-_]+[a-z])", # words with - and '
    r'(?:[\w_]+)', # other words
    r'(?:\S)' # anything else
]

tokens_re = re.compile(r'('+'|'.join(regex_str)+')', re.VERBOSE | re.IGNORECASE)
emoticon_re = re.compile(r'^'+emoticons_str+'$', re.VERBOSE | re.IGNORECASE)

# defining tokenisation functions
def tokenise(s):
    return tokens_re.findall(s)

def text_preprocess(s, lowercase=False):
    tokens = tokenise(s)
    if lowercase:
        tokens = [token if emoticon_re.search(token) else token.lower() for token in tokens]
    return tokens

# selecting texts, for practical reasons, only tweets in English will be chosen
text = raw_df[raw_df.lang == "en"].reset_index()
text = text.text
# tweets sample example
text[1917:19145]

text = text.tolist()
# going for the tokenisation process
tokenised_text = []
for i in range(len(text)):
    tokenised_text.extend(text_preprocess(text[i]))

len(tokenised_text)

# removing stopwords using nltk library
text_clean = [word for word in tokenised_text if word not in stopwords.words("english")]

# a bit of manual process to remove puntuation signs...
puntuation = ["!",".",":", "&", "|", ",", "?", "/", "-", "+" ,"'", ")", "(","[","]","{","}", "=", "’", "…", ";", " ", "I"]
text_clean_2 =  [word for word in text_clean if word not in puntuation]

# and now doing the same for links, which won't be analysed
link = "https"
text_clean_3 = [word for word in text_clean_2 if link not in word]


# semicolon must be implented in punctuations removal!!!
# remove digits in this case
aux = [x for x in text_clean_3 if not any(c.isdigit() for c in x)]
text_clean_count = pd.Series(aux).value_counts()

def counter_plotter(data, values, title = "", xlab = "Count", ylab = ""):
    """
    data arg must be a pandas series
    """
    aux = data[0:values].sort_values()
    x = np.arange(aux.shape[0])
    names = aux.index
    counts = aux.values
    plt.figure(figsize=(10,8))
    plt.barh(names, counts, edgecolor="grey", color=sns.cubehelix_palette(len(counts),start=.5, rot=-.75))
    plt.yticks(x, names, fontsize=10)
    plt.xticks(fontsize=10)
    plt.title(title, fontsize=15, y= 1.02)
    plt.xlabel(xlab,fontsize=10)
    plt.ylabel(ylab, fontsize=10)
    for i, v in enumerate(counts):
        plt.text(v  , i - 0.4 , s = str(v), color = "black", fontsize = 10)
    plt.show()

counter_plotter(data = text_clean_count, values = 29, title = "Most used words", ylab = "Words")

# checking main hashtags used
hash = "#"
hastags = [word for word in text_clean_3 if hash in word]
hastags = pd.Series(hastags).value_counts()
counter_plotter(data = hastags, values = 29, title = "Most used hastags", ylab = "Hashtags")

# same for users mentioned
at = "@"
users = [word for word in text_clean_3 if at in word]
users = pd.Series(users).value_counts()
counter_plotter(data = users, values = 29, title = "Most mentioned users", ylab = "Users")

with open("data/textwordcloud.txt", "w", encoding="utf-8") as output:
    output.write(str(text_clean_3))

## Word Cloud ##
# defining colour function, red colors will be OBVIOUSLY used
def red_color_func(word, font_size, position, orientation, random_state=None,
                    **kwargs):
    return "hsl(357, 100%%, %d%%)" % random.randint(60, 100)


d = path.dirname(__file__) if "__file__" in locals() else os.getcwd()
mask = np.array(Image.open(os.path.join(d, "data/logo5.png")))

text = open(os.path.join(d, 'data/textwordcloud.txt'), encoding="utf-8").read()

wc  = WordCloud(max_words=1000, mask=mask, margin=10, random_state=1).generate(text)


default_colors = wc.to_array()
plt.imshow(wc.recolor(color_func=red_color_func, random_state=3), interpolation="bilinear")
wc.to_file("WordCloud4.ng")

## Sentiment Analysis ##
p.set_options(p.OPT.URL, p.OPT.MENTION, p.OPT.RESERVED)
p.clean(prueba)
analyser = SentimentIntensityAnalyzer()

text = raw_df[raw_df.lang == "en"].reset_index()
time_stamp = text.created_at.tolist()
text = text.text
text = text.tolist()
negative = []
neutral = []
positive = []
compound = []
for i in range(len(text)):
    aux = analyser.polarity_scores(p.clean(text[i]))
    negative.append(aux["neg"])
    neutral.append(aux["neu"])
    positive.append(aux["pos"])
    compound.append(aux["compound"])

sentiments = pd.DataFrame()
sentiments["time"] = time_stamp
sentiments["text"] = text
sentiments["negative"] = negative
sentiments["netural"] = neutral
sentiments["positive"] = positive
sentiments["Compound"] = compound
sentiments.head(10)

# let's observe sentiment behaviour through time
# it must be kept in mind that data comes time-sorted by default
# group data by time using the mean statistic
sentiments = sentiments.iloc[:,[0,2,3,4,5]]
sentiments_grouped = sentiments.groupby(["time"]).mean().reset_index()
sentiments_grouped.columns

compound = sentiments_grouped.Compound.values
plt.figure(figsize=(10,8))
sns.set_style("darkgrid")
plt.title("Compound index of the sentiment analysis", size = 14)
plt.plot(compound, color = "#d84b4b")
plt.xticks([])
plt.ylabel("Index", fontsize=10)
plt.axhline(y=0.0, color='#232121', linestyle='-')
plt.show()

# cummulative sum of sentiments
cum_sum = pd.DataFrame(sentiments_grouped.iloc[:,[1,3]].sum(axis = 0)).reset_index()
cum_sum.columns = ["sentiment", "cum"]
#pie plot
labels = cum_sum.sentiment.values
sizes = cum_sum.cum.values
colors = ["#d87272", "#91d872"]
#Plot
plt.figure(figsize=(10,8))
plt.pie(sizes, labels=labels, colors=colors,autopct='%1.1f%%', shadow=True, startangle=140)
plt.title("Polarity Distribution (only positive or negative)", fontsize=14)
plt.axis('equal')
plt.show()
