library(tidyverse)

all <- readd(compare_all)

error <- map_chr(map(all, class), 1) == "try-error"
