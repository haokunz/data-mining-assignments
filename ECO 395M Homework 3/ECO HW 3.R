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
# 2.62 crimes decreased in the National Mall area, implying 15 percent of decline during high-alert days. Crime also decreases in the other distrcts, though the effect is not statistically significant.
# Lastly, ten percentage of increase on midday ridership increases 0.24 percent of crime rate.

## Tree modeling: dengue cases

dengue <- read.csv('../data/dengue.csv')

