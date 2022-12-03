import tweepy
import pandas as pd
import csv
import numpy as np
import sys

fname = sys.argv[1]
print(fname)

with open(fname, "r") as fin:
    auth = tweepy.OAuthHandler(fin.readline().strip(), fin.readline().strip())
    auth.set_access_token(fin.readline().strip(), fin.readline().strip())

api = tweepy.API(auth, wait_on_rate_limit=True)


def rehydrate(handle):
    if pd.notnull(handle):
        try:
            print(f"looking up {handle}")
            res = api.lookup_users(screen_name=handle)
            if res:
                return res[0]._json['id_str']
        except:
            return pd.NA
    return pd.NA


def rehydrate_candidate_file():
    df1 = pd.read_csv("../data/from_norc/2020_Candidate_List_with_accounts.csv", encoding='latin-1')
    df1 = df1.dropna(axis=1, how='all')

    df1['TwitterA'] = df1['TwitterA'].str.lstrip("https://twitter.com/")
    df1['TwitterB'] = df1['TwitterB'].str.lstrip("https://twitter.com/")

    df1['TwitterA_id'] = df1['TwitterA'].apply(rehydrate)
    df1['TwitterB_id'] = df1['TwitterB'].apply(rehydrate)
    df1 = df1[['candidate_id', 'partyfull', 'name', 'STATE', 'TwitterA', 'TwitterB', 'TwitterA_id', 'TwitterB_id']]
    return df1

def rehydrate_officials_file():
    df2 = pd.read_csv("../data/from_norc/Trump_Adminstration_List_4.5.21.csv")
    df2['handle_id'] = df2['handle'].apply(rehydrate)
    df2['handle2_id'] = df2['handle2'].apply(rehydrate)
    return df2

def rehydrate_governors_file():
    df3 = pd.read_csv("../data/from_norc/governors2020.csv", encoding='latin-1')
    df3 = df3.replace(" ", pd.NA).replace(np.nan, pd.NA)
    df3['Primary_Handle_id'] = df3['Primary_Handle'].apply(rehydrate)
    df3['Secondary_Handle_id'] = df3['Secondary_Handle'].apply(rehydrate)
    df3 = df3.drop(columns=['Unnamed: 7'])
    return df3
    
if __name__ == "__main__":
    df1 = rehydrate_candidate_file()
    df1.to_csv("../data/candidates_2020_rehydrated.tsv", sep="\t", quoting=csv.QUOTE_NONNUMERIC)
    df2 = rehydrate_officials_file()
    df2.to_csv("../data/officials_2020_rehydrated.tsv", sep="\t", quoting=csv.QUOTE_NONNUMERIC)
    df3 = rehydrate_governors_file()
    df3.to_csv("../data/governors_2020_rehydrated.tsv", sep="\t", quoting=csv.QUOTE_NONNUMERIC)
