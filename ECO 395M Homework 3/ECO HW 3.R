# Eco HW 3

## What causes what? 

# 1. The number of cops in the city doesn't direct cause the reduction of crime rate on streets. There are many other
# factors and events that have correlation to crime rates, such as terror alert level and certain events and festivals 
# that increase the number of cops deplied. Focus only on the relationship between numbers of cops on the street and crime rate will 
# lead to a biased conclusion on causation of numbers of cops to the crime.

# 2. The researchers used daily police reports of crime from the Metropolitan Police Department
# of the District of Columbia that cover the time period of 506 days since the HSAS terror alert system began
# During high alert level, the D.C. police forces increased their presence on the streets.
# The researchers used the high-alert periods to estimate the effect of police on crime and break the circle of endogenous relationship between police presence and crime rate.
# In Table 2, the daily total number of crimes in D.C. decreased by an average of seven crimes per day on high-alert days. 

# 3. The researchers included metro ridership as a variable to test their hypothesize that tourism is reduced on high-alert days, therefore there are less crimes on street.
# They added logged midday Metro ridership to the regression and captured the percentage of change on number of crimes based on the change of Metro reidership

# 4. Table 4 presents reduction in crime on high-alert days using police patrol concentration on hte national mall. 
# The first column presents robusted coefficient of estimation of crime in the National Mall area and the other districts during periods of high alert 
# 2.62 crimes decreased in the National Mall area, implying 15 percent of decline during high-alert days. Crime also decreases in the other districts, though the effect is not statistically significant.
# Lastly, ten percentage of increase on midday ridership increases 0.24 percent of crime rate.

#-------------------------------------------------------------------------------------------------------------------------------------------------------------

## Tree modeling: dengue cases
library(randomForest)
library(tidyverse)
library(rpart)
library(rpart.plot)
library(rsample) 
library(gbm)
library(tree)
library(mosaic)
library(pdp)
library(ggplot2)
library(parallel)
library(foreach)
library(gamlr)
library(modelr)

## Exercise 3 2023
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


# evaluate the performance of three models by k-folds
# Perform cross-validation
set.seed(123)
k <- 5
cart_cv <- rpart.control(cp = 0.01)
rf_cv <- list(mtry = sqrt(ncol(dengue_training)), replace = TRUE)
gb_cv <- list(n.trees = 1000, interaction.depth = 4, shrinkage = 0.01, cv.folds = k)

cart_cv_results <- rpart(total_cases ~ ., data = dengue_training, control = cart_cv)
rf_cv_results <- randomForest(total_cases ~ ., data = dengue_training, mtry = rf_cv$mtry, replace = rf_cv$replace)
gb_cv_results <- gbm(total_cases ~ ., data = dengue_training, n.trees = gb_cv$n.trees, interaction.depth = gb_cv$interaction.depth, shrinkage = gb_cv$shrinkage, cv.folds = gb_cv$cv.folds, verbose = FALSE)

# Evaluate the performance of each model
cart_performance <- predict(cart_cv_results, newdata = dengue_testing)
rf_performance <- predict(rf_cv_results, newdata = dengue_testing)
gb_performance <- predict(gb_cv_results, newdata = dengue_testing, n.trees = gb_cv$n.trees)

# Compare the performance of each model by measuring MSE
cart_accuracy <- mean((cart_performance - dengue_testing$total_cases)^2)
rf_accuracy <- mean((rf_performance - dengue_testing$total_cases)^2)
gb_accuracy <- mean((gb_performance - dengue_testing$total_cases)^2)

# print out the MSE of each model to console, the lower the better the model is 
cat("CART accuracy:", cart_accuracy, "\n")
cat("Random Forest accuracy:", rf_accuracy, "\n")
cat("Gradient Boosting accuracy:", gb_accuracy, "\n") # gradient boosting has the lowest MSE

# Because the gradient-boosted model has the smallest out-of-sample RMSE and MSE,
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


## Question 3: Predictive model building: green certification
# goal is to build the best predictive model possible for _revenue per square foot per calendar year_, 
# and to use this model to quantify the average change in rental income per square foot (whether in absolute or percentage terms) 
# associated with green certification, holding other features of the building constant.

# load in data
greenbuildings = read.csv('https://raw.githubusercontent.com/jgscott/ECO395M/master/data/greenbuildings.csv')
# create revenue variable
greenbuildings$revenue_per_square_foot_per_calendar_year <- greenbuildings$Rent * greenbuildings$leasing_rate
# collapse LEED and Energystart to green-certification variable and convert the variable type
greenbuildings$green_certification <- paste(greenbuildings$LEED, 
                                            greenbuildings$Energystar, sep = "_")
greenbuildings$green_certification <- as.factor(greenbuildings$green_certification) # change type of green_certification from chr to factor
imputegreen <- knnImputation(greenbuildings, k = 10, scale = T, meth = "median", distData = NULL) # fill any missing value using KNN method

# split data to training and testing
splitgreen = initial_split(imputegreen, prop = 0.8) # 80% of the data as training data
green_training = training(splitgreen)
green_testing = testing(splitgreen)


## Try to build predictive models
# 1. build a predictive model using three tree models
# CART model
cart_green = rpart(revenue_per_square_foot_per_calendar_year ~ . -LEED -Energystar, 
                    data = green_training, 
                    control = rpart.control(cp = 0.002, minsplit=20))
### Split only if we have at least 20 obs in a node,
### and the split improves the fit by a factor of 0.002 aka 0.2%

# RandomForest model
rforest_green = randomForest(revenue_per_square_foot_per_calendar_year ~ . -LEED -Energystar,
                             data = green_training,
                             importance=TRUE)

# Gradient-boosted model building
## in the "capmetro.R"
gbm_green = gbm(revenue_per_square_foot_per_calendar_year ~ . -LEED -Energystar,
                 data = green_training, 
                 interaction.depth=4, n.trees=500, shrinkage=.05)

# Test these models
yhat_cart = predict(cart_green, green_testing)
plot(yhat_cart, green_testing$revenue_per_square_foot_per_calendar_year)
rmse(cart_green, green_testing)

yhat_rf = predict(rforest_green, green_testing)
plot(yhat_rf, green_testing$revenue_per_square_foot_per_calendar_year)
rmse(rforest_green, green_testing)

yhat_gbm = predict(gbm_green, green_testing, n.trees=350)
plot(yhat_gbm, green_testing$revenue_per_square_foot_per_calendar_year)
rmse(gbm_green, green_testing)

# 2. Write a Lasso Regression

# create own feature matrix
green_lasso_x_main = sparse.model.matrix(revenue_per_square_foot_per_calendar_year ~  (.-1 -LEED -Energystar), data=green_training)
green_lasso_x_itac = sparse.model.matrix(revenue_per_square_foot_per_calendar_year ~  (.-1 -LEED -Energystar)^2, data=green_training)
green_lasso_y = green_training$revenue_per_square_foot_per_calendar_year
## "$" extract a specific part of a data object

# fit a single lasso
# greenlasso_main = glm(green_lasso_y~., data = green_training, family="gaussian")
# plot(greenlasso_main) # the path plot

greenlasso_main = gamlr(green_lasso_x_main, green_lasso_y, family="gaussian")
plot(greenlasso_main)

greenlasso_itac = gamlr(green_lasso_x_itac, green_lasso_y, family="gaussian")
plot(greenlasso_itac)

