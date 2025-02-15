library(magrittr)
library(tidyverse)

# TEXT DATA (SHAKESPEAR)---------------------------------------------------------------
# read and remove empty lines
romeo = readLines("http://www.gutenberg.org/cache/epub/1112/pg1112.txt", encoding = "UTF8")
romeo %<>% {.[. != ""]}

na_rem = function(x){
    return(x[!is.na(x)])
}

# split into header nad corpus
first_line = which(romeo[1:100] == "1595")
romeo = romeo[-1:-first_line]
header = romeo[4:28]
corpus = romeo[-1:-32]
rm(first_line, romeo)

# FIND THE LINES OF EVERY PERSON IN THE BOOK ----------------------------------

# define person names
persons = 
    header %>% 
    str_extract("[ [:alpha:]]+,") %>% 
    str_remove(",") %>%
    str_squish() %>% 
    na_rem()
persons

rm(header)

# try to find them in the text

corpus %>% 
    str_subset(paste(persons, collapse = "|")) %>% head(30)

corpus[20:30]

corpus_person =
    corpus %>% 
    str_extract("^\\s{2}[:alpha:]+\\.") %>%
    str_squish() %>% 
    str_remove("\\.") %>% 
    na_rem() %>% 
    unique()

corpus_person

rm(test_person)

connect_person = map(corpus_person, ~str_subset(persons, .x))
connect_person
names(connect_person) = corpus_person
connect_person %<>% unlist()
connect_person
rm(corpus_person)
rm(persons)

names(connect_person) %<>%
    str_remove("[0-9]+") 
connect_person

connect_person =
    names(connect_person) %>% 
    {.[duplicated(.)]} %>% 
    unique() %>% 
    {which(names(connect_person) %in% .)} %>% 
    {connect_person[multiply_by(.,-1)]}

connect_person

lines_person = 
    names(connect_person) %>% 
    map(~str_subset(corpus, paste0("^\\s{2}", .x)))

names(lines_person) = connect_person

lines_person

rm(na_rem, lines_person, connect_person, corpus)


# SALES DATA --------------------------------------------------------------------
# original at:
# https://toolbox.google.com/datasetsearch/search?query=sales&docid=5kapgBB5IYEGaNZVAAAAAA%3D%3D
# but I did some preprocessing


list.files("data")
zipped = unzip("data/liquor_sales.zip", list = TRUE)

liquor = read_csv(unz("data/liquor_sales.zip", zipped$Name),
                  col_types = paste0(rep("c", 24), collapse = "")) # safer way

summary(liquor)

head(liquor, 100) %>% View()

index = 
    colnames(liquor) %>% 
    str_detect("Item Description") %>% 
    which() 
char_names = colnames(liquor)[1:index]
num_names = colnames(liquor)[(index + 1):ncol(liquor)]

rm(index)

liquor %<>% 
    mutate_at(char_names, as.character)

to_num = function(x) {
    x %<>% 
        str_remove("\\s") %>% 
        str_remove("\\$") %>% 
        str_replace("\\,",".") %>% 
        as.numeric()
    return(x)
}

liquor %<>% 
    mutate_at(num_names, to_num)

rm(char_names, num_names, to_num)
 
liquor %>% head(100) %>% View()

map_chr(liquor, class)

liquor %<>% 
    mutate(Date = as.Date(Date, format = "%m/%d/%Y"))

summary(liquor)

# do the sales make sense?
liquor %>% 
    mutate(sales_test = `State Bottle Retail`*`Bottles Sold` - `Sale (Dollars)`) %>% 
    pull(sales_test) %>% 
    summary()

# lets check GPS
liquor %<>% 
    mutate(gps = str_extract(`Store Location`,
                             "[0-9]{2}\\.[0-9]{1,6}, \\-[0-9]{2}\\.[0-9]{1,6}"))

# where GPS wasn't extracted?
liquor %>% 
    pull(gps) %>% 
    is.na() %>% 
    filter(liquor, .) %>% 
    select(`Store Location`)

splitter = function(x) {
    if (is.na(x)) {
        txt = c(NA,NA)
    } else {
        txt = unlist(strsplit(x, split = ", "))
    }
    names(txt) = c("lat","lon")
    return(txt)
}

gps_loc =
    liquor %>% 
    pull(gps) %>% 
    map(splitter) %>% 
    do.call(rbind.data.frame,.)

colnames(gps_loc) = c("lat", "lon")


fac_to_char = function(x) {
    as.numeric(as.character(x)) %>% 
        return()
}

liquor =
    gps_loc %>% 
    cbind(liquor, .) %>% 
    select(-gps) %>% 
    mutate_at(c("lat", "lon"), .funs = fac_to_char)

liquor %>% head(100) %>% View(
    
)
