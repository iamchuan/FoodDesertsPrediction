# Food Deserts Prediction

Click here for the blog post: [Predicting Food Deserts via Social Media](https://iamchuan.com/2017/02/21/predicting-food-desert-via-social-media/#more-151)

I developed this project in 3 weeks at NYC Data Science Academy Bootcamp, with R, Python, and SQL. This repo contains the most important codes in the development stage.

> Data Source:

* Collected tweets posted from Dec 5 to Dec 16, 2016.
* Filtered out tweets without geolocation infomation. 
* Limited the scope to tweets about food ingestions by a list of [233 food names](https://github.com/iamchuan/FoodDesertsPrediction/blob/master/data_collection/foodList_collect/FoodList_cleaned.txt).
* Downloaded Food Desert distribution in census tract level from [USDA Food Desert Research Atlas](https://www.ers.usda.gov/data-products/food-access-research-atlas/)
* Scraped Socioeconomic Status (SES) in census tract level from  [Federal Financial Institutions Examination Council (FFIEC) online system](https://www.ffiec.gov/census/default.aspx) 

> Pipeline:

![](https://blog.nycdatascience.com/wp-content/uploads/2016/12/pipeline.025.jpeg)


© Chuan Hong [LinkedIn](https://www.linkedin.com/in/iamchuan/)