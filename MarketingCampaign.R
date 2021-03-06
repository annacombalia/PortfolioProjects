# Load libraries
library(readxl)
library(dplyr)
library(ggplot2)
library(tibble)
library(ggcorrplot)
library(reshape2)

# Read excel
marketing <- read_excel('marketing_campaign.xlsx')

# Add new columns
marketing <- marketing %>%
  mutate(MntSpent = MntFishProducts + MntMeatProducts + MntFruits + MntSweetProducts + MntWines + MntGoldProds) %>%
  mutate(NumPurchases = NumCatalogPurchases + NumStorePurchases + NumWebPurchases + NumDealsPurchases) %>%
  mutate(TotalKids = Kidhome + Teenhome) %>%
  mutate(AcceptedPrv = AcceptedCmp1 + AcceptedCmp2 + AcceptedCmp3 + AcceptedCmp4 + AcceptedCmp5) %>%
  mutate(Age = as.numeric(format(as.Date(Dt_Customer), format = '%Y')) - Year_Birth)

# Delete unwanted columns
marketing <- select(marketing,-c(Kidhome, Teenhome, Recency, NumWebVisitsMonth, Complain))

# Check for outliers: Income, Age & TotalKids
outiers_columns <- c('Income','Age','TotalKids')

melt.marketing <- marketing %>%
  select(one_of(outiers_columns)) %>%
  melt()

ggplot(melt.marketing, aes(factor(variable), value)) +
  geom_boxplot(color = 'steelblue') +
  facet_wrap(~variable, scale = 'free') +
  labs(title = 'Boxplot of Income, Age & TotalKids', x = 'Variables', y = 'Ranges')

summary(marketing$Income)
marketing <- marketing[!(marketing$Income > 600000),]
summary(marketing$Age)
age_outliers <- boxplot(marketing$Age)$out
marketing <- marketing[-which(marketing$Age %in% age_outliers),]
summary(marketing$TotalKids)
marketing %>% count(TotalKids)

# Total customers
n_distinct(marketing$ID)

# Correlation between numerical variables
corr_columns <- c('Age','Income','TotalKids','MntWines','MntFruits','MntMeatProducts',
                  'MntFishProducts','MntSweetProducts','MntGoldProds','MntSpent',
                  'NumDealsPurchases','NumWebPurchases','NumCatalogPurchases','NumStorePurchases',
                  'NumPurchases','AcceptedPrv','Response')
corr <- round(cor(marketing[,corr_columns]),2)

ggcorrplot(corr, method ='square',#lab = T, 
           title = 'Variable Correlation', legend.title = 'Correlation',
           type = 'upper', outline.color = 'white')

# Successful previous campaigns
campaign_list <- c('AcceptedCmp1', 'AcceptedCmp2', 'AcceptedCmp3',
                   'AcceptedCmp4', 'AcceptedCmp5')

sum_campaign <- marketing %>%
  select(campaign_list) %>% summarize_each(sum) %>%
  t() %>% as.data.frame() %>%
  rownames_to_column('Campaign')

colnames(sum_campaign) <- c('Campaign','Sums')
campaign <- gsub('Accepted', '', gsub(c('Mnt'), '', campaign_list))

ggplot(sum_campaign, aes(x = Campaign, y = Sums)) +
  geom_bar(stat = 'identity', fill = 'steelblue') +
  labs(x = 'Campaigns', y = 'Accepted')

# Group by Marital_Status
marketing %>% mutate (Marital_Status = case_when(
  marketing$Marital_Status %in% c('Married', 'Together') ~ 'Together',
  TRUE ~ 'Single')
) -> marketing


# Group by Income
min(marketing$Income)
max(marketing$Income)

marketing %>% mutate (Income_split = case_when(
  marketing$Income <= 20000 ~ '$1,000 - $20,000',
  marketing$Income <= 40000 ~ '$20,000 - $40,000',
  marketing$Income <= 60000 ~ '$40,000 - $60,000',
  marketing$Income <= 80000 ~ '$60,000 - $80,000',
  marketing$Income <= 100000 ~ '$80,000 - $100,000',
  marketing$Income <= 200000 ~ '>$100,000')
) -> marketing

