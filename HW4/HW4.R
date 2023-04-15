## Clustering and PCA

# The data in [wine.csv](../data/wine.csv) contains information on 11 chemical properties of 6500 different bottles of _vinho verde_ wine from northern Portugal.  In addition, two other variables about each wine are recorded:
#  - whether the wine is red or white  
#- the quality of the wine, as judged on a 1-10 scale by a panel of certified wine snobs.  

#Run both PCA and a clustering algorithm of your choice on the 11 chemical properties (or suitable transformations thereof) and summarize your results.  Which dimensionality reduction technique makes more sense to you for this data?  Convince yourself (and me) that your chosen method is easily capable of distinguishing the reds from the whites, using only the "unsupervised" information contained in the data on chemical properties.  Does your unsupervised technique also seem capable of distinguishing the higher from the lower quality wines?  
  
#  To clarify: I'm not asking you to run an supervised learning algorithms.  Rather, I'm asking you to see whether the differences in the labels (red/white and quality score) emerge naturally from applying an unsupervised technique to the chemical properties.  This should be straightforward to assess using plots.  

library(tidyverse)
library(usmap)
library(lubridate)
library(randomForest)
library(splines)
library(pdp)
library(string)

# read data
wine = read.csv("https://raw.githubusercontent.com/jgscott/ECO395M/master/data/wine.csv")
head(wine)

# replace color with 1 and 0

wine$color<-gsub("red", 1, wine)
wine$color<-sub("white", 0, wine)
head(wine)

###
# PCA
###

# Now run PCA on the wine data
pc_wine = prcomp(wine, rank=5, scale=TRUE)
