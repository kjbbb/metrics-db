if (file.exists("stats/dirreq-stats")) {
  dirreq <- read.csv("stats/dirreq-stats", header = TRUE,
    stringsAsFactors = FALSE)
  gabelmooSub <- subset(dirreq, directory %in%
    c("68333D0761BCF397A587A0C0B963E4A9E99EC4D3",
      "F2044413DAC2E02E3D6BCF4735A19BCA1DE97281"))
  gabelmoo <- data.frame(date = gabelmooSub$date,
    gabelmooSub[3:(length(gabelmooSub) - 1)] * 6)
  trustedSub <- dirreq[dirreq$directory ==
    "8522EB98C91496E80EC238E732594D1509158E77",]
  trustedSub[!is.na(trustedSub$share) & trustedSub$share < 0.01,
    3:length(trustedSub)] <- NA
  # Take out values when trusted saw less than 1 % of all requests
  trustedSub[!is.na(trustedSub$share) & trustedSub$share < 1,
             3:length(trustedSub)] <- NA
  trusted <- data.frame(date = trustedSub$date,
    floor(trustedSub[3:(length(trustedSub) - 1)] / trustedSub$share * 10))

  write.csv(gabelmoo, "website/csv/new-users.csv", quote = FALSE,
    row.names = FALSE)
  write.csv(trusted, "website/csv/direct-users.csv", quote = FALSE,
    row.names = FALSE)
}