marketing$Income_split <- factor(marketing$Income_split, 
                                 levels = c('$1,000 - $20,000', '$20,000 - $40,000',
                                            '$40,000 - $60,000', '$60,000 - $80,000',
                                            '$80,000 - $100,000', '>$100,000'))


# Group by Age
min(marketing$Age)
max(marketing$Age)

marketing %>% mutate (Age_split = case_when(
  marketing$Age <= 20 ~ '10 - 20 years old',
  marketing$Age <= 30 ~ '20 - 30 years old',
  marketing$Age <= 40 ~ '30 - 40 years old',
  marketing$Age <= 50 ~ '40 - 50 years old',
  marketing$Age <= 60 ~ '50 - 60 years old',
  marketing$Age <= 70 ~ '60 - 70 years old',
  marketing$Age <= 80 ~ '70 - 80 years old') 
) -> marketing

# Convert AcceptedPrv, Response & TotalKids to factors
marketing$AcceptedPrv <- factor(marketing$AcceptedPrv)
marketing$Response <- factor(marketing$Response)
marketing$TotalKids <- factor(marketing$TotalKids)

# Average customer: Marital_Status, Income, Education, Age, TotalKids
marketing %>% count(Marital_Status) %>% mutate(Percent = n/sum(n)*100)
marketing %>% count(Income_split) %>% mutate(Percent = n/sum(n)*100)
marketing %>% count(Education) %>% mutate(Percent = n/sum(n)*100)
marketing %>% count(Age_split) %>% mutate(Percent = n/sum(n)*100)
marketing %>% count(TotalKids) %>% mutate(Percent = n/sum(n)*100)

# Total revenue by Products
product_list <- c('MntWines', 'MntFruits', 'MntMeatProducts', 'MntFishProducts',
                  'MntSweetProducts', 'MntGoldProds')

sum_products <- marketing %>%
  select(product_list) %>% summarize_each(sum) %>%
  t() %>% as.data.frame() %>%
  rownames_to_column('Products')

colnames(sum_products) <- c('Products','Sums')
products <- gsub('Products', '', gsub(c('Mnt'), '', gsub(c('Prods'), '', product_list)))

# Pie chart - Products
ggplot(sum_products, aes(x='', y=Sums, fill = products)) +
  geom_col(color = 'black') +
  coord_polar('y', start = 0) +
  geom_text(aes(label = paste('$',Sums)), size=4.5,
            position = position_stack(vjust = 0.5)) +
  theme(panel.background = element_blank(),
        axis.ticks = element_blank(),
        axis.text=element_blank(),
        axis.text.x=element_text(colour='black'),
        axis.title=element_blank(),
        axis.line = element_blank()) +
  labs(title = 'Total Sales by Products', fill = 'Products',
       caption = paste('Total Revenue: $', sum(sum_products$Sums)))+
  scale_y_continuous(breaks = cumsum(sum_products$Sums) - sum_products$Sums / 2,
                     labels = paste(round(sum_products$Sums/sum(sum_products$Sums) * 100, 1), '%'))

# Total Purchases by method
purchase_list <- c('NumWebPurchases','NumStorePurchases',
                   'NumCatalogPurchases'
)

sum_purchase <- marketing %>%
  select(purchase_list) %>% summarize_each(sum) %>%
  t() %>% as.data.frame() %>%
  rownames_to_column('Purchase')

colnames(sum_purchase) <- c('Purchase','Total')
purchase <- gsub('Purchase', '', gsub(c('Num'), '', gsub(c('Purchases'), '', purchase_list)))

# Pie chart - Purchases
windows()
ggplot(sum_purchase, aes(x='', y=Total, fill = purchase)) +
  geom_col(color = 'black') +
  coord_polar('y', start = 0) +
  geom_text(aes(label = Total), size=4.5,
            position = position_stack(vjust = 0.5)) +
  theme(panel.background = element_blank(),
        axis.ticks = element_blank(),
        axis.text=element_blank(),
        axis.text.x=element_text(colour='black'),
        axis.title=element_blank(),
        axis.line = element_blank()) +
  labs(title = 'Total Purchases by Method', fill = 'Purchase Method',
       caption = paste('Total Purchases: ', sum(sum_purchase$Total)))+
  scale_y_continuous(breaks = cumsum(sum_purchase$Total) - sum_purchase$Total /2,
                     labels = paste(round(sum_purchase$Total/sum(sum_purchase$Total) * 100, 1), '%'))

