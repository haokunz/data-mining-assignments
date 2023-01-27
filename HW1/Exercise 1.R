###
#Exercise 1
###

#import packages
library(ggplot2)
library(tidyverse)
library(dplyr)
library(rsample)  # for creating train/test splits
library(caret)
library(modelr)
library(parallel)
library(foreach)

#Load in data 1
ABIA = read.csv("../data/ABIA.csv")

#head(ABIA)

#average delay time based on airtime
AVG_Delay <- aggregate(DepDelay ~ AirTime, ABIA, mean)

#try to create the first graph
ggplot(AVG_Delay, aes(x=AirTime, y=DepDelay))+
  geom_line()


#Load in data 2
olympics_top20=read.csv("../data/olympics_top20.csv")

#head(olympics_top20)
 
#2_A

#Filter by female
olympics_female<-olympics_top20 %>%
  filter(sex =="F", sport=='Athletics')

#95th percent of female height across all event
quantile(olympics_female$height, probs=0.95)

#2_B

#Filter by female
olympics_female<-olympics_top20 %>%
  filter(sex =="F")

#produce a sorted dataframe containing event and std dev
result<-split(olympics_female, olympics_female$event)%>%
  lapply(., function(x)sd(x$height))%>%
  unlist(.)%>%as.data.frame(.)
res<-cbind(row.names(result),result)
colnames(res)<-c("event","height_std_dev")

#sort by std_dev
res_order<-res[order(res$height_std_dev, decreasing = TRUE),]

head(res_order)

#2_C
olympics_swimmer <- olympics_top20 %>%
  filter(sport == 'Swimming')

#average age of swimmers over time
AVG_Age_Swimmer <- aggregate(age ~ year, olympics_swimmer, mean)

#average age of swimmers in different genders over time
AVG_Age_Gender <- aggregate(age ~ year + sex, olympics_swimmer, mean)

# linear graph
ggplot()+
  geom_line(data = AVG_Age_Swimmer, aes(x=year, y=age))+
  geom_smooth(span = 1)+
  geom_line(data=AVG_Age_Gender, aes(x=year, y=age, color = sex))

# 3
sclass = read.csv('../data/sclass.csv')

trim_350 <- sclass %>%
  filter(trim =='350') #filter 350
trim_65_AMG <- sclass %>%
  filter(trim == '65 AMG') #filter AMG

# split testing and training dataset
trim_350_split =  initial_split(trim_350, prop=0.8)
trim350_train = training(trim_350_split)
trim350_test  = testing(trim_350_split)
trim_AMG_split = initial_split(trim_65_AMG, prop=0.8)
trimAMG_train = training(trim_AMG_split)
trimAMG_test = testing(trim_AMG_split)

# k-value cross validation
k_folds = 5

trim350_folds = crossv_kfold(trim_350, k=K_folds)
trimAMG_folds = crossv_kfold(trim_65_AMG,k=k_folds)

# define a series of k
k_grid = c(2, 4, 6, 8, 10, 15, 20, 25, 30, 35, 40, 45,
           50, 60, 70, 80, 90, 100, 125, 150, 175, 200, 250, 300)

cv_grid350 = foreach(k = k_grid, .combine='rbind') %dopar% {
  # map the model-fitting function over the training sets
  models = map(trim350_folds$train, ~ knnreg(price ~ mileage, k=k, data = ., use.all=FALSE))
  # map the RMSE calculation over the trained models and test sets simultaneously
  errs = map2_dbl(models, trim350_folds$test, modelr::rmse)
  c(k=k, err = mean(errs), std_err = sd(errs)/sqrt(K_folds)) # approximate standard error of CV error
} %>% as.data.frame

# plot means and std errors versus k
ggplot(cv_grid350) + 
  geom_point(aes(x=k, y=err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err)) + 
  scale_x_log10()

# knn to 350
knn15 = knnreg(price ~ mileage, data=trim350_train, k=30)
modelr::rmse(knn15, trim350_test)

# attach the predictions to the test data frame
trim350_test = trim350_test %>%
  mutate(Price_pred = predict(knn15, trim350_test))

p_test = ggplot(data = trim350_test) + 
  geom_point(mapping = aes(x = mileage, y = price), alpha=0.2)

# add the predictions
p_test + geom_line(aes(x = mileage, y = Price_pred), color='red', size=1.5)

###
#trimAMG
###

cv_gridAMG = foreach(k = k_grid, .combine='rbind') %dopar% {
  # map the model-fitting function over the training sets
  models = map(trimAMG_folds$train, ~ knnreg(price ~ mileage, k=k, data = ., use.all=FALSE))
  # map the RMSE calculation over the trained models and test sets simultaneously
  errs = map2_dbl(models, trimAMG_folds$test, modelr::rmse)
  c(k=k, err = mean(errs), std_err = sd(errs)/sqrt(K_folds)) # approximate standard error of CV error
} %>% as.data.frame

head(cv_gridAMG)

# plot means and std errors versus k
ggplot(cv_gridAMG) + 
  geom_point(aes(x=k, y=err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err)) + 
  scale_x_log10()

# knn to AMG
knn20 = knnreg(price ~ mileage, data=trim350_train, k=30)
modelr::rmse(knn20, trimAMG_test)

# attach the predictions to the test data frame
trimAMG_test = trimAMG_test %>%
  mutate(Price_pred = predict(knn20, trimAMG_test))

p_test = ggplot(data = trimAMG_test) + 
  geom_point(mapping = aes(x = mileage, y = price), alpha=0.2)

# add the predictions
p_test + geom_line(aes(x = mileage, y = Price_pred), color='red', size=1.5)

