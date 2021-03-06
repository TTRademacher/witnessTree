#=======================================================================================
# Read climate data from the Harvard Forest weather station.
#---------------------------------------------------------------------------------------

# Load dependencies
#----------------------------------------------------------------------------------------
if (!existsFunction ('read_csv'))   library ('tidyverse')
if (!existsFunction ('floor_date')) library ('lubridate')
if (!existsFunction ('esat'))       library ('plantecophys')

# Read climate data from the appropriate weather station, default is the Fisher 
# meterorological station at Harvard Forest 
#----------------------------------------------------------------------------------------
suppressWarnings (met_HF_shaler  <- read_csv (file = url ('http://harvardforest.fas.harvard.edu/data/p00/hf000/hf000-01-daily-m.csv'),
                                                col_types = cols()))
met_HF_shaler$TIMESTAMP <- as.POSIXct (met_HF_shaler$date, 
                                       format = '%Y-%m-%d',
                                       tz = 'EST') 
suppressWarnings (met_HF_gap <- read_csv (file = url ('http://harvardforest.fas.harvard.edu/data/p00/hf001/hf001-08-hourly-m.csv'),
                                          col_types = cols()))
met_HF_gap$TIMESTAMP <- as.POSIXct (met_HF_gap$datetime, 
                                    format = '%Y-%m-%d %H:%M:%S',
                                    tz = 'EST') 
suppressWarnings (met_HF_old <- read_csv (file = url ('http://harvardforest.fas.harvard.edu/data/p00/hf001/hf001-10-15min-m.csv'),
                                          col_types = cols()))
met_HF_old$TIMESTAMP <- as.POSIXct (met_HF_old$datetime, 
                                    format = '%Y-%m-%d %H:%M:%S',
                                    tz = 'EST') 
suppressWarnings (met_HF_current <- read_csv (file = url ('http://harvardforest.fas.harvard.edu/sites/harvardforest.fas.harvard.edu/files/weather/qfm.csv'),
                                              col_types = cols()))
met_HF_current$TIMESTAMP <- as.POSIXct (met_HF_current$datetime, 
                                        format = '%Y-%m-%d %H:%M:%S',
                                        tz = 'EST') 

dates  <- c (met_HF_shaler$TIMESTAMP, met_HF_gap$TIMESTAMP, met_HF_old$TIMESTAMP, met_HF_current$TIMESTAMP)
dates2 <- c (met_HF_gap$TIMESTAMP, met_HF_old$TIMESTAMP, met_HF_current$TIMESTAMP)
airt <- tibble (TIMESTAMP = dates, airt = c (as.numeric (met_HF_shaler$airt), met_HF_gap$airt, met_HF_old$airt, met_HF_current$airt))
prec <- tibble (TIMESTAMP = dates, prec = c (as.numeric (met_HF_shaler$prec), met_HF_gap$prec, met_HF_old$prec, met_HF_current$prec))
wind <- tibble (TIMESTAMP = dates2, wind = c (met_HF_gap$wspd, met_HF_old$wspd, met_HF_current$wspd))
gust <- tibble (TIMESTAMP = dates2, gust = c (met_HF_gap$gspd, met_HF_old$gspd, met_HF_current$gspd))
rehu <- tibble (TIMESTAMP = dates2, relativeHumidity = c (met_HF_gap$rh, met_HF_old$rh, met_HF_current$rh))

# Add variable for different period to airt (i.e. day, week, month, year)
#----------------------------------------------------------------------------------------
airt <- airt [-1, ]
airt <- add_column (airt, day   = format (airt [['TIMESTAMP']], '%Y-%m-%d'))
airt <- add_column (airt, week  = floor ((airt [['TIMESTAMP']] - 
                                         (min (airt [['TIMESTAMP']], na.rm = T) - 
                                          3 * 60.0 * 60.0 * 24.0)) / 
                                          dweeks (1)))
airt <- add_column (airt, month = floor_date (airt [['TIMESTAMP']], 'month'))
airt <- add_column (airt, year  = floor_date (airt [['TIMESTAMP']], 'year'))

# Create mean airt over varying periods (i.e. day, week, month, year)
#----------------------------------------------------------------------------------------
dailyAirt    <- airt %>% group_by (day) %>% summarise (airt = mean (airt, na.rm = T))
dailyMaxAirt <- suppressWarnings (airt %>% group_by (day) %>% 
                                  summarise (airt = max  (airt, na.rm = T)))
dailyAirt    <- dailyAirt [!is.na (dailyAirt [['day']]),]
dailyMaxAirt <- dailyMaxAirt [!is.na (dailyMaxAirt [['day']]),]
weeklyAirt   <- airt %>% group_by (week) %>% summarise (airt = mean (airt, na.rm = T))
weeklyAirt   <- weeklyAirt [!is.na (weeklyAirt [['week']]), ]
monthlyAirt  <- airt %>% group_by (month) %>% summarise (airt = mean (airt, na.rm = T))
monthlyAirt  <- monthlyAirt [!is.na (monthlyAirt [['month']]), ]
yearlyAirt   <- airt %>% group_by (year) %>% summarise (airt = mean (airt, na.rm = T))
yearlyAirt   <- yearlyAirt [!is.na (yearlyAirt [['year']]), ]

