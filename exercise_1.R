# import packages
library(tidyverse)
library(lubridate)
library(RCurl)
library(dplyr)
library(ggplot2)
library(rsample)  # for creating train/test splits
library(caret)
library(modelr)
library(parallel)
library(foreach)
library(knitr)

# Question 1: Data visualization: flights at ABIA
# load data ABIA
ABIA <- read.csv('https://raw.githubusercontent.com/jgscott/ECO395M/master/data/ABIA.csv')

#calculate the average departure delay time over 2008 and make a plot to show that

AverageDayDelay <- ABIA %>% 
  select(Year, Month, DayofMonth, ArrDelay, DepDelay, ) %>%
  mutate(departureday = make_datetime(Year, Month, DayofMonth)) 

delay <-  AverageDayDelay %>%
  group_by(departureday) %>%
  summarise(mean_dep_delay = mean(DepDelay, na.rm = TRUE))

average_departure_delay_time_over_2008 <- ggplot(data = delay, aes(x = departureday, y = mean_dep_delay)) +
  geom_line()+
  labs(title = "average departure delay time over 2008 ")+
  labs(x = 'date', y = '(minutes)')

plot(average_departure_delay_time_over_2008)

# we can see the result that in most time, the delay time fluctulate between 0 and 20, and around Oct, the delay time is relatively small.

AverageSpecificTimeDelay <- ABIA %>%
  select(Year, Month, DayofMonth, CRSDepTime, ArrDelay, DepDelay) %>%
  mutate(departureday = make_datetime(Year, Month, DayofMonth, CRSDepTime %/% 100, CRSDepTime %% 100)) %>%
  mutate(CRSdeparttime = format(departureday, format = "%H"))


delayoneday = AverageSpecificTimeDelay %>%
  group_by(CRSdeparttime) %>%
  summarise(mean_dep_oneday = mean(DepDelay, na.rm = TRUE))



delay_day <- ggplot(delayoneday) +
  geom_line(aes(x = CRSdeparttime, y = mean_dep_oneday, group =1)) +
  labs(title = "average departure delay time over one day(measured by hours) ")+
  labs(x = 'time', y = '(minutes)')

plot(delay_day)

# we can find from 6am, the average delay time is increased in general, and due to schedule arrangement, there is no flight delarture between 00 and 06
# so we give a suggestion: try to catch earlier flight rather than later flight

answer1 <- ABIA %>% 
  select(Year, Month, DayofMonth, CRSDepTime, DepDelay, UniqueCarrier) %>%
  mutate(departureday = make_datetime(Year, Month, DayofMonth, CRSDepTime %/% 100, CRSDepTime %% 100)) %>%
  mutate(CRSdeparttime = format(departureday, format = "%H"))

delay_airline = answer1 %>%
  group_by(CRSdeparttime, UniqueCarrier) %>%
  summarise(count = n(),
            mean_dep_delay = mean(DepDelay, na.rm = TRUE))

delay_affected_airline <-  delay_airline %>%
  filter(count > 50)%>%
  ggplot(aes(x = CRSdeparttime, y = mean_dep_delay)) +
  geom_line(group = 1)+
  facet_wrap(~UniqueCarrier)

plot(delay_affected_airline)
# from that plot we can see that overall, US airline has the minimum delay time, but we lack their data in some months, maybe they doesn't arrange flightline during these months




# Question 3: K-nearest neighbors: cars
## Load data
sclass <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/sclass.csv")

## Filter 65 AMG & 350
def_350 = sclass%>%
  filter(trim == "350")

## spilt to test& training set
def_65 = sclass%>%
  filter(trim == "65 AMG")

def_350_spilt = initial_split(def_350 ,prop=0.8)
def_350_train = training(def_350_spilt)
def_350_test = testing(def_350_spilt)

def_65_spilt = initial_split(def_65 ,prop=0.8)
def_65_train = training(def_65_spilt)
def_65_test = testing(def_65_spilt)

