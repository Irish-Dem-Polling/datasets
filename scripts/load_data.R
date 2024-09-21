####
# Script for importing and wrangling demographic polling data
####


## load required packages
library(rmarkdown)
library(tidyverse)
library(googlesheets4)

# url to spreadsheets
url_spreadsheets <- "https://docs.google.com/spreadsheets/d/1WEQ3ZOZ7pANUjyxGb75Psh7tqe7B1cQREEA1GsftROc/edit?usp=sharing"

# 0) Stop googlesheets4 looking for credentials
gs4_deauth()

# 1) import spreadsheets from Google Sheets ----

## First-preferences: Red C
dat_redc_first_pref <- read_sheet(url_spreadsheets,
    sheet = "redc_first_pref"
)



## First preferences: Behaviour and Attitudes
dat_banda_first_pref <- read_sheet(url_spreadsheets,
    sheet = "banda_first_pref",
    col_types = "cciiiiiiiiiiiiiiiiiiiiiii"
)


## Government satisfaction: Behaviour and Attitudes
dat_banda_govsat <- read_sheet(url_spreadsheets,
    sheet = "banda_govsat",
    col_types = "cciiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"
)


## Leader satisfaction: Behaviour and Attitudes
dat_banda_leaders <- read_sheet(url_spreadsheets,
    sheet = "banda_leaders",
    col_types = "ccciiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii"
)


## First-preferences (with all parties)
dat_banda_indepen <- read_sheet(url_spreadsheets,
    sheet = "banda_indepen",
    col_types = "cciiiiiiiiiiiiiiiiii"
)



## Load IPI data to merge and adjust survey dates

dat_ipi <- read.csv("https://raw.githubusercontent.com/Irish-Polling-Indicator/ipi-data/main/data_polls.csv")


## select only relevant variables
dat_ipi_subset <- select(
    dat_ipi, pollster,
    date, date_start,
    date_end, date_middle,
    sample_size
)


# 2a) Wrangle RedC ----

# recode dates
dat_redc_first_pref <- dat_redc_first_pref %>%
    mutate(Date = as.character(Date)) %>%
    mutate(Date = dplyr::recode(Date,
        "1625788800" = "9/7/2021",
        "1565308800" = "9/8/2019",
        "1575504000" = "5/12/2019",
        "1646784000" = "9/3/2022",
        "1720483200" = "09/07/2024"
    ))


dat_redc_first_pref <- dat_redc_first_pref %>%
    mutate(party = dplyr::recode(Party,
        "S.P.B.P." = "Solidarity/PBP",
        "A." = "Aontú",
        "F.F." = "Fianna Fáil",
        "F.G." = "Fine Gael",
        "G.P." = "Green Party",
        "I.D.4.C" = "Independents for Change",
        "Lab." = "Labour",
        "R." = "Renua",
        "Non-P." = "Independents",
        "S.D." = "Social Democrats",
        "S.F." = "Sinn Féin",
        "S.P.B.P" = "Solidarity/PBP"
    ))



names(dat_redc_first_pref)

# remove percentage signs in entire dataframe
dat_redc_first_pref[] <- lapply(dat_redc_first_pref, gsub, pattern = "\\%", replacement = "")


dat_redc_first_pref <- dat_redc_first_pref %>%
    mutate(Date = dplyr::recode(Date,
        "1694217600" = "9/9/2023"
    ))

dat_redc_clean <- dat_redc_first_pref %>%
    mutate(date = as.Date(Date, "%m/%d/%Y")) %>%
    mutate(
        total = as.numeric(Total),
        male = as.numeric(Male),
        female = as.numeric(Female),
        age_18_34 = as.numeric(`18-34`),
        age_35_54 = as.numeric(`35-54`),
        age_55 = as.numeric(`55+`),
        class_abc1 = as.numeric(ABC1),
        class_c2de = as.numeric(C2DE),
        region_dublin = as.numeric(Dublin),
        region_leinster_rest = as.numeric(`Rest of Leinster`),
        region_munster = as.numeric(Munster),
        region_connacht_ulster = as.numeric(`Conn/Ulster`)
    ) %>%
    #  select(date, party, total:region_connacht_ulster) %>%
    arrange(date, party)


