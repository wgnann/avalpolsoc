library(dplyr)
library(lmtest)
library(MASS)
library(readr)

# CSVs
deaths_updated <- read_delim("Desktop/avalpolsoc/csv/deaths_updated.csv", 
    ";", escape_double = FALSE, trim_ws = TRUE)
nonfatal_updated <- read_delim("Desktop/avalpolsoc/csv/nonfatal_updated.csv", 
    ";", escape_double = FALSE, trim_ws = TRUE)
planosp_updated <- read_csv("Desktop/avalpolsoc/csv/planosp_updated.csv")
distancing <- read_csv("Desktop/avalpolsoc/csv/distancing.csv")

# corrigindo data para dados a partir de 2015 e cidades com distanciamento
tmp <- subset(deaths_updated, as.Date(date) > as.Date('2015-01-01'))
deaths <- subset(tmp, is.element(city, distancing$city))
nonfatal <- subset(nonfatal_updated, is.element(city, distancing$city))
rm(tmp)

# merge do infosiga com o plano SP
deaths_sp <- merge(x = deaths, y = planosp_updated, by = c('date', 'city'), all.x = TRUE)
nonfatal_sp <- merge(x = nonfatal, y = planosp_updated, by = c('date', 'city'), all.x = TRUE)

# agregando os dados por cidade e data
agg_death <- deaths_sp %>% group_by(date, city) %>% summarise(
    accidents=n(),
    distancing_index,
    phase,
    fatal=1
)
agg_nonfatal <- nonfatal_sp %>% group_by(date, city) %>% summarise(
    accidents=n(),
    distancing_index,
    phase,
    fatal=0
)
agg <- rbind(agg_death, agg_nonfatal)

# tratando os missings
# distance_index virará 0 quando conveniente e teremos uma dummy
nomiss <- agg
nomiss$dist_dummy <- ifelse(is.na(nomiss$distancing_index), 0, 1)
nomiss$distancing_index <- ifelse(is.na(nomiss$distancing_index), 0, nomiss$distancing_index)
nomiss$phase <- ifelse(is.na(nomiss$phase), "AAANORMAL", nomiss$phase)
nomiss$quarantine <- ifelse(as.Date(nomiss$date) >= as.Date('2020-03-24'), 1, 0)

# regressões com missing
regdist <- lm(log(accidents) ~ city + distancing_index, data=agg)
regplsp <- lm(log(accidents) ~ city + phase, data=agg)
bptest(regdist)
bptest(regplsp)
robdist <- rlm(log(accidents) ~ city + distancing_index, data=agg)
robplsp <- rlm(log(accidents) ~ city + phase, data=agg)

# regressões sem missing
nmsdist <- lm(log(accidents) ~ city + dist_dummy + distancing_index, data=nomiss)
nmsplsp <- lm(log(accidents) ~ city + quarantine + phase, data=nomiss)
bptest(nmsdist)
bptest(nmsplsp)
robmsdist <- rlm(log(accidents) ~ city + dist_dummy + distancing_index, data=nomiss)
robmsplsp <- rlm(log(accidents) ~ city + quarantine + phase, data=nomiss)