## run k nearest neighbors  RMSEs

k_folds = 5
k_grid = rep(1:100)

knn100 = knnreg(price ~ mileage, data=def_350_train, k=100)
rmse(knn100, def_350_test)

knn100 = knnreg(price ~ mileage, data=def_65_train, k=100)
rmse(knn100, def_65_test)

### Pipeline 1:
### create specific fold IDs for each row
### the default behavior of sample actually gives a permutation
def_350 = def_350 %>%
  mutate(fold_id = rep(1:k_folds, length=nrow(def_350)) %>% sample)

head(def_350)

def_65 = def_65 %>%
  mutate(fold_id = rep(1:k_folds, length=nrow(def_65)) %>% sample)

head(def_65)

def_350_folds = crossv_kfold(def_350, k=k_folds)
def_65_folds = crossv_kfold(def_65, k=k_folds)

cv_grid_350 = foreach(k = k_grid, .combine='rbind') %dopar% {
  models = map(def_350_folds$train, ~ knnreg(price ~ mileage, k=k, data = ., use.all=FALSE))
  errs = map2_dbl(models, def_350_folds$test, modelr::rmse)
  c(k=k, err = mean(errs), std_err = sd(errs)/sqrt(k_folds))
} %>% as.data.frame

cv_grid_65 = foreach(k = k_grid, .combine='rbind') %dopar% {
  models = map(def_65_folds$train, ~ knnreg(price ~ mileage, k=k, data = ., use.all=FALSE))
  errs = map2_dbl(models, def_65_folds$test, modelr::rmse)
  c(k=k, err = mean(errs), std_err = sd(errs)/sqrt(k_folds))
} %>% as.data.frame

head(cv_grid_350)
head(cv_grid_65)

## the relationship for RMSE and k，can find optimal k（line or point）
ggplot(cv_grid_350) + 
  geom_point(aes(x= k, y= err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err))

ggplot(cv_grid_65) + 
  geom_point(aes(x= k, y= err)) + 
  geom_errorbar(aes(x=k, ymin = err-std_err, ymax = err+std_err))

# The optimal k for 350 is 15, and the optimal k for 65 AMG is 22

## model for each k (for each trim) ##6 Which trim have bigger optimal k? why?
k_min_rmse_350 = cv_grid_350 %>%
  slice_min(err) %>%
  pull(k)

k_min_rmse_65 = cv_grid_65 %>%
  slice_min(err) %>%
  pull(k)
# 350 
def_350_split = initial_split(def_350, prop=0.8)
def_350_train = training(def_350_split)
def_350_test  = testing(def_350_split)

knn100 = knnreg(price ~ mileage, data=def_350_train, k=100)
rmse(knn100, def_350_test)

def_350_test = def_350_test %>%
  mutate(price_350_pred = predict(knn100, def_350_test))

p_test_350 = ggplot(data = def_350_test) + 
  geom_point(mapping = aes(x = mileage, y = price), alpha=0.2) +
  geom_line(aes(x = mileage , y = price_350_pred), color='red', size=1.5)+ ggtitle("350")

p_test_350

#65 AMG
def_65_split = initial_split(def_65, prop=0.8)
def_65_train = training(def_65_split)
def_65_test  = testing(def_65_split)

knn100 = knnreg(price ~ mileage, data=def_65_train, k=100)
rmse(knn100, def_65_test)

def_65_test = def_65_test %>%
  mutate(price_65_pred = predict(knn100, def_65_test))

p_test_65 = ggplot(data = def_65_test) + 
  geom_point(mapping = aes(x = mileage, y = price), alpha=0.2) +
  geom_line(aes(x = mileage , y = price_65_pred), color='red', size=1.5)+ggtitle(" 65 AMG")

p_test_65
## 65 AMG has a bigger optimal value of k.

##Because 65 AMG trim has more data than 350 trim level.

