# ECO 395M: Exercises 2

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


#Luna's part


# plot the data,to find features going into KNN model
ggplot(data = SaratogaHouses) + 
  geom_point(mapping = aes(x = log(livingArea), y = price), color='darkgrey') + 
  ylim(50000, 300000)
ggplot(data = SaratogaHouses) + 
  geom_point(mapping = aes(x = log(landValue), y = price), color='darkgrey') + 
  ylim(50000, 300000)
ggplot(data = SaratogaHouses) + 
  geom_point(mapping = aes(x = bedrooms, y = price), color='darkgrey') + 
  ylim(50000, 300000)
ggplot(data = SaratogaHouses) + 
  geom_point(mapping = aes(x = rooms, y = price), color='darkgrey') + 
  ylim(50000, 300000)
# Make a train-test split
saratoga_split = initial_split(SaratogaHouses, prop = 0.8)
saratoga_train = training(saratoga_split)
saratoga_test = testing(saratoga_split)


#####
# Fit KNN models
#####

# KNN with K = 100
knn100 = knnreg(price ~ log(livingArea)+log(landValue)+bedrooms+rooms, data=saratoga_train, k=100)
modelr::rmse(knn100, saratoga_test)

####
# plot the fit
####

# attach the predictions to the test data frame
saratoga_test = saratoga_test %>%
  mutate(price_pred = predict(knn100, saratoga_test))

p_test = ggplot(data = saratoga_test) + 
  geom_point(mapping = aes(x = log(livingArea)+log(landValue)+bedrooms+rooms, y = price), alpha=0.2) + 
  ylim(50000, 300000)
p_test

# now add the predictions
p_test + geom_line(aes(x = log(livingArea)+log(landValue)+bedrooms+rooms, y = price_pred), color='red', size=1.5)



###
# K-fold cross validation
###

K_folds = 5
saratoga_folds = crossv_kfold(SaratogaHouses, k=K_folds)

# map the model-fitting function over the training sets
models = map(saratoga_folds$train, ~ knnreg(price ~ log(livingArea)+log(landValue)+bedrooms+rooms, k=100, data = ., use.all=FALSE))
# "map" transforms an input by applying a function to
# each element of a list or atomic vector and returning
# an object of the same length as the input.

# map the RMSE calculation over the trained models and test sets simultaneously
errs = map2_dbl(models, saratoga_folds$test, modelr::rmse)

# note:
#  - map2 means map over two inputs simultaneously
#  - _dbl means return the result as a vector of real numbers ("doubles")

mean(errs)
sd(errs)/sqrt(K_folds)   # approximate standard error of CV error


# so now we can do this across a range of k
k_grid = c(2, 4, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45,
           50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300)

# Notice we use the same folds for each value of k
# this is important, otherwise we're not comparing
# models across the same train/test splits
cv_grid = foreach(k = k_grid, .combine='rbind') %dopar% {
  models = map(saratoga_folds$train, ~ knnreg(price ~ log(livingArea)+log(landValue)+bedrooms+rooms, k=k, data = ., use.all=FALSE))
  errs = map2_dbl(models, saratoga_folds$test, modelr::rmse)
  c(k=k, err = mean(errs), std_err = sd(errs)/sqrt(K_folds))
} %>% as.data.frame

head(cv_grid)

# plot means and std errors versus k
ggplot(cv_grid) + 
  geom_point(aes(x=k, y=err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err)) + 
  scale_x_log10()










## Classification and retrospective sampling








## Children and hotel reservations
# Johnason will do this question




