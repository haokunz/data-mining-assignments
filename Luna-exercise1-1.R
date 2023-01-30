library(tidyverse)
library(lubridate)
library(magrittr)
library(ggplot2)
library(plyr)

flights <- read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/ABIA.csv")

dim(flights)
colnames(flights)
head(flights)
str(flights)

summary(flights$DepTime)

# select data that do not have Na in both Departure time and departure delay
departure_index <- !(is.na(flights$DepTime) | (is.na(flights$DepDelay)))
departure_index

dflights <- flights[departure_index, ]

# convert the departure time in time stamps
a <- sprintf("%04d",dflights$DepTime)
dflights$DepTime <-strptime(a, format="%H%M") 

# Only look into the positive numbers as they are delayed flights 
dflights <- dflights[dflights$DepDelay > 0, ]

plot(dflights$DepTime, dflights$DepDelay)

# bin the delay time to illustrate broad sense of delay happening
dflights$time_bin <- format(floor_date(dflights$DepTime, '1 hour'), format = "%H:%M")

aggregate(DepDelay ~ time_bin, dflights, mean)

# The best time of day to fly to minimize the delays will be 5-8 AM,
# and the average delay time is less than 10 minutes. For 8-10 AM, 
# the average delay time is still less than 20 minutes.

boxplot(DepDelay ~ time_bin, data = dflights)

avg_combine <- aggregate(DepDelay ~ UniqueCarrier + time_bin, dflights, mean)
ggplot(data = avg_combine, aes(x = time_bin, y = DepDelay,
                               group = UniqueCarrier, color = UniqueCarrier)) +
                               theme(axis.text.x = element_text(angle = 90)) +
                               geom_line()

# The above trend may differ depends on airlines. In 7-8AM, the EV airline have
# an average delay departure time more than one hour. In other case, for example F9,
# may have extreme delay departure time, more than 200 minutes, for 9-10 AM. 