# Rank intervals from highest to lowest
#----------------------------------------------------------------------------------------
airt         <- add_column (airt,         rank = rank (-airt         [['airt']]))
dailyAirt    <- add_column (dailyAirt,    rank = rank (-dailyAirt    [['airt']]))
dailyMaxAirt <- add_column (dailyMaxAirt, rank = rank (-dailyMaxAirt [['airt']]))
weeklyAirt   <- add_column (weeklyAirt,   rank = rank (-weeklyAirt   [['airt']]))
monthlyAirt  <- add_column (monthlyAirt,  rank = rank (-monthlyAirt  [['airt']]))
yearlyAirt   <- add_column (yearlyAirt,   rank = rank (-yearlyAirt   [['airt']]))
  
# Add variable for different period to prec (i.e. day, week, month, year)
#----------------------------------------------------------------------------------------
prec <- add_column (prec, day   = format (prec [['TIMESTAMP']], '%Y-%m-%d'))
prec <- add_column (prec, week  = floor ((prec [['TIMESTAMP']] - 
                                         (min (prec [['TIMESTAMP']], na.rm = T) - 
                                          3 * 60.0 * 60.0 * 24.0)) / 
                                          dweeks (1)))
prec <- add_column (prec, month = floor_date (prec [['TIMESTAMP']], 'month'))
prec <- add_column (prec, year  = floor_date (prec [['TIMESTAMP']], 'year'))

# Create mean prec over varying periods (i.e. day, week, month, year)
#----------------------------------------------------------------------------------------
dailyPrec   <- prec %>% group_by (day) %>% summarise (prec = sum (prec, na.rm = T))
dailyPrec   <- dailyPrec [!is.na (dailyPrec [['day']]),]
weeklyPrec  <- prec %>% group_by (week) %>% summarise (prec = sum (prec, na.rm = T))
weeklyPrec  <- weeklyPrec [!is.na (weeklyPrec [['week']]), ]
monthlyPrec <- prec %>% group_by (month) %>% summarise (prec = sum (prec, na.rm = T))
monthlyPrec <- monthlyPrec [!is.na (monthlyPrec [['month']]), ]
yearlyPrec  <- prec %>% group_by (year) %>% summarise (prec = sum (prec, na.rm = T))
yearlyPrec  <- yearlyPrec [!is.na (yearlyPrec [['year']]), ]

# Rank intervals from highest to lowest
#----------------------------------------------------------------------------------------
prec         <- add_column (prec,         rank = rank (-prec         [['prec']]))
dailyPrec    <- add_column (dailyPrec,    rank = rank (-dailyPrec    [['prec']]))
weeklyPrec   <- add_column (weeklyPrec,   rank = rank (-weeklyPrec   [['prec']]))
monthlyPrec  <- add_column (monthlyPrec,  rank = rank (-monthlyPrec  [['prec']]))
yearlyPrec   <- add_column (yearlyPrec,   rank = rank (-yearlyPrec   [['prec']]))

# Add variable for different period to wind (i.e. day, week, month, year)
#----------------------------------------------------------------------------------------
wind <- add_column (wind, day = format (wind [['TIMESTAMP']], '%Y-%m-%d'))
gust <- add_column (gust, day = format (gust [['TIMESTAMP']], '%Y-%m-%d'))

# Create daily max wind speed over
#----------------------------------------------------------------------------------------
dailyWind <- gust %>% group_by (day) %>% summarise (gust = max (gust, na.rm = T))
dailyWind <- dailyWind [!is.na (dailyWind [['day']]),]

# Add variable for day to rehu to get mean daily relative humidity
#----------------------------------------------------------------------------------------
rehu <- add_column (rehu, day = format (rehu [['TIMESTAMP']], '%Y-%m-%d'))
dailyReHu <- rehu %>% group_by (day) %>% summarise (relativeHumidity = mean (relativeHumidity, na.rm = T))
dailyReHu <- dailyReHu [!is.na (dailyReHu [['day']]), ]

# calcualte daily vapour pressure deficit
#----------------------------------------------------------------------------------------
dailyVPD <- tibble (day = dailyReHu [['day']],
                    VPS = RHtoVPD (RH = dailyReHu [['relativeHumidity']], 
                                   TdegC = dailyAirt [['airt']] [dailyAirt [['day']] >= dailyReHu [['day']] [1]], 
                                   Pa = 101)) # Should make pressure a variable as well.

# delete temporary variables
#----------------------------------------------------------------------------------------
rm (met_HF_current, met_HF_gap, met_HF_old, met_HF_shaler, rehu, wind, dates, dates2)
#========================================================================================