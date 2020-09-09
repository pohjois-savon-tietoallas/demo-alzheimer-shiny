FROM rocker/shiny-verse

## install debian packages
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    libxml2-dev \
    libcairo2-dev \
    libpq-dev \
    libssh2-1-dev \
    unixodbc-dev \
    libcurl4-openssl-dev \
    libssl-dev

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean

## Install packages needed for running the app
RUN R -e "install.packages(c('rmarkdown', 'tidyverse', 'wordcloud', 'wordcloud2', 'mlogit',  'survival',  'Hmisc', 'RColorBrewer', 'flexdashboard', 'plotly', 'shinydashboard', 'DT', 'survival', 'survminer', 'dplyr'))"

## Copy app to image
COPY /demo-alzheimer-shiny/ /srv/shiny-server/demo-alzheimer-shiny

## Expose port
#EXPOSE 3838

## RUN SHINY APP
CMD ["R", "-e", "rmarkdown::run('/srv/shiny-server/demo-alzheimer-shiny/shinyapp.Rmd', shiny_args = list(host = '0.0.0.0', port = 3838))"]
