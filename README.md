# IDPD ShinyLive Github Page

This branch contains the website used to render data found in the main branch.
 
The way that this repository works is that a ShinyLive application is defined in the folder `app` in Python,it is then built into a full static webpage by running the command:

```
shinylive export app site
```

The repository has the following data structure:

```bash
├── app
│   ├── data
│   │   ├── *.csv
│   │   └── intro.md
│   └── app.py
└── site
```

The bulk of the app is programmed inside of `app.py`, with data being stored locally in the `data` directory - this includes both our `.csv`s as seen in the main branch, as well as `intro.md` which serves as the description text beneath the bulk of the Shiny App.