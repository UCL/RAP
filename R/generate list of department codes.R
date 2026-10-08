#---------------------------------------------------------------------------------------------
# Generate a list of all department codes
# stores the list in /departments/departments.txt
#-------------------------------------------------------------------------------------------
# overheads
#-------------------------------------------------------------------------------------------
source('boilerplate.R')
#-------------------------------------------------------------------------------------------
x <- readLines('https://www.ucl.ac.uk/isd/comprep/orglist.php')
x <- x[-1]
x <- paste(x,collapse='|')
x <- strsplit(x,split='\\|')[[1]]
df <- as.data.frame(t(matrix(x,2,length(x)/2))); names(df) <- c('department','code')

# remove the overall aggregated UCL
df <- df[df$code!='UCL',]

# remove any depts that aren't on discovery
df$exists <- NA
for(n in 1:nrow(df))df$exists[n] <- url.exists(paste('https://discovery.ucl.ac.uk/view/UCL',df$code[n],sep='/'))
df <- subset(df, exists)

x <- as.character(df$code)
writeLines(x,'../tools/departments/departments.txt')
#-------------------------------------------------------------------------------------------





