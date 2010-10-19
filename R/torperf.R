if (file.exists("stats/torperf-stats")) {
  t <- read.csv("stats/torperf-stats", colClasses = c("character", "Date",
    "integer", "integer", "integer"))
  write.csv(t, "website/csv/torperf.csv", quote = FALSE, row.names = FALSE)
}

