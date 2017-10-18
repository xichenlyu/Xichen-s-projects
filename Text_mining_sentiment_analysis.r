library(readr)
library(tidyr)
library(tidytext)
library(okcupiddata)
library(ggplot2)
library(dplyr)
library(stringr)
library(scales) # scale functions for visualization
library(wordcloud)
library(igraph)
library(ggraph)
library(reshape2)
library(janeaustenr)


# subset the `okcupid profiles` object into the essays and smoker status columns.
n <- nrow(profiles)
tidy_okcupid <- data.frame(profiles)

tidy_okcupid <- select_(tidy_okcupid,"essay0","sex") 
tidy_okcupid <- data_frame(line=1:n, text=tidy_okcupid$essay0,
                           sex= tidy_okcupid$sex) %>%
  unnest_tokens(word, text)
# Take a look at the saperated words data set
tidy_okcupid

# Filter out stop words
tidy_okcupid <- tidy_okcupid %>%
  anti_join(stop_words)
tidy_okcupid

# Classify by sentiments
nrcpos <- get_sentiments("nrc") %>% 
  filter(sentiment == "positive")
nrcneg <- get_sentiments("nrc") %>%
  filter(sentiment == "negative")

# Count word frequency
tidy_okypos <-tidy_okcupid %>%
  filter(sex == "m") %>%
  inner_join(nrcpos) %>%
  count(word, sort = TRUE)

tidy_okyneg <-tidy_okcupid %>%
  filter(sex == "m") %>%
  inner_join(nrcneg) %>%
  count(word, sort = TRUE)

top_n(tidy_okypos,10)
top_n(tidy_okyneg,10)

# Try using bing sentiments rule
sentbing <- tidy_okcupid %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, index = line %/% 10, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(sentiment = positive - negative)

sexwords <- tidy_okcupid %>% 
  filter(sex == "m")

bing_word_counts <- sexwords %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  ungroup()

bing_word_counts %>%
  group_by(sentiment) %>%
  top_n(10) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~sentiment, scales = "free_y") +
  labs(y = "Contribution to sentiment",
       x = NULL) +
  coord_flip()

# Get word cloud
sexwords%>%
  anti_join(stop_words) %>%
  count(word) %>%
  with(wordcloud(word, n, max.words = 100))

#Get sentiment word cloud
sexwords %>%
  inner_join(get_sentiments("bing")) %>%
  count(word, sentiment, sort = TRUE) %>%
  acast(word ~ sentiment, value.var = "n", fill = 0) %>%
  comparison.cloud(colors = c("#F8766D", "#00BFC4"),
                   max.words = 100)

