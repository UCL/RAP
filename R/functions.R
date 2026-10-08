#-------------------------------------------------------------------------------------------------------
clean.to.list <- function(x, exclude){

        # basic cleaning
        x <- paste(x,collapse=',')
        x <- gsub(';',',',x)
        x <- gsub('\r','',x,fixed=T)
        x <- gsub('\n','',x,fixed=T)
        x <- gsub(' ,',',',x,fixed=T)
        x <- gsub(', ',',',x,fixed=T)
        x <- gsub('.','',x,fixed=T)
        x <- gsub('"','',x,fixed=T)
        x <- gsub(' ',' ',x,fixed=T)
        x <- gsub('(','',x,fixed=T)
        x <- gsub(')','',x,fixed=T)
        x <- gsub('</sup>','',x,fixed=T)
        x <- gsub('<sup>','',x,fixed=T)
        x <- gsub('-',' ',x,fixed=T)
        x <- gsub(':',' ',x,fixed=T)
        x <- gsub('&',' ',x,fixed=T)
        x <- gsub(' ',',',x,fixed=T)
        x <- strsplit(x,split=',')[[1]]
        x <- x[x!='']
        x <- x[!x%in%exclude]
        # add a single word to avoid processing an empty vector,which will be excluded later
        x <- c('a',x)
return(x)}
#-------------------------------------------------------------------------------------------------------
extract.words <- function(discovery, iris, exclude, ud_model){

        if(is.null(discovery))return(NA)

        # Get keywords
        d1 <- tolower(discovery$abstract)
        d2 <- tolower(discovery$title)
        d3 <- tolower(discovery$keywords)
        d4 <- tolower(iris)

        # Process the sources separately, so their importance can be weighted.
        df1 <- as.data.frame(udpipe_annotate(ud_model, x = clean.to.list(d1,exclude)))
        df2 <- as.data.frame(udpipe_annotate(ud_model, x = clean.to.list(d2,exclude)))
        df3 <- as.data.frame(udpipe_annotate(ud_model, x = clean.to.list(d3,exclude)))
        df4 <- as.data.frame(udpipe_annotate(ud_model, x = clean.to.list(d4,exclude)))

        words1 <- subset(df1, upos %in% c('NOUN','ADJ'))$token
        words2 <- subset(df2, upos %in% c('NOUN','ADJ','VERB'))$token
        words3 <- subset(df3, upos %in% c('NOUN','ADJ','VERB'))$token
        words4 <- subset(df4, upos %in% c('NOUN','ADJ','VERB'))$token

        # weight words
        words1 <- rep(words1,1) # abstracts are far too detailed
        words2 <- rep(words2,3) # publication titles are a little too detailed
        words3 <- rep(words3,6) # publication keywords are better, but still a little specific
        words4 <- rep(words4,15) # iris keywords summarise a reasearcher best
        words <- c(words1,words2,words3,words4)

        # clean
        words <- stri_trim_both(words, pattern = "\\p{L}")

        # remove anything shorter than 3 characters
        words <- words[nchar(words)>3]

        # truncate
        freq <- txt_freq(words)
        if(nrow(freq)>400)freq <- freq[1:400,]

        # singularise
        W <- nrow(freq)
        single <- character(W)
        for(w in 1:W)single[w] <- singularize(freq$key[w])

	  # correct any peculiarities	
        freq$single <- corrector(single)

        # combine the counts of singular and plurals
        keep <- unique(single)
        K <- length(keep)
        counts <- numeric(K)
        for(k in 1:K)counts[k] <- sum(subset(freq,single==keep[k])$freq)

        x <- data.frame(word=keep,freq=counts)
        x <- x[order(x$freq,decreasing=T),]

        # finally truncate to words that occur more than once, to a max of 350 words
        x <- subset(x,freq>1)
        if(nrow(x)>350)x <- x[1:350,]
        
        x$word <- as.character(x$word)

return(x)}
#-------------------------------------------------------------------------------------------------------
get.all.UPIs <- function(folder){

        files <- list.files(folder, full.names=T)
        UPIs <- c()
        for(file in files){
                UPIs <- c(UPIs, readLines(file))
                }
return(UPIs)}
#-------------------------------------------------------------------------------------------------------
get.discovery.summary <- function(urls){

        names <- c(     'eprintid','rev_number','userid',
                        'title','ispublished',
                        'divisions','keywords','abstract',
                        'official_url','lyricists_name',
                        'lyricists_id')

        id <- paste('eprints',names,sep='.')

        # just keep the links to the pages
        i <- lengths(regmatches(urls, gregexpr("/", urls)))==6
        urls <- urls[i]
        urls <- unique(urls)
        urls <- urls[!is.na(urls)]
        urls <- urls[urls!='']

        # extract required data
        U <- length(urls)
        N <- length(id)
        if(U==0)return(NULL) 	
        data <- data.frame(matrix(,U,N)); names(data) <- names
        for(u in 1:U){
                url <- urls[u]
                page <- reader(url)
                if(is.na(page)){
                        data[u,] <- NA
                        print('page could not be read')
			next
                        }

                if(!is.na(page)){
                        name <- page%>% html_nodes("meta")  %>% html_attr( "name")
                        name[is.na(name)] <- 'crap'
                        content <- page%>% html_nodes("meta")  %>% html_attr( "content")
                        for(n in 1:N){
                                i <- name==id[n]
                                data[u,n] <- paste(content[i],collapse='/')
                                }
                        }
                }
return(data)}
#-------------------------------------------------------------------------------------------------------
get.discovery.urls.for.department <- function(dept){
        
        # find which years are available for the department
        x <- paste('https://discovery.ucl.ac.uk/view/UCL/',dept,sep='')
        print(paste('pulling data for',dept,'.......'))
        top.page <- reader(x)
        if(is.na(top.page))return(NA)
        page.links <- top.page%>% html_nodes("a") %>% html_attr( "href")
        i.1 <- grep(glob2rx('19*.html'),page.links)
        i.2 <- grep(glob2rx('20*.html'),page.links)
        i.3 <- grep(glob2rx('21*.html'),page.links)
        page.links <- page.links[c(i.1,i.2,i.3)]
        years <- length(page.links)
        all.links <- c()
        if(years>0){
        for(y in 1:years){
                
                # get the summary page for a whole year for department
                x <- paste('https://discovery.ucl.ac.uk/view/UCL/',dept,'/',page.links[y],sep='')
                page <- reader(x)
                if(is.na(page)){
                        print(paste(page,'page could not be read'))
			next
                        }

                # extract all links
                links <- page%>% html_nodes("a") %>% html_attr( "href")
                all.links <- c(all.links, links)
                }
        }
        # extract only the links to discovery papers
        i <- grepl("https://discovery.ucl.ac.uk/id/eprint/", all.links)
        urls <- all.links[i]
        urls <- urls[!is.na(urls)]
return(urls)}
#-------------------------------------------------------------------------------------------------------
get.discovery.urls.for.upi <- function(upi){

        # summary page for UPI
        x <- paste('https://discovery.ucl.ac.uk/view/people/',upi,'.html',sep='')
        page <- reader(x)
        if(is.na(page)){
                print(paste(page,'page could not be read'))
		return(NA)
                }

        # extract all links
        all.links <- page%>% html_nodes("a") %>% html_attr( "href")

        # extract only the links to discovery papers
        i <- grepl("https://discovery.ucl.ac.uk/id/eprint/", all.links)
        urls <- all.links[i]
        urls <- urls[!is.na(urls)]
return(urls)}
#-------------------------------------------------------------------------------------------------------
get.exclusions <- function(upi=NA,folder='../tools/exclusions'){

        # general exclusions for everyone
        exc <- readLines(paste(folder,'/everyone.txt',sep=''))
        file <- paste(folder,'/individuals/',upi,'.txt',sep='')
        if(file.exists(file))exc <- c(exc,readLines(file))

return(exc)}
#-------------------------------------------------------------------------------------------------------
get.iris.summary <- function(upi){

        url.1 <- paste('https://iris.ucl.ac.uk/iris/browse/profile?upi',upi,sep='=')
        url.2 <- paste('https://iris.ucl.ac.uk/iris/browse/profile/researchActivities?upi',upi,sep='=')
        page.1 <- reader(url.1)
        page.2 <- reader(url.2)
        if(is.na(page.1)|is.na(page.2)){
                print(paste(page.1,'or',page.2,'page could not be read'))
		return(NA)
                }

        links <- page.1%>% html_nodes("a") %>% html_attr( "href")
        text <- page.1%>% html_nodes("a") %>% html_text()

        # anything with 'researchTheme' on it
        i <- grep('researchTheme',links)
        text.1 <- text[i]
        text.2 <- page.2%>% html_nodes("a") %>% html_text()
        text <- c(text.1,text.2)
        text <- text[text!='Themes']
return(text)}
#-------------------------------------------------------------------------------------------------------
reader <- function(url){
        page <- NA
        gc()
        if(!url.exists(url)){
                print(paste(url,'non-existant'))
                return(NA)
                }
        page <- read_html(url)	
return(page)}
#-------------------------------------------------------------------------------------------------------
wordcloud.maker <- function(freq, col, png.file){

	# Choosing the size argument for wordcloud2 is critical and tricky.
	# ad hoc approach below is a start, but doesnt always solve the problem.
	# Also the algorithm used by wordcloud2 for positioning the words doesnt always result in an attractive layout.
	# Wordcloud2 by default generates a different layout each time (random positioning),
	# therefore we also loop for several attempts, with various size changes, until constraints are satisfied.
	# rough relative widths of lowercase letters, taken from https://gist.github.com/imaurer/d330e68e70180c985b380f25e195b90c

	error <- FALSE
	if(class(freq)!='data.frame')error <- TRUE

	if(!error){
		# adjust the frequency of words by their physical length, as the largest words (given their frequency AND size) should be centred first	
		w <- c(60,60,52,60,60,30,60,60,25,25,52,25,87,60,60,60,60,35,52,30,60,52,77,52,52,52)
		rw <- w/mean(w)
		words <- strsplit(freq$word,split='')
		N <- length(words)
		rw.words <- numeric(N)
		for(n in 1:N){
			word <- words[[n]]
			letter.position <- match(word,letters[])
			letter.rw <- rw[letter.position]
			letter.rw[is.na(letter.rw)] <- 1
			rw.words[n] <- sum(letter.rw)
			}
		freq$freq <- round(rw.words*freq$freq*100)
		weighted.word.length <- sum(rw.words*freq$freq)/sum(freq$freq)
		size <- 12/weighted.word.length 

		# various constants and starting conditions
		html.file <- 'tmp.html'	
		width <- 2200
		height <- round(width/1.5)	
		generate <- TRUE
		attempt.number <- 0

		# output sanity checks 
		print(paste('number of words =',nrow(freq)))

		# loop to allow regeneration if aesthetic constraints of png arent met	
		while(generate){

			attempt.number <- attempt.number + 1
			print(paste('attempt number',attempt.number))

			# generate wordcloud as a html widget
			size <- round(size,3)
			wc <- wordcloud2(freq, size=size, color = col, minRotation = 0, maxRotation = pi/2,widgetsize=c(width,height))
			saveWidget(wc,html.file,selfcontained = F)

			# extract as a png webshot. Allow more time to get the webshot if there is a lot of words
			delay <- round(N*0.08)+5
			webshot(html.file,png.file, delay =delay, vwidth = width, vheight=height) 
			Sys.sleep(2)

			# remove intermediate temp files
			file.remove(html.file)
      		unlink('tmp_files', recursive=TRUE)
			print('webshot complete')

			# crop white borders with imagemagick
			print('cropping...')
			system(paste('magick convert ',png.file,' +repage -gravity South -chop 0x20 -trim ',png.file,sep=''))

			# check some details of the webshot, and decide if to regenerate
			png <- readPNG(png.file)
			png.height <- dim(png)[1]
			png.width <- dim(png)[2]
			png.ratio <- png.width/png.height
			if(png.width>(width*0.6) & png.width<(width*0.9) & png.ratio<1.75 & png.ratio>1.25) generate <- FALSE
			if(png.width<=(width*0.6)){
				print(paste(size,'is too small, trying again'))
				size <- size * 1.5	
				}
			if(png.width>=(width*0.9)){
				print(paste(size,'is too big, trying again'))
				size <- size * 0.8
				}	
			if(png.ratio>1.75 | png.ratio<1.25) print('ratio poor, trying again')	
			if(attempt.number==10){
				generate <- FALSE
				error <- TRUE
				}
			}
		}

	if(!error){
		# resize with imagemagick
		print('resizing...')  
 		system(paste('magick convert ',png.file,' +repage -resize 900x900 ',png.file,sep=''))
  
  
		# compress png
		print('optipng compression...')
		system(paste('optipng -quiet',png.file))
		}

	}
#-------------------------------------------------------------------------------------------------------
correction.tidy <- function(file='../tools/corrections/corrections.csv'){
	d <- read.csv(file)
	sorted <- d[order(d$from),]
	write.csv(sorted,file=file, row.names=FALSE)
	} 
#-------------------------------------------------------------------------------------------------------
corrector <- function(x,file='../tools/corrections/corrections.csv'){
	d <- read.csv(file)
	for(n in 1:nrow(d))x[x==d$from[n]]<- d$to[n]
return(x)}
#-------------------------------------------------------------------------------------------------------	

#-------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------
