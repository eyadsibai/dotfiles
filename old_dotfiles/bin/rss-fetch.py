#!/bin/python

import urllib.request
import re
import sys

if  len(sys.argv) < 1 < len(sys.argv):
    raise Exception("number of arguments can only be one")

url = str(sys.argv[1])
req = urllib.request.Request(url)
resp = urllib.request.urlopen(req)
respData = resp.read().decode("utf-8")


# Search for RSS in the HTML
try:
    rss = re.findall(r'channel_id=(.*)"', respData)
    rss = "https://www.youtube.com/feeds/videos.xml?channel_id=" + rss[0]

    print(rss)
# Else search for RSS in the channel name
except:
    try:
        rss = re.findall(r'/channel/(.*)', url)
        rss = "https://www.youtube.com/feeds/videos.xml?channel_id=" + rss[0]
        print(rss)
    except:
        print("Unable to find RSS in the given youtube link")
