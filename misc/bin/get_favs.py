#!/usr/bin/python3 -u
"""
Copyright 2015 Michael F. Lamb <http://datagrok.org>
License: AGPLv3+
https://gist.github.com/datagrok/74a71f572493e603919e
ugly one-off script that uses tweepy to dump all favorites (aka "likes")
into a dbm database file, because the twitter-provided data export does
not include them, because their users are not their customers, instead
they are the product they sell to advertisers.

re-running it will update the existing database file.

warning warning: this script uses the since_id and max_id parameters in
an attempt to retrieve only favs unseen since the last run. but the
sequential ids are not assigned to favs, they're assigned to the
original statuses. this means that if you fav a status that is older
than your most recently fav'd status, we won't notice it! this means
that you must periodically run a full re-download of all your favs to
ensure none are missed.  🔥 this is fine.🔥

warning: the twitter api docs caution that "there are limits to the
number of tweets which can be accessed through the API." sooo if you're
a longtime twitter user, maybe some of your favs might be completely
irrecoverable? i dunno.  🔥 this is fine.🔥

to use, create an "application" at apps.twitter.com. put the credentials
it gives you into a creds.py file:


TODO: abstract the storage mechanism to easily swap out dbm for
maildir-like structure, nosql database, whatever

TODO: retrieve all related tweets (in_reply_to_status_id,
quoted_status_id)

TODO: build a local database of tweets from twitter's export and various
retrieval scripts like this one, with local copies of all tweets
necessary to reconstruct conversations I've faved, rt'd, or participated
in.

"""
import tweepy
import dbm
import json
import time

username = "eyadsibai"
consumer_key = "h5jvRlcWiwyFWNHDE8lgxZKOI"
consumer_secret = "DNnT5za2Yz38TFbp3bvQZtGPyi8eJb8GIoxeMrO6f1HbSBpbut"
access_token = "14768431-3KJJvsWC3gtDwrL7a69wOWuErbnPHpRmpzjo2eDvS"
access_token_secret = "RZBBhBc9zafQiPThmjfwMtsvqZoo6UIlPouNG9YSk9dqX"


def get_api():
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_token_secret)
    return tweepy.API(auth, wait_on_rate_limit=True, wait_on_rate_limit_notify=True)


def get_unseen_statuses(api, min_id, max_id):
    if min_id and max_id:
        yield from tweepy.Cursor(api.favorites, username,
                count=200, since_id=max_id, include_entities=True).items()
        yield from tweepy.Cursor(api.favorites, username,
                count=200, max_id=min_id, include_entities=True).items()
    else:
        yield from tweepy.Cursor(api.favorites, username,
                count=200, include_entities=True).items()


def main():
    api = get_api()
    with dbm.open('favs', 'c') as db:
        try:
            max_id = int(max(db.keys()))
            # contrary to docs, twitter finds less than OR EQUAL TO
            # max_id :(
            min_id = int(min(db.keys()))-1
        except ValueError:
            min_id = None
            max_id = None
        print("Looking for favs newer than %s, and also those older than %s" %
                (max_id, min_id))
        for status in get_unseen_statuses(api, min_id, max_id):
            print(status.id)
            db[str(status.id)] = json.dumps(status._json)
            # twitter rate-limits us to 15 requests / 15 minutes, so
            # space this out a bit to avoid a super-long sleep at the
            # end which could lose the connection.
            time.sleep(60*15/(15*200))
        print('Done.')

if __name__ == '__main__':
    main()