dat_ipi_redc <- filter(dat_ipi_subset, pollster == "Red C")

dat_ipi_redc$date_middle <- as.Date(dat_ipi_redc$date_middle)



dat_redc_clean <- rename(dat_redc_clean, date_middle = date)


dat_redc_clean_joined <- left_join(dat_redc_clean, dat_ipi_redc)


dat_redc_clean_joined <- dat_redc_clean_joined %>%
    mutate(
        date = as.Date(date),
        date_start = as.Date(date_start),
        date_middle = as.Date(date_middle),
        date_end = as.Date(date_end)
    )


# dataset with proportions
dat_redc_props <- dat_redc_clean_joined %>%
    select(starts_with("date"), sample_size, party, total:region_connacht_ulster) %>%
    select(
        date, date_start, date_end, date_middle,
        sample_size, everything()
    ) %>%
    select(-Date) %>%
    arrange(date) |>
    unique() # get only unique values in case parties are included twice per poll


## Note: raw counts not available


# 2b) Wrangle B&A: First pref with independent ----


## recode parties

dat_banda_indepen <- dat_banda_indepen %>%
    mutate(party = dplyr::recode(Party,
        "Sinn Fein" = "Sinn Féin",
        "Fianna Fail" = "Fianna Fáil",
        "Aontu" = "Aontú",
        "Labour Party" = "Labour",
        "Solidarity/People Before Profit" = "Solidarity/PBP",
        "Labour Party" = "Labour",
        "Other Independent candidate" = "Independents",
        "Other Independent candidate" = "Independents",
        "RENUA Ireland" = "RENUA",
        "PBP" = "Solidarity/PBP"
    ))


## recode three dates
dat_banda_indepen <- dat_banda_indepen %>%
    mutate(Date = as.character(as.Date(Date, "%m/%d/%Y"))) %>%
    mutate(Date = dplyr::recode(Date,
        "2017-01-10" =
            "2017-01-09",
        "2016-01-09" = "2016-01-08"
    )) %>%
    mutate(Date = as.Date(Date))





dat_banda_indepen_clean <- dat_banda_indepen %>%
    filter(!is.na(Total)) %>%
    rename(date = Date) %>%
    group_by(date) %>%
    mutate(
        total = Total / sum(Total),
        male = Male / sum(Male),
        female = Female / sum(Female),
        age_18_34 = `-34` / sum(`-34`),
        age_35_54 = `34-54` / sum(`34-54`),
        age_55 = `55+` / sum(`55+`),
        class_abc1 = ABC1 / sum(ABC1),
        class_c2de = C2DE / sum(C2DE),
        class_f = `F` / sum(`F`),
        region_dublin = Dublin / sum(Dublin),
        region_leinster = Leinster / sum(Leinster),
        region_munster = Munster / sum(Munster),
        region_connacht_ulster = `Conn/Ulster` / sum(`Conn/Ulster`),
        area_urban = Urban / sum(Urban),
        area_rural = Rural / sum(Rural),
        const_seats_3 = `3 Seats` / sum(`3 Seats`),
        const_seats_4 = `4 Seats` / sum(`4 Seats`),
        const_seats_5 = `5 Seats` / sum(`5 Seats`)
    ) # %>%
# select(date, party, total:const_seats_5)



dat_ipi_banda <- filter(
    dat_ipi_subset,
    pollster == "Behaviour & Attitudes"
)

dat_ipi_banda$date_middle <- as.Date(dat_ipi_banda$date_middle)

dat_banda_indepen_clean <- rename(dat_banda_indepen_clean, date_middle = date)

dat_banda_indepen_clean$date_middle <- as.Date(dat_banda_indepen_clean$date_middle)

