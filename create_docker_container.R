# DOCKERIZE SHINY APPLICATION
# DO NOT JUST BLIND RUN THIS FILE! RUN LINE BY LINE AND KNOW WHAT YOU ARE DOING.

## Before creating docker image, make sure that you have file /datasets/alzdataset.RData. You can create this dataset with script create_datasets.R but you need to have access to load(file="/dbfs/mnt/demodata/norpen.RData", verbose=T)

## Also make sure that you have docker desktop and it's running. You should pull rocker/r-base and rocker/shiny-verse images from dockerhub. If you don't know how to do it, check guide here: http://janimiettinen.fi/post/docker/

if(FALSE){
  system("cp Dockerfile ../")
  current_workdir <- getwd()
  setwd(gsub("/demo-alzheimer-shiny", "", current_workdir))
  system("docker build -t shiny_app . ")
  # system("docker run --name shiny_container --rm -d -p 3838:3838 shiny_app") # run container
  # system("docker stop shiny_container") # stop container
  # system("docker save -o ~/demo-alzheimer-shiny.tar shiny_app") # save shiny app
  # system("rm ./Dockerfile")
  setwd(current_workdir)
  rm("current_workdir")
}