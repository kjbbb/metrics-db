if (file.exists("stats/consensus-stats")) {
  consensuses <- read.csv("stats/consensus-stats", header = TRUE,
      stringsAsFactors = FALSE);
  consensuses <- consensuses[1:length(consensuses$date)-1,]
  write.csv(data.frame(date = consensuses$date,
    relays = consensuses$running, bridges = consensuses$brunning),
    "website/csv/networksize.csv", quote = FALSE, row.names = FALSE)
  write.csv(data.frame(date = consensuses$date,
    all = consensuses$running, exit = consensuses$exit),
    "website/csv/exit.csv", quote = FALSE, row.names = FALSE)
}

