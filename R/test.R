### TEST 
getwd()
Paq1000 <- read.csv("data/Paq1000.txt", sep="")

head(Paq1000)
source("R/idm.R")
library(survival)

library(marqLevAlg)
library(splines2)
#library(SmoothHazardoptim9) #package Ariane
library(prodlim)
library(dplyr)
library(survival)
#library(SmoothHazard) #package Pierre
library(ggplot2)
library(doBy) 
#pour enregistrer les objets
#load("fitspline.Rdata")
#save(fitsplinecens,file="fitsplinecens.Rdata")
#save(fitspline,file="fitspline.Rdata")
source("R/idm.weib.R")
dyn.load("src/idmlikelihood.f90")



fit <- idm(
  formula02 = Hist(time = t, event = death) ~ certif,
  
  formula01 = Hist(time = r, event = dementia) ~ certif, 
  
  formula12 = ~ certif, data = Paq1000, nproc=3,clustertype = "PSOCK")

summary(fit)