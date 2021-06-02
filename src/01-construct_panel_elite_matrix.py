#!/usr/bin/env python
# coding: utf-8
from pathlib import Path
import networkx as nx
from collections import defaultdict
from tqdm import tqdm
import pandas as pd
import scipy.sparse as sp
import numpy as np
import scipy.io as sio

def main():
    political_elites = pd.read_csv("../data/elites_combined_v2.tsv", sep="\t", dtype={'user_id' :'string'})

    ID_TO_META = political_elites.set_index("user_id")['meta_id'].to_dict()

    ALL_TWITTER_IDS = set(list(ID_TO_META.keys()))
    ALL_META_IDS = set(list(ID_TO_META.values()))

    FOLLOWER_DATA = Path("/net/data-backedup/twitter-voters/friends_collect/friends_data/")
    fnames = list(FOLLOWER_DATA.glob("*"))
    PANEL_MEMBERS = set([x.stem for x in fnames])

    rownames = list(sorted(PANEL_MEMBERS))
    colnames = list(sorted(ALL_META_IDS))

    mat = sp.dok_matrix((len(rownames), len(colnames)))

    for fname in tqdm(fnames):
        with open(fname, "r") as fin:
            alters = [x.strip() for x in fin.readlines()]
            alters = [x for x in alters if x in ALL_TWITTER_IDS]
            if alters:
                i = rownames.index(fname.stem)
                for alter in alters:
                    meta = ID_TO_META[alter]
                    j = colnames.index(meta)
                    mat[i, j] = 1
                    
    sio.mmwrite("../data/panel_elites_mat.mtx", mat)

    with open("../data/panel_elites_mat_rownames.txt", "w") as fout:
        for x in rownames:
            fout.write(f"{x}\n")

    with open("../data/panel_elites_mat_colnames.txt", "w") as fout:
        for x in colnames:
            fout.write(f"{x}\n")

if __name__ == "__main__":
    main()