dat_banda_indepen_clean_joined <- left_join(dat_banda_indepen_clean, dat_ipi_banda)


dat_banda_indepen_clean_joined <- dat_banda_indepen_clean_joined %>%
    mutate(
        date = as.Date(date),
        date_start = as.Date(date_start),
        date_middle = as.Date(date_middle),
        date_end = as.Date(date_end)
    )


## proportions

dat_props_banda_indepen_joined <- dat_banda_indepen_clean_joined %>%
    select(
        date, date_start, date_end, date_middle,
        sample_size, party, total:const_seats_5
    )

# round numberic to 2 digits

dat_props_banda_indepen_joined <- dat_props_banda_indepen_joined %>%
    mutate(across(where(is.numeric), round, 2)) %>%
    arrange(date, party)



# repeat for counts

dat_counts_banda_indepen_joined <- dat_banda_indepen_clean_joined %>%
    select(-c(total:const_seats_5)) %>%
    rename(
        total = Total,
        male = Male,
        female = Female,
        age_18_34 = `-34`,
        age_35_54 = `34-54`,
        age_55 = `55+`,
        class_abc1 = ABC1,
        class_c2de = C2DE,
        class_f = `F`,
        region_dublin = Dublin,
        region_leinster = Leinster,
        region_munster = Munster,
        region_connacht_ulster = `Conn/Ulster`,
        area_urban = Urban,
        area_rural = Rural,
        const_seats_3 = `3 Seats`,
        const_seats_4 = `4 Seats`,
        const_seats_5 = `5 Seats`
    ) %>%
    select(
        date, date_start, date_end, date_middle,
        sample_size, party, total:const_seats_5
    ) %>%
    arrange(date)



# 2c) Government Satisfaction: Behaviour and Attitudes ----

dat_banda_govsat <- dat_banda_govsat %>%
    mutate(Date = as.Date(Date, "%d/%m/%Y")) %>%
    mutate(Date = as.character(Date)) %>%
    mutate(Date = dplyr::recode(
        Date,
        "2011-08-24" = "2011-08-20",
        "2012-02-18" = "2012-02-17",
        "2015-06-14" = "2015-06-10",
        #  "2015-06-06" = "2015-06-10",
        "2016-01-09" = "2016-01-08",
        "2016-02-02" = "2016-02-01",
        "2016-02-16" = "2016-02-15",
        "2017-01-10" = "2017-01-09",
        "2017-04-06" = "2017-04-05",
        "2017-06-01" = "2017-05-31",
        "2018-10-11" = "2018-10-10",
        "2018-12-15" = "2018-12-12",
        "2019-01-19" = "2019-01-09",
        "2019-06-06" = "2019-06-05",
        "2020-03-05" = "2020-03-04",
        "2021-07-06" = "2021-07-07",
        "2021-09-02" = "2021-08-31"
    )) %>%
    mutate(date = as.Date(Date))


names(dat_banda_govsat)


