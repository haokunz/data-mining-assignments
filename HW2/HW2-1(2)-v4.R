# ECO 395M: Exercises 2
#Author:Luna

## Saratoga house prices

### write a better lm model

library(tidyverse)
library(ggplot2)
library(modelr)
library(rsample)
library(mosaic)
library(caret)
library(parallel)
library(foreach)
library(lubridate)
library(dplyr)
library(knitr)
data(SaratogaHouses)
glimpse(SaratogaHouses)

## build better model

saratoga_split = initial_split(SaratogaHouses, prop = 0.8)
saratoga_train = training(saratoga_split)
saratoga_test = testing(saratoga_split)

#try 3 different linear models,then compare
lm1 = lm(log(price) ~ lotSize + lotSize:age + age + 
           landValue + bathrooms + sewer, data=saratoga_train)
lm2 = lm(log(price) ~ lotSize + age + log(landValue) + log(livingArea) + 
           bedrooms + bathrooms +  bedrooms:bathrooms + 
           rooms, data=saratoga_train)
lm3 = lm(log(price) ~  lotSize + age + log(landValue) 
         + log(livingArea) + log(landValue):log(livingArea) 
         + bedrooms + bathrooms + rooms
         + fireplaces:waterfront, data=saratoga_train)
rmse(lm1, saratoga_test)
rmse(lm2, saratoga_test)
rmse(lm3, saratoga_test)  
#since lm3 has the least rmse, lm3 is the best model among these above 3 lm models,which is better than lm2 and lm1

#build the best K-nearest-neighbor regression model for price,using same variables from lm3
k_folds = 5
SaratogaHouses_folds = crossv_kfold(SaratogaHouses, k=k_folds)

k_grid = c(2, 4, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45,
           50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300)
cv_SaratogaHouses = foreach(k = k_grid, .combine='rbind') %dopar% {
  models = map(SaratogaHouses_folds$train, ~ knnreg(log(price) ~ lotSize+age+log(landValue) + log(livingArea) + bedrooms + bathrooms + rooms, k=k, data = ., use.all=FALSE))
  errs = map2_dbl(models, SaratogaHouses_folds$test, modelr::rmse)
  c(k=k, err = mean(errs), std_err = sd(errs)/sqrt(k_folds))
} %>% as.data.frame
head(cv_SaratogaHouses)

ggplot(cv_SaratogaHouses) + 
  geom_point(aes(x= k, y= err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err))+
  geom_line(aes(x= k, y= err))

#we can get the best k according to the following:

k_min_error = cv_SaratogaHouses %>%
  slice_min(err) %>%
  pull(k)
k_min_error

#then we calculate the best knn model's error
knnmodels =map(SaratogaHouses_folds$train, ~ knnreg(log(price) ~ lotSize+age+log(landValue) + log(livingArea) + bedrooms + bathrooms + rooms, k=k_min_error, data = ., use.all=FALSE))
knnerrs = map2_dbl(knnmodels, SaratogaHouses_folds$test, modelr::rmse)
knnerrs
mean(knnerrs)


#then we calculate the best lm model's error 
lmmodels = map(SaratogaHouses_folds$train, ~ lm(log(price) ~  lotSize + age + log(landValue) 
                                              + log(livingArea) + log(landValue):log(livingArea) 
                                              + bedrooms + bathrooms + rooms
                                              + fireplaces:waterfront, data = .))
lmerrs = map2_dbl(lmmodels, SaratogaHouses_folds$test, modelr::rmse)
lmerrs
mean(lmerrs)

# The error from the optimal knn model is 0.3441, larger than that of linear model 3, which is 0.2945. 
# Thus linear model seems to do better at achieving lower out-of-sample mean-squared error.
# Therefore as for price-modeling strategies for a local taxing authority, we should pay more attention to the linear model’s prediction to estimate market values for properties.



