from shiny import *
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import urllib

Data = {
    "firstprefcount": pd.read_csv(
        Path(__file__).parent / "data/data_banda_firstpref_counts.csv"
    ),
    "govsatcount": pd.read_csv(
        Path(__file__).parent / "data/data_banda_govsat_counts.csv"
    ),
    "govsatprop": pd.read_csv(
        Path(__file__).parent / "data/data_banda_govsat_prop.csv"
    ),
    "leaderscount": pd.read_csv(
        Path(__file__).parent / "data/data_banda_leaders_counts.csv"
    ),
    "leadersprop": pd.read_csv(
        Path(__file__).parent / "data/data_banda_leaders_prop.csv"
    ),
    "redcprop": pd.read_csv(
        Path(__file__).parent / "data/data_redc_firstpref_prop.csv"
    ),
}

# Data sets available
DataSets = {
    "firstpref": "B&A First Preference Polling",
    "govsat": "B&A Government Satisfaction Polling",
    "leaders": "B&A Party Leader Confidence Polling",
    "redc": "RedC First Preference Polling",
}

# Data presentation modes
DataTypes = {"prop": "Proportional", "count": "Raw Counts"}

# Demographic subsets
Demographics = {
    "total": "Total Population",
    "gender": "Gender",
    "age": "Age",
    "social": "Social Class",
    "region": "Province",
    "urban": "Urban/Rural",
    "num_const": "Constituency Seats",
    "vote_prob": "Likelihood of Voting in a General Election",
    "vote_prev": "Previous General Election Vote",
    "vote_next": "Next General Election Vote"
}

Series = dict(zip(
    Data['firstprefcount']['party'].unique().tolist(),
    Data['firstprefcount']['party'].unique().tolist()
))

app_ui = ui.page_fluid(

    # Header title
    ui.panel_title("Irish Demographic Polling Datasets" , "Irish Demographic Polling Datasets"),

    # Side bar layout
    ui.layout_sidebar(
    
        # Left panel
        ui.panel_sidebar(
            ui.input_date_range(
                "daterange", "Date range:", start="2001-01-01", end="2022-12-31"
            ),
            ui.input_radio_buttons("dataset", "Dataset:", DataSets),
            ui.input_radio_buttons("datatype", "Representation:", DataTypes),
            ui.input_radio_buttons("demographics", "Demographics: ", Demographics)
        ),

        # Main diagram panel
        ui.panel_main(
            ui.output_plot('line'),
        ),

    ),

    # Description
    ui.panel_well(
        ui.input_checkbox_group("series", "Select Series:", Series, inline = True)
    ),
    ui.markdown(
        """

        For more information, please consult our [**Detailed Report and Codebook (PDF)**](https://github.com/Irish-Dem-Polling/irish-demographic-polling-datasets.pdf)

        ### Introduction

        The Irish Demographic Polling Datasets collect aggregated results on vote intentions, satisfaction with the government, and popularity of party leaders. The data are available for all respondents and various subsamples, such as age groups, gender, social class, geographic region, and district magnitude. Currently, the datasets consider over 100 polls, published between 2011 and 2022.

        An detailed [report (PDF)](https://github.com/Irish-Dem-Polling/irish-demographic-polling-datasets.pdf) summarises the variables and structure of the data. The document also discusses advantages and limitations of subgroup analyses by addressing three questions relating to party politics.

        In sub-folders of this repository, we provide three datasets:

        - The folder [`vote-intention`](https://github.com/Irish-Dem-Polling/vote-intention) contains data on first-preference vote intentions from Behaviour & Attitudes and RedC polls for all respondents and various demographic and geographic subsamples.
        - The folder [`government-satisfaction`](https://github.com/Irish-Dem-Polling/government-satisfaction) contains data on satisfaction with the government from Behaviour & Attitudes polls for all respondents and various demographic and geographic subsamples.
        - The folder [`party-leaders`](https://github.com/Irish-Dem-Polling/party-leaders) contains data on the approval of party leaders from Behaviour & Attitudes polls for all respondents and various demographic and geographic subsamples.

        If available, we provide the data as weighted proportions and counts.

        ### File Formats

        We provide all datasets in three file formats. 

        - `csv`: The [comma-separated values](https://en.wikipedia.org/wiki/Comma-separated_values) file ensures inter-operability as it can be opened in R, Python, Stata, SPSS, and Excel.
        - `dta`: This file can be used to import the datasets  with correct variable encodings into [Stata](https://stata.com).
        - `rds`: The RDS file is optimised for the [R](https://r-project.org) statistical programming language and stores the variables in the correct data type.

        ### Citation

        If you use these datasets for news reports or academic research, please 
        citing:

        Stefan Müller, Thomas Pluck, and Paula Montano (2023). _Irish Demographic Polling Datasets_. URL: https://github.com/Irish-Dem-Polling/datasets

        ### Acknowledgements

        We want to thank RedC Research and Behaviour & Attitudes for continuously publishing survey reports for the public. If you use individual surveys, please cite and reference the pollsters' reports rather than this dataset. Reports provided by Behaviour & Attitudes are available [here](https://banda.ie/site-reports/). The reports released by RedC can be accessed [here](https://www.redcresearch.ie/latest-polls/live-polling-tracker/).

        """
    )
)


def server(input, output, session):
    @reactive.Effect
    def _():

        set = input.dataset()
        type = input.datatype()



        ui.update_checkbox_group(
            "series",
            "Select Series:",
            Series,
            inline = True
        )

app = App(app_ui, server, debug=True)