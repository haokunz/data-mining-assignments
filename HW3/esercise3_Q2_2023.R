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

# Read the dataset
dengue_fever <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/dengue.csv")
head(dengue_fever)

# Split the datset into training set and testing set
dengue_fever = initial_split(dengue_fever, prop = 0.8) # 80% of the data as training data
dengue_training = training(dengue_fever)
dengue_testing = testing(dengue_fever)


# CART model building
load.tree = rpart(COAST~temp + dewpoint, data=load,
                  control = rpart.control(cp = 0.002, minsplit=20))
### Split only if we have at least 20 obs in a node,
### and the split improves the fit by a factor of 0.002 aka 0.2%


# Random Forest model building


# Gradient-boosted model building

# Predict the dengue cases

# Make the partial dependence plots







