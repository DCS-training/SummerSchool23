############ TEXT ANALYSIS  ##################

# RESEARCH QUESTIONS ##############
# 1. What can we observe about the number and length of articles on the cost of living in the last 3 years? How do the data sets compare?
# 2. Can we see a difference in the wording about the cost of living between the data sets?

# PART1: DATA CLEANING AND BASIC ANALYSIS
# 1. Getting Setup ====================
## 1.1. Load required libraries ------------
install.packages("lexicon")
install.packages("wordcloud")
install.packages("textstem")
install.packages("quanteda.textmodels")
install.packages("quanteda.textplots")
install.packages("tidytext")
library(quanteda)
library(quanteda.textplots)
library(quanteda.textmodels)
library(lexicon)
library(tidyverse)
library (tm)

## 1.2 Load the Uk data ------------
uk_data <- read_csv("Day1/WebScraping/outputs/UKNews.csv")

## 1.3  Examine the data ------------
summary(uk_data)
# Drop the first column that we do not need
uk_data<-uk_data[, 2:4]

# 2. Basic Cleaning =================
# Look at the text of our articles
head(uk_data$clean_text)
# There are a lot of formatting errors (next line, next paragraph) that we want to clean up
uk_data_clean <- mutate_if(uk_data, 
                           is.character, #apply the changes only if the data is a "character" type (e.g. text)
                           str_replace_all, 
                           pattern = "\r?\n|\r", #What I am searching for: scraped text reflected paragraph/line breaks in the original online text
                           replacement = " ")#What I am replacing the search matches with (a blank space)

# This will insert only one space regardless whether the text contains \r\n, \n or \r.
# Let's check the results
head(uk_data_clean$clean_text) # Now, it's much cleaner. We will perform cleaning and preprocessing in more detail later on.

# 3. Create a Quanteda Corpus ===========
# Create a Quanteda corpus of the 'article text' column from our data set:
article_text<-corpus(uk_data_clean, text_field='clean_text')

# 4. Extract Information about the Corpus ================
# Some methods for extracting information about the corpus:
# Print doc in position 5 of the corpus
summary(article_text, 5)
# Check how many docs are in the corpus
ndoc(article_text) 
# Check number of characters in the first 10 documents of the corpus
nchar(article_text[1:10]) 
# Check number of tokens in the first 10 documents
ntoken(article_text[1:10]) 

## 4.1 Visualise these results --------------
# Create a new vector with tokens for all articles and store the vector as a new data frame with three columns (Ntoken, Dataset, Date)
NtokenUK<-as.vector(ntoken(article_text))
TokenUK <-data.frame(Tokens=NtokenUK, Dataset="UK", Date=uk_data_clean$dates)
# Let's explore the number of articles published and their length to see if we can answer research question #1.
# First, let's extract Year and Month from the dates 
TokenUK$MonthYear <- format(as.Date(TokenUK$Date, format="%Y-%m-%d"),"%Y-%m")
# Now we can group the data by Month/Year and, for each group, count 1) how many articles were published and 2) how many tokens they contained
BreakoutUK<- TokenUK %>%
  group_by(MonthYear,Dataset)%>%
  summarize(NArticles=n(), MeanTokens=round(mean(Tokens)))
# Now we can plot the trends. We are going to focus on plots on Friday
ggplot(BreakoutUK, aes(x=MonthYear, y=NArticles))+ # Select data set and coordinates we are going to plot
  geom_point(aes(size=MeanTokens, fill=MeanTokens),shape=21, stroke=1.5, alpha=0.9, colour="black")+ # Which graph I want 
  labs(x = "Timeline", y = "Number of Articles", fill = "Mean of Tokens", size="Mean of Tokens", title="Number of Articles and Tokens in the UK Gov Website")+ # Rename labs and title
  geom_path(aes(group=1), colour="black", size=1)+ # Add a line that will connect the dots 
  scale_size_continuous(range = c(5, 15))+ # Resize the dots to be bigger
  geom_text(aes(label=MeanTokens))+ # Add the mean of tokens in the dots
  scale_fill_viridis_c(option = "plasma")+ # Change the colour coding
  theme_bw()+ # B/W Background
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1), legend.position = "bottom")+ # Rotate labels of x and move them slightly down. Plus move the position to the bottom 
  guides(size = "none") # Remove the Size from the Legend 

# Discussion question: what is the graph telling us about our data?

# 5. Tokenise the Corpus =================
# Now, we can tokenise the corpus, which will break the textual data into separate words grouped by document. We are also removing symbols, URLs, and punctuation.
article_tokens <- quanteda::tokens(article_text, 
                                   remove_symbols=TRUE, 
                                   remove_url=TRUE, 
                                   remove_punct=TRUE)
                                   
# Take a look at our tokens list by printing the second document:
article_tokens[2]

# Remove tokens under 3 characters. (Shorter words won't tell us much about our data, and because we removed punctuation, we want to get rid of the 
                                   #truncated contractions--e.g. I'm -->'I', 'm')
article_tokens <- tokens_select(article_tokens, min_nchar = 3)

# 6. Keywords in Context =================
# keyword search examples (using kwic aka "keyword in context")
kwic(article_tokens, "cost")
kwic(article_tokens, "cost", 3)
article_tokens %>% 
  kwic(pattern = phrase("cost of living"))
