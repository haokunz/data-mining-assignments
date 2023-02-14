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

#leave the rest to Luna



## Classification and retrospective sampling

credit = read.csv("../data/german_credit.csv")

#build a bar plot of history
barplot(table(credit$history),
        main='count of credit history',
        xlab='credit history',
        ylab='count')

#build a logit reg model
logit_credit1 = glm(Default ~ +duration + amount + installment + age + history + purpose + foreign, data = credit, family = 'binomial')

#summary(logit_credit1)
coef(logit_credit1) %>% round(2)

#check out-of-sample performance
phat_test_logit_credit1 = predict(logit_credit1, credit, type='response')
yhat_test_logit_credit1 = ifelse(phat_test_logit_credit1 > 0.5, 1, 0)
confusion_out_logit1 = table(y = credit$Default,
                            yhat=yhat_test_logit_credit1)
confusion_out_logit1

#split to test and training
credit_split = initial_split(credit, 0.8)
credit_test = testing(credit_split)
credit_training = training(credit_split)

#run a predictive logit regression
logit_credit2 = glm(Default ~ + duration + amount + installment + age + history + purpose + foreign, data = credit_training, family = 'binomial')

summary(logit_credit2)
coef(logit_credit2) %>% round(2)

#check out-of-sample performance
phat_test_logit_credit2 = predict(logit_credit2, credit_test, type='response')
yhat_test_logit_credit2 = ifelse(phat_test_logit_credit2 > 0.5, 1, 0)
confusion_out_logit2 = table(y = credit_test$Default,
                            yhat=yhat_test_logit_credit2)
confusion_out_logit2

# The coef for having poor and terrible credit history is -1.11 and -1.88. 
# Having a poor or terrible credit history multiplies odds of default by 0.33 and 0.15
# If the purpose of the model is to screen prospective borrowers to classify them into "high" versus "low" probability of default
# This data set is not appropriate for building a predictive model, because of class imbalance
# The ratio of number of non-default and default is more than 2:1, by blindly prediciting more than half of data points as non-default, this model will not predict default well
table(credit$Default)
# A suggestion I can make is balance the number of defaults so that the 1's and 0's are in approximately equal proportions



## Children and hotel reservations
# Johnason will do this question