# AcceptedPrv vs multiple variables
ggplot(marketing) + geom_bar(aes(x = AcceptedPrv))
marketing %>% count(AcceptedPrv) %>% mutate(Percent = n/sum(n))

prv_cmp <- marketing[marketing$AcceptedPrv != 0,]

ggplot(prv_cmp, aes(x = AcceptedPrv, fill = Education)) + 
  geom_bar(position='dodge')

ggplot(prv_cmp, aes(x = AcceptedPrv, fill = Marital_Status)) + 
  geom_bar(position='dodge') +
  scale_fill_discrete(name = 'Marital Status')

ggplot(prv_cmp, aes(x = AcceptedPrv, fill = TotalKids)) + 
  geom_bar(position='dodge') +
  scale_fill_discrete(name = 'Total Kids')

ggplot(prv_cmp, aes(x = AcceptedPrv, fill = Income_split)) + 
  geom_bar(position='dodge') +
  scale_fill_discrete(name = 'Income')

ggplot(prv_cmp, aes(x=AcceptedPrv, y= Age)) + geom_boxplot()

ggplot(prv_cmp, aes(x=AcceptedPrv, y= MntSpent)) + geom_boxplot()

# Response vs AcceptedPrv
ggplot(marketing) + geom_bar(aes(x = Response))
marketing %>% count(Response) %>% mutate(Percent = round(n/sum(n),4))

respon <- marketing[marketing$Response == 1,]

ggplot(respon, aes(x = Response, fill = AcceptedPrv)) + 
  geom_bar(position='dodge')

total_acceptedprv <- marketing %>% count(AcceptedPrv) %>% 
  mutate(Percent = round(n/sum(n),4)) %>% 
  arrange(desc(n))
accepted_prv <- respon %>% count(AcceptedPrv) %>% 
  mutate(Percent = round(n/sum(n),4)) %>% 
  arrange(desc(n))
percent_response <- accepted_prv[,2]/total_acceptedprv[,2]

# Response vs multiple variables
ggplot(respon, aes(x = Response, fill = Education)) + 
  geom_bar(position='dodge')
respon %>% count(Education) %>% 
  mutate(Percent = round(n/sum(n),4)) %>% 
  arrange(desc(n))

ggplot(respon, aes(x = Response, fill = Marital_Status)) + 
  geom_bar(position='dodge') +
  scale_fill_discrete(name = 'Marital Status')
respon %>% count(Marital_Status) %>% 
  mutate(Percent = round(n/sum(n),4)) %>% 
  arrange(desc(n))

ggplot(respon, aes(x = Response, fill = TotalKids)) + 
  geom_bar(position='dodge') +
  scale_fill_discrete(name = 'Total Kids')
respon %>% count(TotalKids) %>% 
  mutate(Percent = round(n/sum(n),4)) %>% 
  arrange(desc(n))

ggplot(respon, aes(x = Response, fill = Income_split)) + 
  geom_bar(position='dodge') +
  scale_fill_discrete(name = 'Income')
respon %>% count(Income_split) %>% 
  mutate(Percent = round(n/sum(n),4)) %>% 
  arrange(desc(n))

ggplot(marketing, aes(x=Response, y= Age)) + geom_boxplot()
respon %>% count(Age_split) %>% 
  mutate(Percent = round(n/sum(n),4)) %>% 
  arrange(desc(n))

ggplot(marketing, aes(x=Response, y= MntSpent)) + geom_boxplot()

# Other variable relationships
ggplot(data=marketing, aes(x=MntSpent, y=Income)) + 
  geom_point() + geom_smooth(method = lm)

ggplot(data=marketing, aes(x=MntSpent, y=MntWines)) + 
  geom_point() + geom_smooth(method = lm)

ggplot(data=marketing, aes(x=MntSpent, y=MntMeatProducts)) + 
  geom_point() + geom_smooth(method = lm)

ggplot(data=marketing, aes(x=MntSpent, y=NumPurchases)) + 
  geom_point() + geom_smooth(method = lm)

ggplot(marketing, aes(x=TotalKids, y= MntSpent)) + 
  geom_boxplot()

ggplot(data=marketing, aes(x=NumPurchases, y=NumStorePurchases)) + 
  geom_point() + geom_smooth(method = lm)
