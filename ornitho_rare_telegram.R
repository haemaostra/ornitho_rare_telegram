rm(list=ls()) 

library(telegram.bot)
library(rvest)
library(xml2)

#### Building an R Bot in 3 steps ----
# 1. Creating the Updater object
updater <- Updater(token = Sys.getenv("RTELEGRAMBOT_TOKEN"))

bot <- updater[["bot"]]

# Get bot info
print(bot$getMe())

# Get updates
updates <- bot$getUpdates()

# Retrieve your chat id
# Note: you should text the bot before calling `getUpdates`
chat_id <- updates[[2L]]$from_chat_id()

#### scrap rare observation ----
#Address of the login webpage
login<-"https://www.ornitho.de/index.php?m_id=1182&sp_DOffset=7&sp_Cat%5Bnever%5D=1&sp_Cat%5Bveryrare%5D=1&sp_Cat%5Brare%5D=1&sp_FDisplay=SPECIES_PLACE_DATE"

#create a web session with the desired login address
pgsession<-html_session(login)
pgform<-html_form(pgsession)[[1]]  #in this case the submit is the 2nd form
filled_form<-set_values(pgform, USERNAME= Sys.getenv("ORNITHO_USER"), PASSWORD= Sys.getenv("ORNITHO_PW"))
submit_form(pgsession, filled_form)

#pre allocate the final results dataframe.
results<-data.frame()  

#loop through all of the pages with the desired info
#for (i in 1:5)
#{
  #base address of the pages to extract information from
  url<-"https://www.ornitho.de/index.php?m_id=1182&sp_DOffset=1&sp_Cat%5Bnever%5D=1&sp_Cat%5Bveryrare%5D=1&sp_Cat%5Brare%5D=1&sp_FDisplay=SPECIES_PLACE_DATE"
  #url<-paste0(url, i)
  page<-jump_to(pgsession, url)
#}

ornithoDErare <- read_html(page)
ornithoDErare
str(ornithoDErare)

txt_obs_old<-read.table("txt_obs_old.txt") # read previous observations

txt_obs_old<-as.character(txt_obs_old$x[1]) #previous observations as character

txt_obs <- ornithoDErare %>% 
  rvest::html_nodes('body') %>% 
  xml2::xml_find_all("//div[contains(@class, 'listTop')]") %>% 
  rvest::html_text()

txt_obs

# send rare observations to telegram
txt_obs <- toString(txt_obs)
txt_obs <- gsub(",", "\n", txt_obs)

#
if (txt_obs_old==txt_obs) {
  write.table(txt_obs,"txt_obs_old.txt") # write recent observations to previous observations
} else {
  bot$sendMessage(chat_id = chat_id, text = txt_obs, parse_mode = "Markdown")
  write.table(txt_obs,"txt_obs_old.txt") # write recent observations to previous observations
}
