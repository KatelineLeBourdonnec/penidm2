### TEST 
getwd()
Paq1000 <- read.csv("data/Paq1000.txt", sep="")

head(Paq1000)
library(survival)
library(marqLevAlg)
library(splines2)
library(prodlim)
library(dplyr)
library(survival)
library(ggplot2)
library(doBy) 



fit <- idm(
  formula02 = Hist(time = t, event = death) ~ certif,
  
  formula01 = Hist(time = r, event = dementia) ~ certif, 
  
  formula12 = ~ certif, data = Paq1000, nproc=3,clustertype = "PSOCK", timedep12=F)

summary(fit)

idm()