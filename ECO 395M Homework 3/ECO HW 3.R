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

# this function actually prunes the tree at that level
prune_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  prune(my_tree, cp=cp_opt)
}
# a handy function for picking the smallest tree 
# whose CV error is within 1 std err of the minimum
cp_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  cp_opt
}

# load data
dengue = read.csv('../data/dengue.csv')
N = nrow(dengue)
dengue$total_cases <- as.numeric(as.character(dengue$total_cases))
dengue$city <- as.factor(dengue$city)
dengue$season <- as.factor(dengue$season)

# split into training and testing
train_frac = 0.8
N_train = floor(train_frac*N)
N_test = N - N_train
train_ind = sample.int(N, N_train, replace=FALSE) %>% sort
dengue_train = dengue[train_ind,]
dengue_test = dengue[-train_ind,]

##
# build a classification tree with variables indicated in questions
dengue_tree= rpart(total_cases ~ ., 
                   data = dengue_train)

# plot the tree
rpart.plot(dengue_tree, type=4, extra=1)

# the various summaries of the tree
print(dengue_tree) # the structure
summary(dengue_tree)  # more detail on the splits
# cross-validated error plot.
plotcp(dengue_tree)
# you could squint at the table...
printcp(dengue_tree)
# picking the smallest tree whose CV error is within 1 std err of the minimum
cp_1se(dengue_tree)

# in-sample fit, i.e. predict on the original training data
# this returns predicted class probabilities
predict(dengue_tree, newdata=dengue_train)

##
# Regression trees
##

# grow a smallish tree
# larger cp and insplit means stop at a smaller tree
dengue.tree = rpart(total_cases~ ., 
                    data=dengue_train,
                    control = rpart.control(cp = 0.0002, minsplit = 10))
# this says: split only if you have at least 10 obs in a node,
# and the split improves the fit by a factor of 0.0002

# plot the tree
# see ?rpart.plot for the various plotting options here (type, extra)
rpart.plot(dengue.tree, digits=-5, type=4, extra=1)

# cross-validated error plot.
plotcp(dengue.tree)
# you could squint at the table...
printcp(dengue.tree)
# picking the smallest tree whose CV error is within 1 std err of the minimum
cp_1se(dengue.tree)

# let's prune our tree at the 1se complexity level
dengue.tree_prune = prune_1se(dengue.tree)
#plot the tree 
rpart.plot(dengue.tree_prune, type=4, digits=-5, extra=1, cex=0.5)

##
# random forests
##

dengue_forest = randomForest(total_cases ~ .,
                       data = dengue_train, 
                       na.action = na.roughfix, importance=TRUE)
# shows out-of-bag MSE as a function of the number of trees used
plot(dengue_forest)

# let's compare RMSE on the test set
modelr::rmse(dengue_tree, dengue_test)
modelr::rmse(dengue.tree, dengue_test)
modelr::rmse(dengue_forest, dengue_test) # randomforest has less RMSE

yhat_dengue2 = predict(dengue_forest, dengue_test)
rmse_dengue2 = mean((yhat_dengue2 - dengue_test$total_cases)^2) %>% sqrt

##
# boosting
##

# boost model with default distribution
dengue_boost = gbm(total_cases ~ .,
                   data = dengue_train, 
                   interaction.depth=4, n.trees=500, shrinkage=.05)

# Look at error curve
gbm.perf(dengue_boost)

yhat_test_gbm = predict(dengue_boost, dengue_test, n.trees=500)

# RMSE
modelr::rmse(dengue_boost, dengue_test)


# What if we assume a Poisson error model?
dengue_boost2 = gbm(total_cases ~ ., 
             data = dengue_train, distribution='poisson',
             interaction.depth=4, n.trees=500, shrinkage=.05)

# error curve
gbm.perf(dengue_boost2)

# Note: the predictions for a Poisson model are on the log scale by default
# use type='response' to get predictions on the original scale
# all this is in the documentation, ?gbm
yhat_test_gbm2 = predict(dengue_boost2, dengue_test, n.trees=500, type='response')

# but this subtly messes up the rmse function, which uses predict with default args
# so we need to roll our own calculate for RMSE
(yhat_test_gbm2 - dengue_test$total_cases)^2 %>% mean %>% sqrt


# What if we assume a gaussian error model?
dengue_boost3 = gbm(total_cases ~ ., 
                    data = dengue_train, distribution='gaussian', # guassian for std error
                    interaction.depth=4, n.trees=500, shrinkage=.05)

# error curve
gbm.perf(dengue_boost3)

# predict yhat
yhat_test_gbm = predict(dengue_boost3, dengue_test, n.trees=500)

# RMSE
modelr::rmse(dengue_boost3, dengue_test)
