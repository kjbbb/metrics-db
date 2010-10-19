if (file.exists("stats/bridge-stats")) {
  bridge <- read.csv("stats/bridge-stats", header = TRUE,
    stringsAsFactors = FALSE)
  bridge <- bridge[1:length(bridge$date)-1,]
  write.csv(bridge, "website/csv/bridge-users.csv", quote = FALSE,
    row.names = FALSE)
}

