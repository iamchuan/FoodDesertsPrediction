setwd("./Workspace/food_analysis/")
library(data.table)
rm(list = ls())

tweets <- read.csv('./tract_1/tweets_lite.csv', stringsAsFactors = FALSE)
str(tweets)

tweets <- tweets[tweets$block != "None",]
tweets <- tweets[tweets$block != "",]


library(dplyr)
tweets <- tweets %>% 
  mutate(CensusTract = substring(block, first = 1, last = 11),
         block = substring(block, first = 12, last = 15))



## load SES
demographic <- read.csv('./data_collection/SES_tables/demographic.csv',
                        stringsAsFactors = FALSE,
                        row.names = NULL) %>% select(-index)

housing <- read.csv("./data_collection/SES_tables/housing.csv", 
                    stringsAsFactors = FALSE,
                    row.names = NULL) %>% select(-index)

income <- read.csv("./data_collection/SES_tables/income.csv", 
                   stringsAsFactors = FALSE,
                   row.names = NULL) %>% select(-index)

population <- read.csv("./data_collection/SES_tables/population.csv", 
                       stringsAsFactors = FALSE,
                       row.names = NULL) %>% select(-index)

demographic <- unique(demographic)

## Create census tract
addTractNumber <- function(data) {
  data %>% 
    mutate(State.Code = sprintf("%02d", State.Code),
           County.Code = sprintf("%03d", County.Code),
           Tract.Code = sprintf("%06d", Tract.Code * 100),
           CensusTract = paste0(State.Code, County.Code, Tract.Code))
}

demographic <- addTractNumber(demographic)
demographic <- demographic[!duplicated(demographic$CensusTract),]

housing <- addTractNumber(housing)
housing <- housing[!duplicated(housing$CensusTract),]

income <- addTractNumber(income)
income <- income[!duplicated(income$CensusTract),]

population <- addTractNumber(population)
population <- population[!duplicated(population$CensusTract),]


## load FoodAccess tables
foodAccess13 <- read.csv("./data_collection/food_desert/FoodAccess_2013.csv", 
                         stringsAsFactors = FALSE)
foodAccess <- read.csv("./data_collection/food_desert/FoodAccess_2017.csv", 
                       stringsAsFactors = FALSE)

## add leading 0 to CensusTract
foodAccess$CensusTract <- gsub(" ", "0", 
                               sprintf("%11s", 
                                       as.character(foodAccess$CensusTract)))

## Join tables
fases <- foodAccess %>%
  inner_join(demographic, by = "CensusTract") %>%
  inner_join(housing, by = "CensusTract") %>%
  inner_join(income, by = "CensusTract") %>%
  inner_join(population, by = "CensusTract")

colnames(fases)

fases <- fases %>%
  select(CensusTract,
         Tract.Minority...x, 
         Non.Hisp.White.Population,
         Median.House.Age..Years.,
         Owner.Occupied.Units.x,
         Distressed.or.Under..served.Tract,
         Tract.Population.x,
         X..of.House..holds,
         X2016.Est..Tract.Median.Family.Income.x,
         X..Below.Poverty.Line,
         Number.of.Families,
         HUNVFlag,
         lahunvhalfshare,
         lakids1share,
         lakids10share,
         laseniors1share,
         laseniors10share,
         lalowi1share,
         lalowi10share,
         PCTGQTRS,
         Urban,
         LILATracts_halfAnd10,
         LILATracts_1And10,
         LILATracts_1And20,
         LILATracts_Vehicle)

saveRDS(fases, "./fases.rds")


# tweets vs. food desert
length(setdiff(tweets$CensusTract, fases$CensusTract))

tweets %>% 
  left_join(fases, by = "CensusTract") %>%
  group_by(LILATracts_1And10) %>%
  summarise(count = n())

# read nutrition table
abbrev <- read.csv("./data_collection/food_list/USDA_food_database_ABBREV.csv", 
                   stringsAsFactors = FALSE)

food_list <- scan("./data_collection/food_list/FoodList_cleaned.txt", what="", sep="\n")


abbrev[is.na(abbrev)] <- 0

nutritions <- abbrev %>% 
  mutate(food_type = gsub("[,(\\].*$", "", Shrt_Desc)) %>%
  group_by(food_type) %>%
  summarise(energy = mean(Energ_Kcal),
            sugar = mean(Sugar_Tot_.g.),
            fat = mean(Lipid_Tot_.g.),
            chol = mean(Cholestrl_.mg.),
            fiber = mean(Fiber_TD_.g.),
            protein = mean(Protein_.g.))

text_to_nutrition <- function(text) {
  pos <- sapply(nutritions$food_type, 
                function(food) grepl(food, text, 
                                     ignore.case = TRUE))
  nutritions %>% 
    select(-food_type) %>%
    filter(pos) %>%
    summarise_each(funs(mean))
}

nut_cols <- names(nutritions)[-1]

text_nutrition <- NULL

tweets_cbind <- cbind(tweets[1,], data.frame(text_to_nutrition(tweets$text[1])))
for(i in 2:nrow((tweets))) {
  if(i %% 1000 == 0) print(i)
  tweets_cbind <- rbind(tweets_cbind,
                        cbind(tweets[i,], 
                              data.frame(text_to_nutrition(tweets$text[i]))))
}
  
table(is.na(tweets_cbind$energy))

tweets_cbind[complete.cases(tweets_cbind),] %>% 
  inner_join(fases, by="CensusTract") %>%
  group_by(LILATracts_1And10) %>%
  summarise(mean_energy = mean(energy),
            mean_sugar = mean(sugar),
            mean_fat = mean(fat),
            mean_chol = mean(chol),
            mean_fiber = mean(fiber),
            mean_protein = mean(protein))

tweets_fases <- tweets_cbind[complete.cases(tweets_cbind),] %>% 
  inner_join(fases, by="CensusTract") 


tweets_fases
saveRDS(tweets_fases, "tweets_fases_2.rds")

tweets_prob <- unique(read.csv("./tweets_prob.csv", stringsAsFactors = FALSE))

tweets_all <- tweets_fases %>%
  inner_join(tweets_prob, by = c("created_at", "text", "lat", "lon", "source"))

tweets_all <- tweets_all[!duplicated(tweets_all$text), ]
tweets_all <- tweets_all[complete.cases(tweets_all),]

tweets_all %>% 
  # filter(LILATracts_1And10 == 1) %>%
  group_by(LILATracts_1And10) %>%
  summarise(mean_energy = mean(energy),
            mean_sugar = mean(sugar),
            mean_fat = mean(fat),
            mean_chol = mean(chol),
            mean_fiber = mean(fiber),
            mean_protein = mean(protein))

tweets_all$X2016.Est..Tract.Median.Family.Income.x <- as.numeric(sub(",","",
                                                                     sub("\\$","",
                                                                         tweets_all$X2016.Est..Tract.Median.Family.Income.x)))
table(tweets_all$Distressed.or.Under..served.Tract)
write.csv(tweets_all, 
          file = "./tweets_all.csv",
          row.names = FALSE)
