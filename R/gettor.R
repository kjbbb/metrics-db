if (file.exists("stats/gettor-stats")) {
  gettor <- read.csv("stats/gettor-stats", header = TRUE,
      stringsAsFactors = FALSE);
  start <- as.Date(min(gettor$date))
  end <- seq(from = Sys.Date(), length = 2, by = "-1 day")[2]
  total <- data.frame(date = gettor$date,
    packages = rowSums(gettor[2:length(gettor)]) - gettor$none)
  en <- data.frame(date = gettor$date,
    packages = gettor$tor.browser.bundle_en + gettor$tor.im.browser.bundle_en)
  zh_cn <- data.frame(date = gettor$date,
    packages = gettor$tor.browser.bundle_zh_cn +
    gettor$tor.im.browser.bundle_zh_cn)
  fa <- data.frame(date = gettor$date,
    packages = gettor$tor.browser.bundle_fa + gettor$tor.im.browser.bundle_fa)

  write.csv(data.frame(date = gettor$date,
    total = rowSums(gettor[2:length(gettor)]) - gettor$none,
    en = gettor$tor.browser.bundle_en + gettor$tor.im.browser.bundle_en,
    zh_cn = gettor$tor.browser.bundle_zh_cn +
      gettor$tor.im.browser.bundle_zh_cn,
    fa = gettor$tor.browser.bundle_fa + gettor$tor.im.browser.bundle_fa),
    "website/csv/gettor.csv", quote = FALSE, row.names = FALSE)
}

