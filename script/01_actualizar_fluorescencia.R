library(fs)
library(readr)
library(stringr)
library(lubridate)
library(tidyr)
library(dplyr)

data_fluo <- read_rds('data/data_processed/rds/data_fluorescencia.rds')

dates_fluo <- data_fluo |> 
  group_by(sitio) |> 
  distinct(fecha) 

files <- dir_ls('data/data_raw/fluorescencia',regexp = 'fluor_')
dates_new <- str_extract(files,'[0-9]{8}')

ind <- which(!(ymd(dates_new) %in% ymd(dates_fluo$fecha)))

sit <- str_remove_all(sapply(str_split(files[ind],'/'),function(x) x[4]),'fluor_|_[0-9]{8}.txt')

names_cols <- as.data.frame(read_csv('data/data_raw/fluorescencia/ubicacion_muestreo.csv'))

for (x in 1:length(ind)) {
  
  lineas <- readLines(files[ind][x])
  lineas <- lineas[6:length(lineas)]
  campos <- strsplit(lineas, "\t")
  datos <- list()
  names <- c()
  
  for (i in 2:length(lineas)) {
    datos[[i-1]] <- as.numeric(campos[[i]][2:length(campos[[i]])])
    names[i-1] <- campos[[i]][1]
  }
  
  data_new <- as.data.frame(setNames(datos, names))
  data_new[which(data_new$Mo %in% boxplot.stats(data_new$Mo)$out),1:ncol(data_new)] <- NA
  
  data_new <- data_new |> 
    mutate(sitio = sit[x],
           fecha = ymd(dates_new[ind])[x],
           codigo = names_cols[which(names_cols$sitio == sit[x]),2], 
           .before = Bckg) |>
    group_by(sitio, fecha, codigo) |> 
    summarise(across(Bckg:`DIo.RC`,.fns= mean,na.rm = TRUE))
  
  names(data_new) <- names(data_fluo)
  data_fluo <- rbind(data_fluo, data_new)
  
}

data_fluo <- data_fluo[order(data_fluo$fecha),]

write_rds(data_fluo,'data/data_processed/rds/data_fluorescencia.rds')
