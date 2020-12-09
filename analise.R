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
deaths2015 <- subset(tmp, is.element(city, distancing$city))
rm(tmp)

# dados a partir de 2019 para fazer o POLS
deaths <- subset(deaths2015, as.Date(date) > as.Date('2019-01-01'))
nonfatal <- subset(nonfatal_updated, is.element(city, distancing$city))

# merge do infosiga com o plano SP
deaths2015_sp <- merge(x = deaths2015, y = planosp_updated, by = c('date', 'city'), all.x = TRUE)
deaths_sp <- merge(x = deaths, y = planosp_updated, by = c('date', 'city'), all.x = TRUE)
nonfatal_sp <- merge(x = nonfatal, y = planosp_updated, by = c('date', 'city'), all.x = TRUE)

# agregando os dados por cidade e data
agg_death2015 <- deaths2015_sp %>% group_by(date, city) %>% summarise(
    accidents=n(),
    distancing_index,
    moto = sum(motorcycle),
    phase
)
agg_death2015 <- unique(agg_death2015)
agg_death <- deaths_sp %>% group_by(date, city) %>% summarise(
    accidents=n(),
    distancing_index,
    moto = sum(motorcycle),
    phase,
    fatal=1
)
agg_death <- unique(agg_death)
agg_nonfatal <- nonfatal_sp %>% group_by(date, city) %>% summarise(
    accidents=n(),
    distancing_index,
    moto = sum(motorcycle),
    phase,
    fatal=0
)
agg_nonfatal <- unique(agg_nonfatal)
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
nmsdist <- lm(log(accidents) ~ city + dist_dummy:distancing_index, data=nomiss)
nmsplsp <- lm(log(accidents) ~ city + quarantine + phase, data=nomiss)
bptest(nmsdist)
bptest(nmsplsp)
robmsdist <- rlm(log(accidents) ~ city + dist_dummy:distancing_index, data=nomiss)
robmsplsp <- rlm(log(accidents) ~ city + quarantine + phase, data=nomiss)

# regressões de moto sem missing
motodist <- lm(log(moto+1) ~ city + dist_dummy:distancing_index, data=nomiss)
motoplsp <- lm(log(moto+1) ~ city + quarantine + phase, data=nomiss)
bptest(motodist)
bptest(motoplsp)
motomsdist <- rlm(log(moto+1) ~ city + dist_dummy:distancing_index, data=nomiss)
motomsplsp <- rlm(log(moto+1) ~ city + quarantine + phase, data=nomiss)

# regressões de morte sem missing
# trata morte
deathnm <- agg_death2015
deathnm$dist_dummy <- ifelse(is.na(deathnm$distancing_index), 0, 1)
deathnm$distancing_index <- ifelse(is.na(deathnm$distancing_index), 0, deathnm$distancing_index)
deathnm$phase <- ifelse(is.na(deathnm$phase), "AAANORMAL", deathnm$phase)
deathnm$quarantine <- ifelse(as.Date(deathnm$date) >= as.Date('2020-03-24'), 1, 0)

# regs propriamente ditas
mortedist <- lm(log(accidents) ~ city + dist_dummy:distancing_index, data=deathnm)
morteplsp <- lm(log(accidents) ~ city + quarantine + phase, data=deathnm)
bptest(mortedist)
bptest(morteplsp)
cov1 <- vcovHC(mortedist, type="HC1")
cov2 <- vcovHC(morteplsp, type="HC1")
rse1 <- sqrt(diag(cov1))
rse2 <- sqrt(diag(cov2))
wald1 <- waldtest(mortedist, vcov=cov1)
wald2 <- waldtest(morteplsp, vcov=cov2)

# stargazer(mortedist, morteplsp, se = list(rse1, rse2), omit.stat = "f", add.lines = list(c("F Statistic", "32.592***(df = 104; 17143)", "31.87***(df = 107; 17141)")))
