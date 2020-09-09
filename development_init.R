# run.R

# Run these chunks in databricks RStudio cluster when you first clone and start the project. It will install packages, modify the dataset, add git credentials and run the program. All chunk are preset to FALSE, so check chunks before running them. 

## Clean environment setup ----
if(FALSE){
  ## install packages
  install.packages("rmarkdown")
  install.packages("tidyverse")
  install.packages("wordcloud")
  install.packages("wordcloud2")
  install.packages("mlogit") 
  install.packages("survival") 
  install.packages("Hmisc")
  install.packages("RColorBrewer")
  install.packages("flexdashboard")
  install.packages("plotly")
  install.packages("shinydashboard")
  install.packages("DT")
  install.packages("survival")
  install.packages("survminer")
  install.packages("dplyr")
  
  ## create datasets in /datasets/ folder
  source("create_datasets.R")
  
  ## set git credentials
  if(Sys.info()[["user"]] == "janimi@istekkiasiakas.fi") {
    system('git config --global user.email "jani.miettinen@uef.fi"')
    system('git config --global user.name "Jani Miettinen"')
  }
}

## Render documents ----
if(FALSE){
  if(!dir.exists("output")) dir.create("output")
  rmarkdown::render("report.Rmd", output_dir = "output/")
}

## Run ShinyApp -----
if(FALSE){
  rmarkdown::run("shinyapp.Rmd")
}


