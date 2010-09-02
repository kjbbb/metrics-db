# Copyright 2010 The Tor Project
# See LICENSE for licensing information

plot_bandwidth_versions_bargraph <- function(start, end, path) {

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste("select sum(d.bandwidthavg) as bwsum, ",
    "    substring(d.platform, 5, 5) as version ",
    "from descriptor d ",
    "join statusentry s on d.descriptor=s.descriptor ",
    "where d.bandwidthavg is not null ",
    "    and date(s.validafter) >= '",start,"' ",
    "    and date(s.validafter) <= '",end,"' ",
    "group by substring(d.platform, 5, 5)", sep="")

  rs <- dbSendQuery(con, q)
  bw <- fetch(rs,n=-1)

  #Change the data frame into percentages, rounded to one decimal place.
  bw$bwsum <- round(bw$bwsum / sum(bw$bwsum) * 100, 1)

  #Group the platforms
  versions <- as.vector(unique(bw$version))

  #Specify the labels with the percentages concatenated to the end
  versions_pct = as.vector(length(versions))
  for (p in 1:length(versions)) {
    versions_pct[p] <- paste(versions[p],
        " (", bw$bwsum[bw$version == versions[p]],"%)", sep="")
  }

  ggplot(bw, aes(x="", y=bwsum, fill=version)) +
    geom_bar(position="dodge") +
    scale_y_continuous(name="") +
    scale_x_discrete(name="Version") +
    scale_fill_brewer(name="Version",
        breaks=versions,
        labels=versions_pct) +
    opts(title="Bandwidth distribution per version")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}
plot_bandwidth_platforms_bargraph <- function(start, end, path)  {

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste (" select sum(d.bandwidthavg) as bwsum, ",
    "      (case when platform like '%Windows%' then 'Windows' ",
    "      when platform like '%Linux%' then 'Linux' ",
    "      when platform like '%FreeBSD%' then 'FreeBSD' ",
    "      when platform like '%Darwin%' then 'Darwin' else 'Other' end) ",
    "          as platform ",
    " from descriptor d ",
    " join statusentry s on d.descriptor=s.descriptor ",
    " where bandwidthavg is not null ",
    "     and date(s.validafter) >= '",start,"' ",
    "     and date(s.validafter) <= '",end,"' ",
    " group by (case when platform like '%Windows%' then 'Windows' ",
    "      when platform like '%Linux%' then 'Linux' ",
    "      when platform like '%FreeBSD%' then 'FreeBSD' ",
    "      when platform like '%Darwin%' then 'Darwin' else 'Other' end)",
        sep="")

  rs <- dbSendQuery(con, q)
  bw <- fetch(rs,n=-1)

  #Change the data frame into percentages, rounded to one decimal place.
  bw$bwsum <- round(bw$bwsum / sum(bw$bwsum) * 100, 1)

  #Group the platforms
  platforms <- as.vector(unique(bw$platform))

  #Specify the labels with the percentages concatenated to the end
  platforms_pct = as.vector(length(platforms))
  for (p in 1:length(platforms)) {
    platforms_pct[p] <- paste(platforms[p],
        " (", bw$bwsum[bw$platform == platforms[p]],"%)", sep="")
  }

  ggplot(bw, aes(x="", y=bwsum, fill=platform)) +
    geom_bar(position="dodge") +
    scale_y_continuous(name="", labels=NULL, breaks=NULL) +
    scale_x_discrete(name="", labels=NULL, breaks=NULL) +
    scale_fill_brewer(name="Platform",
        breaks=platforms,
        labels=platforms_pct) +
    opts(title="Bandwidth distribution per platform")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

plot_bandwidth_guardexit_bargraph <- function(start, end, path) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste("select sum(d.bandwidthavg) as bwsum, ",
    "    (case when isexit=true then 't' else 'f' end) || ",
    "    (case when isguard=true then 't' else 'f' end) as guardexit ",
    "from descriptor d ",
    "join statusentry s on d.descriptor=s.descriptor ",
    "where d.bandwidthavg is not null ",
    "    and date(s.validafter) >= '",start,"' ",
    "    and date(s.validafter) <= '",end,"' ",
    "group by (case when isexit=true then 't' else 'f' end) || ",
    "    (case when isguard=true then 't' else 'f' end) ", sep="")

  rs <- dbSendQuery(con, q)
  bw <- fetch(rs,n=-1)

  #Change the data frame into percentages, rounded to one decimal place.
  bw$bwsum <- round(bw$bwsum / sum(bw$bwsum) * 100, 1)

  #Group the guard/exit flags
  guardexit <- c("tt", "tf", "ft", "ff")

  #Specify the labels with the percentages concatenated to the end
  guardexit_pct = as.vector(length(guardexit))
  for (p in 1:length(guardexit)) {
    guardexit_pct[p] <- paste(" (",
        bw$bwsum[bw$guardexit == guardexit[p]],"%)", sep="")
  }
  ggplot(bw, aes(x="", y=bwsum, fill=guardexit)) +
    geom_bar(position="dodge") +
    scale_y_continuous(name="") +
    scale_x_discrete(name="") +
    scale_fill_brewer(name="Guard/exit flags",
        breaks=c("tt", "tf", "ft", "ff"),
        labels=c(paste("Guard and Exit - ",guardexit_pct[1],sep=""),
            paste("Guard and no Exit - ",guardexit_pct[2],sep=""),
            paste("No Guard and Exit",guardexit_pct[3],sep=""),
            paste("No Guard and no Exit",guardexit_pct[4],sep=""))) +
    opts(title="Bandwidth distribution per guard and exit flags")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}