dat_banda_govsat_clean <- dat_banda_govsat %>%
    select(-Date) %>%
    group_by(date) %>%
    mutate(
        total = Total / sum(Total),
        male = Male / sum(Male),
        female = Female / sum(Female),
        age_18_34 = `-34` / sum(`-34`),
        age_35_54 = `35-55` / sum(`35-55`),
        age_55 = `55+` / sum(`55+`),
        class_abc1 = ABC1 / sum(ABC1),
        class_c2de = C2DE / sum(C2DE),
        class_f = `F` / sum(`F`),
        region_dublin = Dublin / sum(Dublin),
        region_leinster = Leinster / sum(Leinster),
        region_munster = Munster / sum(Munster),
        region_connacht_ulster = `Conn/Ulster` / sum(`Conn/Ulster`),
        area_urban = Urban / sum(Urban),
        area_rural = Rural / sum(Rural),
        const_seats_3 = `3 seats` / sum(`3 seats`),
        const_seats_4 = `4 seats` / sum(`4 seats`),
        const_seats_5 = `5 seats` / sum(`5 seats`),
        voting_vote = `Would Vote` / sum(`Would Vote`),
        voting_prob_vote = `Would Prob Vote` / sum(`Would Prob Vote`),
        voting_undecided = `Might/might not` / sum(`Might/might not`),
        voting_not_vote = `Would not Vote` / sum(`Would not Vote`),
        future_fianna_fail = `Future Fianna Fail` / sum(`Future Fianna Fail`),
        future_fine_gael = `Future Fine Gael` / sum(`Future Fine Gael`),
        future_labour = `Future Labour Party` / sum(`Future Labour Party`),
        future_greens = `Future Green Party` / sum(`Future Green Party`),
        future_sinn_fein = `Future Sinn Fein` / sum(`Future Sinn Fein`),
        future_ind_oth = `Future Independent/Other` / sum(`Future Independent/Other`),
        future_dont_know = `Future Don't Know/Would not` / sum(`Future Don't Know/Would not`),
        past_fianna_fail = `Past Fianna Fail` / sum(`Past Fianna Fail`),
        past_fine_gael = `Past Fine Gael` / sum(`Past Fine Gael`),
        past_labour = `Past Labour Party` / sum(`Past Labour Party`),
        past_greens = `Past Green Party` / sum(`Past Green Party`),
        past_sinn_fein = `Past Sinn Fein` / sum(`Past Sinn Fein`),
        past_ind_oth = `Past Independent/Other` / sum(`Past Independent/Other`),
        past_dont_know = `Past Don't Know/Would not` / sum(`Past Don't Know/Would not`)
    ) %>%
    rename(
        satisfaction_government = Opinion,
        date_middle = date
    )


dat_banda_govsat_clean$date_middle <- as.Date(dat_banda_govsat_clean$date_middle)

dat_banda_govsat_clean_joined <- left_join(dat_banda_govsat_clean, dat_ipi_banda)


dat_banda_govsat_clean_joined <- dat_banda_govsat_clean_joined %>%
    mutate(
        date = as.Date(date),
        date_start = as.Date(date_start),
        date_middle = as.Date(date_middle),
        date_end = as.Date(date_end)
    )

## clean dataset with proportions

# dat_prop_banda_govsat <- dat_banda_govsat_clean %>%
#     select(date, satisfaction_government, total:past_dont_know)

dat_prop_banda_govsat <- dat_banda_govsat_clean_joined %>%
    select(
        date, date_start, date_end, date_middle,
        sample_size, satisfaction_government, total:past_dont_know
    )

# round numberic to 4 digits

dat_prop_banda_govsat <- dat_prop_banda_govsat %>%
    mutate(across(where(is.numeric), round, 2)) %>%
    arrange(date)

ggplot(
    dat_prop_banda_govsat,
    aes(x = date_middle, y = future_sinn_fein)
) +
    geom_point() +
    facet_wrap(~satisfaction_government)


## repeat for counts

dat_counts_banda_govsat <- dat_banda_govsat_clean_joined %>%
    select(-c(total:past_dont_know)) %>%
    mutate(
        total = Total,
        male = Male,
        female = Female,
        age_18_34 = `-34`,
        age_35_54 = `35-55`,
        age_55 = `55+`,
        class_abc1 = ABC1,
        class_c2de = C2DE,
        class_f = `F`,
        region_dublin = Dublin,
        region_leinster = Leinster,
        region_munster = Munster,
        region_connacht_ulster = `Conn/Ulster`,
        area_urban = Urban,
        area_rural = Rural,
        const_seats_3 = `3 seats`,
        const_seats_4 = `4 seats`,
        const_seats_5 = `5 seats`,
        voting_vote = `Would Vote`,
        voting_prob_vote = `Would Prob Vote`,
        voting_undecided = `Might/might not`,
        voting_not_vote = `Would not Vote`,
        future_fianna_fail = `Future Fianna Fail`,
        future_fine_gael = `Future Fine Gael`,
        future_labour = `Future Labour Party`,
        future_greens = `Future Green Party`,
        future_sinn_fein = `Future Sinn Fein`,
        future_ind_oth = `Future Independent/Other`,
        future_dont_know = `Future Don't Know/Would not`,
        past_fianna_fail = `Past Fianna Fail`,
        past_fine_gael = `Past Fine Gael`,
        past_labour = `Past Labour Party`,
        past_greens = `Past Green Party`,
        past_sinn_fein = `Past Sinn Fein`,
        past_ind_oth = `Past Independent/Other`,
        past_dont_know = `Past Don't Know/Would not`
    ) %>%
    select(
        date, date_start, date_end, date_middle,
        sample_size, satisfaction_government, total:past_dont_know
    ) %>%
    arrange(date)