#Discussion: Examining the output, why do you think we get 0 matches for this search? 
                                   
article_tokens %>%
  kwic(pattern=c("price", "bills", "payment"))

# 7. Visualise the Results ==============
# Convert to document-feature matrix (aka "dfm")
dfm_uk <- dfm(article_tokens)

## 7.1. Wordcolud ----------------------
# Plot a wordcloud
textplot_wordcloud(dfm_uk, max_words=100, color='black')
# What observations do we have about the wordcloud? what should our next steps be?

## 7.2. Cleaning the Wordcloud ----------------------
# To lowercase
dfm_uk <- dfm_tolower(dfm_uk)

# Remove Stop-words
dfm_nostop <- dfm_remove(dfm_uk, stopwords('english'))
topfeatures(dfm_nostop, 10)
topfeatures(dfm_uk, 10)


#Let's try the word cloud again:
textplot_wordcloud(dfm_nostop, rotation = 0.25,
                   max_words=50,
                   color = rev(RColorBrewer::brewer.pal(10, "Spectral")))

# What observations do we have?

## 7.3. Remove Custom Stopwords --------------------
# We can also create a custom list of words to remove from the corpus

customstopwords <- c("cost", "living", "will")#removed keywords that aren't telling us much or that skew the results

dfm_nostop_cost <- dfm_remove(dfm_uk, c(stopwords('english'), customstopwords))
topfeatures(dfm_nostop, 10)
topfeatures(dfm_nostop_cost, 10)

# 8. Further Cleaning =====================
# Further steps for cleaning: stemming vs. lemmatization
## 8.1. Stemming ===========
nostop_toks <- tokens_select(article_tokens, pattern = stopwords("en"), selection = "remove")
stem_toks <- tokens_wordstem(nostop_toks, language=quanteda_options('language_stemmer'))
stem_dfm <- dfm(stem_toks)
# Let's see the top features
topfeatures(stem_dfm, 30)

## 8.2. Lemmatization ================
lemmas <- tokens_replace(nostop_toks, pattern = lexicon::hash_lemmas$token, replacement = lexicon::hash_lemmas$lemma)
lemma_dfm <- dfm(lemmas)

topfeatures(stem_dfm, 20)
topfeatures(lemma_dfm, 20)

# Discussion: What can we observe about stemming and lemmatization? which method (if any) is better for answering our research questions, and why?

# Make a word cloud of the lemmatized results:
textplot_wordcloud(lemma_dfm, rotation = 0.25,
                   max_words=50,
                   color = rev(RColorBrewer::brewer.pal(10, "Paired")))

# 9. Plot Frequency #########
# Plot the top 20 words (non-lemmatized) in another way:
top_keys <- topfeatures (dfm_nostop, 20)
data.frame(list(term = names(top_keys), frequency = unname(top_keys))) %>% # Create a data.frame for ggplot
  ggplot(aes(x = reorder(term,-frequency), y = frequency)) + # Plotting with ggplot2
  geom_point() +
  theme_bw() +
  labs(x = "Term", y = "Frequency") +
  theme(axis.text.x=element_text(angle=90, hjust=1))

# 10. Exercise 1. Comparing the Datasets: #########

# Now, we will compare what we have found for the general UK dataset with what we can find in the Scottish news dataset. Hint: Copy and paste the code we used so far below and adapt it to do the same steps in the Scottish Dataset 

# To start:
# Load the Scotland data
SC_data <- read_csv("Day1/WebScraping/outputs/ScotlandNews.csv")
#Drop the first column that we do not need
SC_data<-SC_data[, 2:4]

#examine the data 
summary(SC_data)

#Look at the text of our articles
head(SC_data$texts)

# Clean up the formatting annotations:

SC_data_clean <- mutate_if(SC_data, #change if is character so titles and texts
                           is.character, 
                           str_replace_all, 
                           pattern = "\r?\n|\r", #What I am searching
                           replacement = " ")#What I am replacing with

# Which will insert only one space regardless of whether the text contains \r\n, \n or \r.
# We can use the same trick to standardise references to Scotland (including "Scottish") to "Scotland". Spoiler alert there are a lot of these two words repeating 

SC_data_clean <- mutate_if(SC_data_clean,
                           is.character, 
                           str_replace_all, 
                           pattern = "[Ss]cottish", #searches for upper and lowercase to account for typos
                           replacement = "Scotland")#replace matches with "Scotland"



# Let's check the cleaned output:
head(SC_data_clean$texts)

#create a quanteda corpus of the 'article text' column from our data set:
article_text_SC<-corpus(SC_data_clean, text_field='texts')

#Wrap-up activity: comparisons & table discussion
#1. Follow the steps from the first lesson to analyse the Scotland data. When you are finished, compare the world clouds and the top-keys results between the Scotland and UK datasets.
#Discuss your findings with your table. 

#2. Looking at top_keys with your table along with the word clouds we've made so far (hint: you can scroll through the plots using the arrows in the top left corner of the window),
#what can keywords show us about a corpus? What do they not show us?

#3. Can we answer our research questions with the data we have? If not, what is still unknown? What information might we need to gather?

#4.Discuss the pros and cons of the text mining methods we've covered so far.
#bonus points for coming up with a potential use case in the context of your research!

# Export our data for Friday visualisation ##########
write_csv(uk_data_clean, "Day5/data/TextDataVis.csv")
