# ECO 395M: Exercises 2

## Saratoga house prices

### write a better lm model

library(tidyverse)
library(ggplot2)
library(modelr)
library(rsample)
library(mosaic)
data(SaratogaHouses)

SaratogaHouses$loglivingArea <- log(SaratogaHouses$livingArea)
#SaratogaHouses$logprice <- log(SaratogaHouses$price)


glimpse(SaratogaHouses)

####
# Compare out-of-sample predictive performance
####

# Split into training and testing sets
saratoga_split = initial_split(SaratogaHouses, prop = 0.8)
saratoga_train = training(saratoga_split)
saratoga_test = testing(saratoga_split)

# Fit to the training data
# Sometimes it's easier to name the variables we want to leave out
# The command below yields exactly the same model.
# the dot (.) means "all variables not named"
# the minus (-) means "exclude this variable"

lm2 = lm(price ~ . - pctCollege - sewer - waterfront - landValue - newConstruction, data=saratoga_train)
lm3 = lm(price ~ (. - pctCollege - sewer - waterfront - landValue - newConstruction)^2, data=saratoga_train)

#hand build a new model
lm4 = lm(price ~ . - pctCollege - sewer - fuel -fireplaces -livingArea -landValue +poly(landValue, 2) +livingArea:centralAir +bathrooms:heating, data=saratoga_train)

#summarize and test the model's aic and bic
summary(lm4)
broom::glance(lm4)

coef(lm2) %>% round(0)
coef(lm3) %>% round(0)
coef(lm4) %>% round(0)

# Predictions out of sample
# Root mean squared error

rmse(lm2, saratoga_test)
rmse(lm3, saratoga_test)
rmse(lm4, saratoga_test)

## build a knn model

# k-value cross validation
k_folds = 5

saratoga_folds = crossv_kfold(SaratogaHouses, k=k_folds)

k_grid = c(2, 4, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45,
           50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300)


