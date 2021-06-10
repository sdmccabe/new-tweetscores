# Updated Twitter-based ideal points (2021)

This repository hosts code and data for a new set of Twitter-based ideal points,
calculated using the correspondence-analysis-based method developed by Pablo
Barberá in his *Psychological Science*
[paper](https://journals.sagepub.com/doi/10.1177/0956797615594620). We use the
streamlined method he documents in his [2020
update](https://github.com/pablobarbera/twitter_ideology/tree/master/2020-update). 

As input, we use a snapshot of following data from the Lazer Lab's panel of
Twitter users. The snapshot was collected from September 19, 2020 to January
7, 2021. The composition of the panel, details on its construction, and other
details can be found in [Hughes et al
2021](https://sdmccabe.github.io/files/hughes_constructing_2020.pdf) and
[Shugars et al 2021](https://journalqd.org/article/view/2570).

The elite-level ideal points (φ in the original paper) are stored in this
repository. The user-level ideal points (θ) are not (we generally don't post the
user IDs of the panel members, and also the full dataset is too large to commit
to Github).

The key file, `data/elites_combined_with_phi.tsv`, has the following columns:
* `meta_id`: a single identifier for individuals with multiple Twitter accounts.
* `user_id`: the ID for the Twitter account.
* `screen_name`: the handle for the Twitter account.
* `phi`: The first dimension of the ideal point.
* `phi_2`: The second dimension of the ideal point.
* `followers`: The number of _in-sample_ accounts following the user.
* `voteview_id`: If the target is a Member of Congress, their VoteView ID (for joining in, e.g., NOMINATE data).

There are a series of binary columns representing the lists each account appeared in. These are:

* `moc_116`: A list of members of the 116th Congress.
* `moc_117`: A list of members of the 117th Congress.
* `pundit`: A list of political pundits, collected for [this working paper](https://www.dropbox.com/s/xv3m14dcfy3pyde/green_masket_MPSA.pdf?dl=0).
* `covid_elite`: A list of political accounts prominent during the COVID-19 pandemic, described in [this preprint](https://arxiv.org/abs/2009.07255).
* `president`: The personal or POTUS account for each of Obama, Trump, and Biden.
* `governor`: A list of state governors.
* `media`: A list of prominent media accounts, seen [here](https://github.com/pablobarbera/twitter_ideology/tree/master/2020-update).
* `candidates`: A list of candidates for office in 2020.
* `official`: A list of Trump administration officials.

These lists are available for individual inspection in `data/source_files`.
