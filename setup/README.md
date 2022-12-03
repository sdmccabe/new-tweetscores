# Setting up the project

## Setting up the scripts

This assumes python3 and R have been installed in your local evironment.

Once both of them are installed, you can run the following commands to install dependencies (run from the setup directory).

For python, run:

`python3 -m pip install -r requirements.txt`

For R, run:
`r install.R`

Additionally, you need to have secrets for the twitter API. Create a file with this format and replace the text in single quotes:
```text
TWITTER_KEY = 'key goes here'
TWITTER_SECRET_KEY = 'secret key goes here'
```

Do *NOT* put the file in the `new-tweetscores` directory unless you are sure it doesn't get included in your git history.

## Running scripts

Navigate to the `src/` directory.

_NOTE:_ This assumes the secret keys are 2 directories above the `src/` directory.


```bash
python3 ./00a-rehydrate_norc_data.py ../../keys.txt
r 00b-assemble_elites_files.R
python3 01-construct_panel_elite_matrix.py
r 02-compute_first_stage.R
```

## Running Jupiter Notebooks

This assumes Jupiter notebooks are installed on your system. You may need to make the R kernel accessible to Jupiter notebooks.

See [this page](https://dzone.com/articles/using-r-on-jupyternbspnotebook) for more details, but you *should* be able to do this:

```bash
sudo R
IRkernel::installspec(user = FALSE)
quit()
```

This opens the R repl, sets the R runtime to *not* be exclusive to the user account, and exits the repl. This is necessary because Jupiter will be running in your browser.

Then, in the `src/` directory, run:

```bash
jupyter notebook
```

Now, you can open the link displayed in the terminal.
