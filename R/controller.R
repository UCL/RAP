#-------------------------------------------------------------------------------------------
# Single script to run all other required R scripts, so can be envoked automatically on server using CRON
#-------------------------------------------------------------------------------------------
source('boilerplate.R')
install_phantomjs(force = TRUE)

#ud_model <- udpipe_download_model(language = "english", model_dir='../tools/data')
#ud_model <- udpipe_load_model(ud_model$file_model)
ud_model <- udpipe_load_model('../tools/data/english-ewt-ud-2.5-191206.udpipe')
#-------------------------------------------------------------------------------------------
#correction.tidy()
Sys.time()
source('generate list of UPIs.R')
Sys.time()
source('generate wordcloud for each UPI.R')
Sys.time()
source('generate list of department codes.R')
Sys.time()
source('generate wordcloud for each department.R')
Sys.time()
#-------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------------



















