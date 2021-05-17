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

        # singularise. Reversing some peculiarities
        W <- nrow(freq)
        single <- character(W)
        for(w in 1:W)single[w] <- singularize(freq$key[w])
        single[single=='specie'] <- 'species'
        single[single=='gammon'] <- 'gamma'
        freq$single <- single

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

        # extract required data
        U <- length(urls)
        N <- length(id)
        data <- data.frame(matrix(,U,N)); names(data) <- names
        for(u in 1:U){
                page <- NA
                gc()
                url <- urls[u]
                if(!url.exists(url)){
				print(paste(url,'non-existant'))
				next
				}

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
        print(paste('checking',dept,'.......'))
        if(url.exists(x))print('url exists')
        if(!url.exists(x)){
                print(paste(x,'url does not exist'))
                return(NA)
                }
        top.page <- reader(x)
        page.links <- top.page%>% html_nodes("a") %>% html_attr( "href")
        i.1 <- grep(glob2rx('20*.html'),page.links)
        i.2 <- grep(glob2rx('19*.html'),page.links)
        page.links <- page.links[c(i.1,i.2)]
        years <- length(page.links)
        all.links <- c()
        if(years>0){
        for(y in 1:years){
                
                # get the summary page for a whole year for department
                x <- paste('https://discovery.ucl.ac.uk/view/UCL/',dept,'/',page.links[y],sep='')
                page <- reader(x)

                # extract all links
                links <- page%>% html_nodes("a") %>% html_attr( "href")
                all.links <- c(all.links, links)
                }
        }
        # extract only the links to discovery papers
        i <- grepl("https://discovery.ucl.ac.uk/id/eprint/", all.links)
        urls <- all.links[i]
return(urls)}
#-------------------------------------------------------------------------------------------------------
get.discovery.urls.for.upi <- function(upi){

        # summary page for UPI
        x <- paste('https://discovery.ucl.ac.uk/view/people/',upi,'.html',sep='')
        page <- reader(x)

        # extract all links
        all.links <- page%>% html_nodes("a") %>% html_attr( "href")

        # extract only the links to discovery papers
        i <- grepl("https://discovery.ucl.ac.uk/id/eprint/", all.links)
        urls <- all.links[i]

return(urls)}
#-------------------------------------------------------------------------------------------------------
get.exclusions <- function(upi=NA){

        # general exclusions for everyone
        exc <- readLines('../exclusions/everyone.txt')
        file <- paste('../exclusions/individuals/',upi,'.txt',sep='')
        if(file.exists(file))exc <- c(exc,readLines(file))

return(exc)}
#-------------------------------------------------------------------------------------------------------
get.iris.summary <- function(upi){

        url.1 <- paste('https://iris.ucl.ac.uk/iris/browse/profile?upi',upi,sep='=')
        url.2 <- paste('https://iris.ucl.ac.uk/iris/browse/profile/researchActivities?upi',upi,sep='=')
        page.1 <- reader(url.1)
        page.2 <- reader(url.2)

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
        if(!url.exists(url))return(NA)

        # was causing encoding problems, eg the title of https://discovery.ucl.ac.uk/id/eprint/10083261/
        #download.file(url, destfile = "scrapedpage.html", quiet=TRUE)
        #page <- read_html('scrapedpage.html', addFinalizer=F)
        #file.remove('scrapedpage.html')      

        # instead try extraction directly		
        page <- read_html(url)	
return(page)}


#-------------------------------------------------------------------------------------------------------
wordcloud.maker <- function(freq, col, png.file){

	if(is.null(freq))return(NA)

	# ad hoc approach to deciding the character size
	# rough relative widths of lowercase letters, taken from https://gist.github.com/imaurer/d330e68e70180c985b380f25e195b90c
	w <- c(60,60,52,60,60,30,60,60,25,25,52,25,87,60,60,60,60,35,52,30,60,52,77,52,52,52)
	rw <- w/mean(w)
	words <- strsplit(freq$word,split='')
	N <- length(words)
	rw.words <- numeric(N)
	for(n in 1:N){
		word <- words[[n]]
		letter.position <- match(word,letters[])
		letter.rw <- rw[letter.position]
		rw.words[n] <- sum(letter.rw)
		}
	weighted.word.length <- sum(rw.words*freq$freq)/sum(freq$freq)
	size <- 8/weighted.word.length 

	width <- 1800; height <- 1200
	wc <- wordcloud2(freq, size=size, color = col, minRotation = 0, maxRotation = pi/2,widgetsize=c(width,height))
	html.file <- 'tmp.html'
	saveWidget(wc,html.file,selfcontained = F)	
 	webshot(html.file,png.file, delay =20, vwidth = width, vheight=height) 

	# imagemagick
	system(paste('magick convert ',png.file,' +repage -gravity South -chop 0x20 -trim ',png.file,sep=''))
	print('step 1 of imagemagick complete')
 	system(paste('magick convert ',png.file,' +repage -resize 600x600 ',png.file,sep=''))
 	print('step 2 of imagemagick complete')   
  
	# tidy
      file.remove(html.file)
      unlink('tmp_files', recursive=TRUE)

	# compress
	system(paste('optipng',png.file))
	}




#-------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------
