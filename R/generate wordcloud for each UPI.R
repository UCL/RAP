#---------------------------------------------------------------------------
# Generate one wordcloud for each UPI (individual researcher) listed in the UPI folder
# Uses a combination of publication keywords and titles, and if available, IRIS keywords
#-------------------------------------------------------------------------------------------
# overheads
#-------------------------------------------------------------------------------------------
source('boilerplate.R')
all.UPIs <- get.all.UPIs('../tools/UPI')
clouds <- sub('.png','',list.files('../wordclouds/UPI'))

# upis that haven't been done yet
UPIs.new <- all.UPIs[!all.UPIs %in% clouds]
print(paste(length(UPIs.new),'UPIs still to do'))

# 100 clouds that haven't been updated recently. Dont do them all.
N <- 100
i <- order(file.info(list.files('../wordclouds/UPI', full.names=T))$mtime)
UPIs.old <- clouds[i[1:N]]

UPIs <- c(UPIs.new, UPIs.old)
if(length(UPIs)>N)UPIs <- sample(UPIs,size=N)
#-------------------------------------------------------------------------------------------
# main loop
#-------------------------------------------------------------------------------------------
count <- 0
N <- length(UPIs)
for(n in sample(1:N)){

	count <- count + 1
	urls <- discovery <- iris <- exclude <- freq <- NULL
	upi <- UPIs[n]

	print('----------------------------------------------------------')
	print(paste('Attempting',upi,count,'of',N))
	
	# get discovery URLs
	urls <- try(get.discovery.urls.for.upi(upi))

	# get discovery keywords
	discovery <- try(get.discovery.summary(urls))

	# get IRIS keywords
	iris <- try(get.iris.summary(upi))

	# get exclusions
	exclude <- get.exclusions(upi)

	# analyse frequencies of words 
	freq <- extract.words(discovery, iris, exclude, ud_model)
	if(nrow(freq)<20)freq <- NULL

	# generate word clouds and save
	png.file <- paste('../wordclouds/UPI/',upi,'.png',sep='')
	wordcloud.maker(freq, col='steelblue', png.file=png.file)

	# housekeeping
	if(is.null(freq))print(paste(upi,'failed'))

	}

#-------------------------------------------------------------------------------------------