## 2d) Party leaders ----


# recode party names
dat_banda_leaders <- dat_banda_leaders %>%
    mutate(Subject = str_remove_all(Subject, " Leader")) %>%
    mutate(Subject = dplyr::recode(Subject,
        "FF" = "Fianna Fáil",
        "FG" = "Fine Gael",
        "SF" = "Sinn Féin",
        "GP" = "Green Party",
        "LP" = "Labour"
    )) %>%
    mutate(Date = as.Date(Date, "%d/%m/%Y")) %>%
    mutate(Date = as.character(Date)) %>%
    mutate(Date = dplyr::recode(
        Date,
        "2011-08-24" = "2011-08-20",
        "2012-02-18" = "2012-02-17",
        #  "2015-06-06" = "2015-06-10",
        "2015-06-14" = "2015-06-10",
        "2016-01-09" = "2016-01-08",
        "2016-02-02" = "2016-02-01",
        "2016-02-16" = "2016-02-15",
        "2017-01-10" = "2017-01-09",
        "2017-04-06" = "2017-04-05",
        "2017-06-01" = "2017-05-31",
        "2018-10-11" = "2018-10-10",
        "2018-12-15" = "2018-12-12",
        "2019-01-19" = "2019-01-09",
        "2019-06-06" = "2019-06-05",
        "2020-03-05" = "2020-03-04",
        "2021-07-06" = "2021-07-07",
        "2021-09-02" = "2021-08-31"
    )) %>%
    mutate(Date = as.Date(Date))


table(dat_banda_leaders$Subject)

names(dat_banda_govsat)

names(dat_banda_leaders)

dat_banda_leaders_clean <- dat_banda_leaders %>%
    rename(date = Date) %>%
    group_by(date, Subject) %>%
    mutate(
        total = Total / sum(Total),
        male = Male / sum(Male),
        female = Female / sum(Female),
        age_18_34 = `-34` / sum(`-34`),
        age_35_54 = `35-55` / sum(`35-55`),
        age_55 = `55+` / sum(`55+`),
        class_abc1 = ABC1 / sum(ABC1),
        class_c2de = C2DE / sum(C2DE),
        class_f = `F` / sum(`F`),
        region_dublin = Dublin / sum(Dublin),
        region_leinster = Leinster / sum(Leinster),
        region_munster = Munster / sum(Munster),
        region_connacht_ulster = `Conn/Ulster` / sum(`Conn/Ulster`),
        area_urban = Urban / sum(Urban),
        area_rural = Rural / sum(Rural),
        const_seats_3 = `3 seats` / sum(`3 seats`),
        const_seats_4 = `4 seats` / sum(`4 seats`),
        const_seats_5 = `5 seats` / sum(`5 seats`),
        voting_vote = `Would Vote` / sum(`Would Vote`),
        voting_prob_vote = `Would Prob Vote` / sum(`Would Prob Vote`),
        voting_undecided = `Might/might not` / sum(`Might/might not`),
        voting_not_vote = `Would not Vote` / sum(`Would not Vote`),
        future_fianna_fail = `Future Fianna Fail` / sum(`Future Fianna Fail`),
        future_fine_gael = `Future Fine Gael` / sum(`Future Fine Gael`),
        future_labour = `Future Labour Party` / sum(`Future Labour Party`),
        future_greens = `Future Green Party` / sum(`Future Green Party`),
        future_sinn_fein = `Future Sinn Fein` / sum(`Future Sinn Fein`),
        future_ind_oth = `Future Independent/Other` / sum(`Future Independent/Other`),
        future_dont_know = `Future Don't Know/Would not` / sum(`Future Don't Know/Would not`),
        past_fianna_fail = `Past Fianna Fail` / sum(`Past Fianna Fail`),
        past_fine_gael = `Past Fine Gael` / sum(`Past Fine Gael`),
        past_labour = `Past Labour Party` / sum(`Past Labour Party`),
        past_greens = `Past Green Party` / sum(`Past Green Party`),
        past_sinn_fein = `Past Sinn Fein` / sum(`Past Sinn Fein`),
        past_ind_oth = `Past Independent/Other` / sum(`Past Independent/Other`),
        past_dont_know = `Past Don't Know/Would not` / sum(`Past Don't Know/Would not`)
    ) %>%
    rename(date_middle = date)


