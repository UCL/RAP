#---------------------------------------------------------------------------
# Generate one wordcloud for each department listed in the 'departments' folder
# Uses a combination of publication keywords and titles from Discovery
# Department codes listed in 'departments.txt' must be suffixes of:https://discovery.ucl.ac.uk/view/UCL/
# eg: 
# https://discovery.ucl.ac.uk/view/UCL/F99
# https://discovery.ucl.ac.uk/view/UCL/DF9
#-------------------------------------------------------------------------------------------
# overheads
#-------------------------------------------------------------------------------------------
source('boilerplate.R')
departments <- readLines('../tools/departments/departments.txt')
cloud.png <- list.files('../wordclouds/departments')
non.research <- readLines('../tools/departments/non.research.txt')

# many departments are administrative not research, so wont have a useful number of publications
departments <- departments[!departments%in%non.research]

# remove any departments that are no longer at UCL
clouds <- sub('.png','',cloud.png)
remove <- list.files('../wordclouds/departments', full.names=T)[!clouds%in%departments]
file.remove(remove)

# departments that haven't been done yet
departments.new <- departments[!departments %in% clouds]
print(paste(length(departments.new),'departments still to do'))

# 10 clouds that haven't been updated recently. Dont do them all.
N <- 10
i <- order(file.info(list.files('../wordclouds/departments', full.names=T))$mtime)
departments.old <- clouds[i[1:N]]

departments <- c(departments.new, departments.old)
if(length(departments)>N)departments <- sample(departments,size=N)
#-------------------------------------------------------------------------------------------
# main loop
#-------------------------------------------------------------------------------------------
count <- 0
N <- length(departments)
for(n in sample(1:N)){

	count <- count + 1
	dept <- urls <- discovery <- exclude <- freq <- NULL
	dept <- departments[n]
	
	print('----------------------------------------------------------')
	print(paste('Attempting',dept,count,'of',N))

	# get discovery URLs and process if 10 or more pubs
	urls <- try(get.discovery.urls.for.department(dept))
	if(length(urls)<10){
		print(paste(dept,'has less than 10 publications. Added to the exclusion list'))
		non.research <- c(non.research,dept)
		next
		}
	if(length(urls)>10000){
		print(paste(dept,'has more than 10,000 publications. Looks like a meta-department. Added to the exclusion list'))
		non.research <- c(non.research,dept)
		next
		}

	# get discovery keywords
	discovery <- try(get.discovery.summary(urls))

	# get exclusions
	exclude <- get.exclusions()

	# analyse frequencies of words 
	freq <- extract.words(discovery, iris=NULL, exclude, ud_model)
	if(nrow(freq)<20)freq <- NULL

	# generate word clouds and save
	png.file <- paste('../wordclouds/departments/',dept,'.png',sep='')
	wordcloud.maker(freq, col='steelblue', png.file=png.file)

	# housekeeping
	if(is.null(freq))print(paste(dept,'failed'))
	}

non.research <- sort(non.research)
write(non.research,file='../tools/departments/non.research.txt')

#-------------------------------------------------------------------------------------------
