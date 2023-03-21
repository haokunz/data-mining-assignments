# Exercise 3 2023
# Question 2 : Tree modeling: dengue cases

# Our goal for this problem: 
# 1. Use CART, random forests, 
# and gradient-boosted trees to predict dengue cases
# based on the features available in the data set

# 2. for whichever model has the better performance on the testing data, 
# make three partial dependence plots: specific_humidity, precipitation_amt
# and wild card/writer's choice: you choose a feature that looks 
# interesting and make a partial dependence plot for that.


## Train of thought
## 1. Build CART model, Random forest model and Gradient-boosted trees
## 2. Uses the 3 models to predict the dengue cases( depend on testing set)
## 3. Make the partial dependence plots 

## Problem 1: How to build CART model?
## Problem 2: How to build Random Forest model?
## Problem 3: How to build Gradient-boosted trees?
## Problem 4: How to make the partial dependence plots?



# Loaded the needed packages
library(tidyverse)
library(ggplot2)
library(rsample)
library(modelr)
library(randomForest)
library(caret)
library(gbm)
library(ggmap)
library(glmnet)
library(rpart) # a powerful ML library that is used for building classification and regression trees
library(gamlr)
library(rpart.plot)
library(data.table)
library(DMwR2)

# PART 1: Data wrangling

# Read the dataset
dengue_fever <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/dengue.csv")
head(dengue_fever)

# Use KNN to impute the n.a. value
dengue_fever$total_cases <- as.numeric(as.character(dengue_fever$total_cases))
dengue_fever$city <- as.factor(dengue_fever$city)
dengue_fever$season <- as.factor(dengue_fever$season)
imputeDengue <- knnImputation(dengue_fever, k = 10, scale = T, meth = "median", distData = NULL)
head(imputeDengue)

# Split the dataset into training set and testing set
imputeDengue = initial_split(imputeDengue, prop = 0.8) # 80% of the data as training data
dengue_training = training(imputeDengue)
dengue_testing = testing(imputeDengue)

# PART 2: Model building 

# CART model building
cart_dengue = rpart(total_cases ~ . , data = dengue_training, 
                  control = rpart.control(cp = 0.002, minsplit=20))
### Split only if we have at least 20 obs in a node,
### and the split improves the fit by a factor of 0.002 aka 0.2%

# Random Forest model building
## in the "random_forest_example.R"
rforest_dengue = randomForest(total_cases ~ .,
                             data = dengue_training, 
                             importance=TRUE)

# Gradient-boosted model building
## in the "capmetro.R"
gbm_dengue = gbm(total_cases ~ .,
                   data = dengue_training, 
                   interaction.depth=4, n.trees=500, shrinkage=.05)

# PART 3: Use the models to Predict the infection cases, and find the model has the best performance
# Predict the dengue cases with CART model, Random Forest model and Gradient-boosted model
yhat_cart = predict(cart_dengue, dengue_testing)
plot(yhat_cart, dengue_testing$total_cases)
rmse(cart_dengue, dengue_testing)

yhat_rf = predict(rforest_dengue, dengue_testing)
plot(yhat_rf, dengue_testing$total_cases)
rmse(rforest_dengue, dengue_testing)

yhat_gbm = predict(gbm_dengue, dengue_testing, n.trees=350)
plot(yhat_gbm, dengue_testing$total_cases)
rmse(gbm_dengue, dengue_testing)


# let's compare RMSE on the test set
modelr::rmse(cart_dengue, dengue_testing)
modelr::rmse(rforest_dengue, dengue_testing) 
modelr::rmse(gbm_dengue, dengue_testing) 

# Because the gradient-boosted model has the smallest out-of-sample RMSE,
# we decided to choose it as the model to make partial dependence plots

# PART 4: Partial dependence plots
# Make the partial dependence plots
## gbm partial plots are in the "capmetro.R"
##### partialPlot(gbm_dengue, dengue_testing, 'specific_humidity', las=1)

plot(gbm_dengue, 'specific_humidity', main = "Partial Dependence on specific humidity")
plot(gbm_dengue, 'precipitation_amt', main = "Partial Dependence on precipitation_amt")
plot(gbm_dengue, 'tdtr_k', main = "Partial Dependence on tdtr_k")
# We choose "tdtr_k" to make a partial dependence plots because we think that 
# if the DTR is bigger, it's more difficult for mosquito to live
# as a result, we want to know whether DTR affect the total dengue fever cases
# and we can see that it has big influence on the infection cases.

## Problem: y是total_cases嗎？

####p1 = pdp::partial(gbm_dengue, pred.var = 'specific_humidity', n.trees=350)
####p1
####ggplot(p1) + geom_point(mapping=aes(x=specific_humidity, y=total_cases)) 


## Problem: cross-validation??




