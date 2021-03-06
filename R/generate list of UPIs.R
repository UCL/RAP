#---------------------------------------------------------------------------------------------
# Generate a list of all UPIs with more than some minimum number of publications on discovery
# stores the list in /UPI/everyone.txt
#-------------------------------------------------------------------------------------------
# overheads
#-------------------------------------------------------------------------------------------
source('boilerplate.R')
#-------------------------------------------------------------------------------------------
min <- 5

page <- read_html('https://discovery.ucl.ac.uk/view/people/')
x <-  page %>% html_node("table") %>% html_table()
x <- paste(x,collapse='')
x <- strsplit(x,split="[() ]+")[[1]]
df <- as.data.frame(t(matrix(x,2,length(x)/2))); names(df) <- c('upi','counts')
df[,2] <- as.numeric(df[,2])
df <- subset(df,counts>=min)
x <- as.character(df$upi)
writeLines(x,'../tools/UPI/everyone.txt')
#-------------------------------------------------------------------------------------------



