# Irish Demographic Polling Datasets

[**Detailed Report and Codebook (PDF)**](irish-demographic-polling-datasets.pdf)

## Introduction

The Irish Demographic Polling Datasets collect aggregated results on vote intentions, satisfaction with the government, and popularity of party leaders. The data are available for all respondents and various subsamples, such as age groups, gender, social class, geographic region, and district magnitude. Currently, the datasets consider over 100 polls, published between 2011 and 2022.

An detailed [report (PDF)](irish-demographic-polling-datasets.pdf) summarises the variables and structure of the data. The document also discusses advantages and limitations of subgroup analyses by addressing three questions relating to party politics.

In sub-folders of this repository, we provide three datasets:

- The folder [`vote-intention`](vote-intention) contains data on first-preference vote intentions from Behaviour & Attitudes and RedC polls for all respondents and various demographic and geographic subsamples.
- The folder [`government-satisfaction`](government-satisfaction) contains data on satisfaction with the government from Behaviour & Attitudes polls for all respondents and various demographic and geographic subsamples.
- The folder [`party-leaders`](party-leaders) contains data on the approval of party leaders from Behaviour & Attitudes polls for all respondents and various demographic and geographic subsamples.

If available, we provide the data as weighted proportions and counts.

## File Formats

We provide all datasets in three file formats. 

- `csv`: The [comma-separated values](https://en.wikipedia.org/wiki/Comma-separated_values) file ensures inter-operability as it can be opened in R, Pyhton, Stata, SPSS, and Excel.
- `dta`: This file can be used to import the datasets  with correct variable encodings into [Stata](https://stata.com).
- `rds`: The RDS file is optimised for the [R](https://r-project.org) statistical programming language and stores the variables in the correct data type.

## Citation

If you use these datasets for news reports or academic research, please consider citing:

Thomas Pluck and Stefan Müller (2022). _Irish Demographic Polling Datasets_. URL: https://github.com/Irish-Dem-Polling/datasets

## Acknowledgements

We want to thank RedC Research and Behaviour & Attitudes for continuously publishing survey reports for the public. If you use individual surveys, please cite and reference the pollsters' reports rather than this dataset. Reports provided by Behaviour & Attitudes are available [here](https://banda.ie/site-reports/). The reports released by RedC can be accessed [here](https://www.redcresearch.ie/latest-polls/live-polling-tracker/).