dat_banda_leaders_clean$date_middle <- as.Date(dat_banda_leaders_clean$date_middle)

dat_banda_leaders_clean_joined <- left_join(dat_banda_leaders_clean, dat_ipi_banda)


dat_banda_leaders_clean_joined <- dat_banda_leaders_clean_joined %>%
    mutate(
        date = as.Date(date),
        date_start = as.Date(date_start),
        date_middle = as.Date(date_middle),
        date_end = as.Date(date_end)
    )


# add names of party leaders

# https://en.wikipedia.org/wiki/Leader_of_Fine_Gael

# https://en.wikipedia.org/wiki/Leader_of_Fianna_Fáil

# https://en.wikipedia.org/wiki/Leader_of_the_Labour_Party_(Ireland)
# round numberic to 4 digits

dat_banda_leaders_clean_joined <- dat_banda_leaders_clean_joined %>%
    rename(
        satisfaction_leader = Opinion,
        leader_party = Subject
    ) %>%
    mutate(leader_name = case_when(
        date <= as.Date("2017-06-01") & leader_party == "Fine Gael" ~ "Enda Kenny",
        date > as.Date("2017-06-01") & leader_party == "Fine Gael" ~ "Leo Varadkar",
        date >= as.Date("2011-01-26") & leader_party == "Fianna Fáil" ~ "Micheál Martin",
        between(date, as.Date("2007-09-06"), as.Date("2014-07-03")) & leader_party == "Labour" ~ "Joan Burton",
        between(date, as.Date("2014-07-04"), as.Date("2016-05-19")) & leader_party == "Labour" ~ "Joan Burton",
        between(date, as.Date("2016-05-20"), as.Date("2020-04-02")) & leader_party == "Labour" ~ "Brendan Howlin",
        between(date, as.Date("2020-04-03"), as.Date("2022-03-23")) & leader_party == "Labour" ~ "Alan Kelly",
        date >= as.Date("2022-03-24") & leader_party == "Labour" ~ "Ivana Bacik",
        date < as.Date("2018-02-10") & leader_party == "Sinn Féin" ~ "Gerry Adams",
        date >= as.Date("2018-02-10") & leader_party == "Sinn Féin" ~ "Mary Lou McDonald",
        leader_party == "Green Party" ~ "Eamon Ryan"
    ))


dat_props_banda_leaders <- dat_banda_leaders_clean_joined %>%
    select(
        date, date_start, date_end, date_middle,
        sample_size, leader_party, leader_name,
        satisfaction_leader,
        total:past_dont_know
    )


dat_props_banda_leaders <- dat_props_banda_leaders %>%
    mutate(across(where(is.numeric), round, 2)) %>%
    arrange(date)



## repeat for counts

