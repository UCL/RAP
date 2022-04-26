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
x <-  page %>% html_nodes("li") %>% html_text()
x <- x[nchar(x)%in%c(11,12,13)]
x <- paste(x,collapse='')
x <- strsplit(x,split="[() ]+")[[1]]
df <- as.data.frame(t(matrix(x,2,length(x)/2))); names(df) <- c('upi','counts')
df[,2] <- as.numeric(df[,2])
df <- subset(df,counts>=min)
x <- as.character(df$upi)
writeLines(x,'../tools/UPI/everyone.txt')

# remove any wordclouds that are no longer at UCL
clouds <- sub('.png','',list.files('../wordclouds/UPI'))
remove <- list.files('../wordclouds/UPI', full.names=T)[!clouds%in%x]
file.remove(remove)
#-------------------------------------------------------------------------------------------