dat_counts_banda_leaders <- dat_banda_leaders_clean_joined %>%
    select(-c(total:past_dont_know)) %>%
    mutate(
        total = Total,
        male = Male,
        female = Female,
        age_18_34 = `-34`,
        age_35_54 = `35-55`,
        age_55 = `55+`,
        class_abc1 = ABC1,
        class_c2de = C2DE,
        class_f = `F`,
        region_dublin = Dublin,
        region_leinster = Leinster,
        region_munster = Munster,
        region_connacht_ulster = `Conn/Ulster`,
        area_urban = Urban,
        area_rural = Rural,
        const_seats_3 = `3 seats`,
        const_seats_4 = `4 seats`,
        const_seats_5 = `5 seats`,
        voting_vote = `Would Vote`,
        voting_prob_vote = `Would Prob Vote`,
        voting_undecided = `Might/might not`,
        voting_not_vote = `Would not Vote`,
        future_fianna_fail = `Future Fianna Fail`,
        future_fine_gael = `Future Fine Gael`,
        future_labour = `Future Labour Party`,
        future_greens = `Future Green Party`,
        future_sinn_fein = `Future Sinn Fein`,
        future_ind_oth = `Future Independent/Other`,
        future_dont_know = `Future Don't Know/Would not`,
        past_fianna_fail = `Past Fianna Fail`,
        past_fine_gael = `Past Fine Gael`,
        past_labour = `Past Labour Party`,
        past_greens = `Past Green Party`,
        past_sinn_fein = `Past Sinn Fein`,
        past_ind_oth = `Past Independent/Other`,
        past_dont_know = `Past Don't Know/Would not`
    ) %>%
    select(
        date, date_start, date_end, date_middle,
        sample_size, leader_party, leader_name,
        satisfaction_leader,
        total:past_dont_know
    ) %>%
    arrange(date)



# 3) Save files in various formats ----


write_csv(dat_redc_props, "vote-intention/data_redc_firstpref_prop.csv")
haven::write_dta(dat_redc_props, "vote-intention/data_redc_firstpref_prop.dta")
saveRDS(dat_redc_props, "vote-intention/data_redc_firstpref_prop.rds")

write_csv(dat_props_banda_indepen_joined, "vote-intention/data_banda_firstpref_prop.csv")
write_csv(dat_counts_banda_indepen_joined, "vote-intention/data_banda_firstpref_counts.csv")
haven::write_dta(dat_props_banda_indepen_joined, "vote-intention/data_banda_firstpref_prop.dta")
haven::write_dta(dat_counts_banda_indepen_joined, "vote-intention/data_banda_firstpref_counts.dta")
saveRDS(dat_props_banda_indepen_joined, "vote-intention/data_banda_firstpref_prop.rds")
saveRDS(dat_counts_banda_indepen_joined, "vote-intention/data_banda_firstpref_counts.rds")

write_csv(dat_props_banda_leaders, "party-leaders/data_banda_leaders_prop.csv")
write_csv(dat_counts_banda_leaders, "party-leaders/data_banda_leaders_counts.csv")
haven::write_dta(dat_props_banda_leaders, "party-leaders/data_banda_leaders_prop.dta")
haven::write_dta(dat_counts_banda_leaders, "party-leaders/data_banda_leaders_counts.dta")
saveRDS(dat_props_banda_leaders, "party-leaders/data_banda_leaders_prop.rds")
saveRDS(dat_counts_banda_leaders, "party-leaders/data_banda_leaders_counts.rds")


write_csv(dat_prop_banda_govsat, "government-satisfaction/data_banda_govsat_prop.csv")
write_csv(dat_counts_banda_govsat, "government-satisfaction/data_banda_govsat_counts.csv")
haven::write_dta(dat_prop_banda_govsat, "government-satisfaction/data_banda_govsat_prop.dta")
haven::write_dta(dat_counts_banda_govsat, "government-satisfaction/data_banda_govsat_counts.dta")
saveRDS(dat_prop_banda_govsat, "government-satisfaction/data_banda_govsat_prop.rds")
saveRDS(dat_counts_banda_govsat, "government-satisfaction/data_banda_govsat_counts.rds")
