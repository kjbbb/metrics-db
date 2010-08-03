##Pre-loaded libraries and graphing functions to speed things up

library("RPostgreSQL")
library("DBI")
library("ggplot2")
library("proto")
library("grid")
library("reshape")
library("plyr")
library("digest")

db = "tordir"
dbuser = "ernie"
dbpassword= ""

plot_networksize_line <- function(start, end, path) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)
  q <- paste("select * from network_size where date >= '",start,"' and date <= '",end,"'")
  rs <- dbSendQuery(con, q)
  networksize <- fetch(rs,n=-1)
  networksize <- melt(networksize, id="date")
  ggplot(networksize, aes(x = as.Date(date, "%Y-%m-%d"), y = value,
    colour = variable)) + geom_line(size=1) +
    scale_x_date(name="") +
    scale_y_continuous(name="") +
    scale_colour_hue("",breaks=c("avg_running","avg_exit","avg_guard"),
        labels=c("Total","Exit","Guard"))
  ggsave(filename=path, width=8, height=5, dpi=72)
  dbDisconnect(con)
  dbUnloadDriver(drv)
}
plot_versions_line <- function(start, end, path) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)
  q <- paste("select * from relay_versions where date >= '",start,"' and date <= '",end,"'")
  rs <- dbSendQuery(con, q)
  v <- fetch(rs,n=-1)
  v <- melt(v, id="date")
  ggplot(v, aes(x=as.Date(date, "%Y-%m-%d"), y = value, colour=variable)) +
    geom_line(size=1) +
    scale_x_date(name = "") +
    scale_y_continuous(name= "",
      limits = c(0, max(v$value, na.rm = TRUE))) +
    scale_colour_brewer(name = "Tor version")
  ggsave(filename=path, width=8,height=5,dpi=72)
  dbDisconnect(con)
  dbUnloadDriver(drv)
}
plot_platforms_line <- function(start, end, path) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)
  q <- paste("select * from relay_platforms where date >= '",start,"' and date <= '",end,"'")
  rs <- dbSendQuery(con, q)
  p <- fetch(rs,n=-1)
  p <- melt(p, id="date")
  ggplot(p, aes(x=date, y=value, colour=variable)) +
    geom_line(size=1) +
    scale_x_date(name="") +
    scale_y_continuous(name="",
      limits=c(0,max(p$value, na.rm=TRUE))) +
    scale_colour_brewer(name="Platforms",
      breaks=c("avg_linux", "avg_darwin", "avg_bsd", "avg_windows", "avg_other"),
      labels=c("Linux", "Darwin", "FreeBSD", "Windows", "Other"))
  ggsave(filename=path,width=8,height=5,dpi=72)
  dbDisconnect(con)
  dbUnloadDriver(drv)
}
plot_bandwidth_line <- function(start, end, path) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)
  q <- paste("select bwavg, date from total_bandwidth where date >= '",start,"' and date <= '",end,"'")
  rs <- dbSendQuery(con, q)
  bandwidth <- fetch(rs,n=-1)
  bandwidth <- melt(bandwidth, id="date")
  bandwidth$value <- bandwidth$value / 1024 / 1024 / 8
  ggplot(bandwidth, aes(x = as.Date(date, "%Y-%m-%d"), y = value)) + geom_line(size=1) +
    scale_x_date(name="") +
    scale_y_continuous(name="Bandwidth (MiB/s)")
  ggsave(filename = path, width = 8, height = 5, dpi = 72)
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

#this function accepts a two letter country code, like "cn"
plot_bridge_users_line <- function(start, end, path, country)  {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)
  q <- paste("select ",country,", date(validafter) as date from bridge_stats ",
             "where validafter>='",start,"' and validafter <= '",end,"'")
  rs <- dbSendQuery(con, q)
  bu <- fetch(rs,n=-1)
  bu <- melt(bu, id="date")
  ggplot(bu, aes(x = as.Date(date, "%Y-%m-%d"), y = value)) +
    geom_line() +
    scale_x_date(name="") +
    scale_y_continuous(name="Bridge Users")
  ggsave(filename = path, width = 8, height = 5, dpi = 72)
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

plot_torperf_line <- function (start, end, path, source, size) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword)

  colors <- c("#0000EE", "#EE0000", "#00CD00")
  if (source=="moria") {
    color <- colors[1]
  } else if (source =="siv")  {
    color <- colors[2]
  } else if (source =="torperf")  {
   color <- colors[3]
  } else {
    color <- colors[1]
  }

  q <- paste("select date(time) as date, q1, md, q3 from torperf_stats ",
             "where source like '%",source,"%' and size like '%",size,"%' ",
             "and time >= '",start,"' and time <= '",end,"'",
              sep="", collapse="")
  rs <- dbSendQuery(con, q)
  tp <- fetch(rs, n=-1)

  ggplot(tp, aes(x=as.Date(date), y=md)) +
    scale_x_date(name="") +
    scale_y_continuous(name="", limits=c(0, max(tp$md))) +
    geom_line(size=.75, colour=color) +
    geom_ribbon(data=tp, aes(x=date, ymin=q1, ymax=q3, fill="ribbon")) +
    coord_cartesian(ylim = c(0, 0.8*max(tp$md))) +
    scale_fill_manual(name=source,
        breaks=c("line", "ribbon"),
        labels=c("Median", "1st to 3rd quartile"),
        values=paste(color,"66",sep="",collapse="")) +
    opts(title=paste("Time in seconds to complete",size,"request"))
  ggsave(filename="./torperf.png", width=8, height=5, dpi=72)
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

# bundle argument accepts the ending string of the bundle,
# e.g. "zh_cn", "en", "es", etc. Usually a country code.

plot_gettor_line <- function (start, end, path, bundle)  {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  if (bundle == "all")  { bundle = "" }

  q = paste("select date(time) as date, sum(count) as sum ",
      "from gettor_stats where bundle like '%",bundle,"' ",
      "and time >= '",start,"' and time <= '",end,"' ",
      "group by date(time) order by date(time)", sep="",collapse="")

  rs <- dbSendQuery(con, q)
  gt<- fetch(rs, n=-1)

  ggplot(data=gt, aes(x=as.Date(date, "%Y-%m-%d"), y=sum)) +
    geom_line() +
    scale_x_date(name="") +
    scale_y_continuous(name="")
  ggsave(filename=path, width=8, height=5, dpi=72)
}

plot_bandwidth_versions_boxplot <- function(start, end, path, limit=0) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste("select d.bandwidthavg/131072.0 as bandwidthavg, ",
    "    substring(d.platform, 5, 5) as version ",
    "from descriptor d ",
    "join statusentry s on d.descriptor=s.descriptor ",
    "where bandwidthavg is not null ",
    "and s.validafter >= '",start,"' ",
    "and s.validafter <= '",end,"' ", sep="")

  rs <- dbSendQuery(con, q)
  bandwidth <- fetch(rs,n=-1)

  limit = ifelse(limit==0, max(bandwidth$bandwidthavg), limit)

  ggplot(bandwidth, aes(y=bandwidthavg, x=version, fill=version)) +
    geom_boxplot(outlier.size=1) +
    scale_y_continuous(name="Bandwidth (Mbit/s)", limits=c(0, limit)) +
    scale_x_discrete(name="Version") +
    opts(title="Bandwidth per version")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

plot_bandwidth_platforms_boxplot <- function(start, end, path, limit=0)  {

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste("select d.bandwidthavg/131072.0 as bandwidthavg, ",
    "    (case when platform like '%Windows%' then 'Windows' ",
    "     when platform like '%Linux%' then 'Linux' ",
    "     when platform like '%FreeBSD%' then 'FreeBSD' ",
    "     when platform like '%Darwin%' then 'Darwin' else 'Other' end) as platform ",
    "from descriptor d ",
    "join statusentry s on d.descriptor=s.descriptor ",
    "where bandwidthavg is not null ",
    "   and s.validafter >= '",start,"'",
    "   and s.validafter <= '",end,"'", sep="")

  rs <- dbSendQuery(con, q)
  bandwidth <- fetch(rs,n=-1)

  limit = ifelse(limit==0, max(bandwidth$bandwidthavg), limit)

  ggplot(bandwidth, aes(y=bandwidthavg, x=platform, fill=platform)) +
    geom_boxplot(outlier.size=1) +
    scale_y_continuous(name="Bandwidth (Mbit/s)", limits=c(0, limit)) +
    scale_x_discrete(name="Platform") +
    opts(title="Bandwidth per platform")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

plot_exit_uptime_boxplot <- function(start, end, path, limit=0) {

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste("select ((d.uptime + ",
  "    (extract('epoch' from s.validafter) - ",
  "    extract('epoch' from d.published)))/86400)::INTEGER as uptime, ",
  "    ((case when isexit=true then 't' else 'f' end) || ",
  "    (case when isguard=true then 't' else 'f' end)) as guardexit ",
  "from descriptor d ",
  "join statusentry s on d.descriptor=s.descriptor ",
  "where uptime is not null ",
  "    and s.validafter >= '",start,"' ",
  "    and s.validafter <= '",end,"' ", sep="")

  rs <- dbSendQuery(con, q)
  exituptime <- fetch(rs,n=-1)

  limit = ifelse(limit==0, max(exituptime$uptime), limit)

  ggplot(exituptime, aes(y=uptime, x=guardexit, fill=guardexit)) +
    geom_boxplot(outlier.size=1) +
    scale_y_continuous(name="Uptime (days)", limits=c(0, limit)) +
    scale_x_discrete(name="Guard/Exit flags") +
    scale_colour_brewer(name="Guard/exit flags",
        breaks=c("ff", "tf", "tt", "ft"),
        labels=c("f,f", "t,f", "t,t", "f,t"))
    opts(title="Guard, exit, and relay uptime")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

plot_version_uptime_boxplot <- function(start, end, path, limit=0) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste("select ((d.uptime + ",
    "    (extract('epoch' from s.validafter) - ",
    "    extract('epoch' from d.published))) / 86400)::INTEGER as uptime, ",
    "    substring(platform, 5, 5) as version ",
    "from descriptor d ",
    "join statusentry s on d.descriptor=s.descriptor ",
    "where uptime is not null ",
    "    and s.validafter >= '",start,"' ",
    "    and s.validafter <= '",end,"' ", sep="")

  rs <- dbSendQuery(con, q)
  versionuptime <- fetch(rs,n=-1)

  limit = ifelse(limit==0, max(versionuptime$uptime), limit)

  ggplot(versionuptime, aes(y=uptime, x=version, fill=version)) +
    geom_boxplot(outlier.size=1) +
    scale_y_continuous(name="Uptime (days)", limits=c(0, limit)) +
    scale_x_discrete(name="Version") +
    opts(title="Version uptime")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

plot_platform_uptime_boxplot <- function(start, end, path, limit=0)  {

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste("select ((d.uptime + ",
    "    (extract('epoch' from s.validafter) - ",
    "    extract('epoch' from d.published)))/86400)::INTEGER as uptime, ",
    "    (case when platform like '%Windows%' then 'Windows' ",
    "        when platform like '%Linux%' then 'Linux' ",
    "        when platform like '%FreeBSD%' then 'FreeBSD' ",
    "        when platform like '%Darwin%' then 'Darwin' else 'other' end) as ",
    "        platform ",
    "from descriptor d ",
    "join statusentry s on d.descriptor=s.descriptor ",
    "where uptime is not null ",
    "   and s.validafter >= '",start,"' ",
    "   and s.validafter <= '",end,"' ", sep="")

  rs <- dbSendQuery(con, q)
  platformsuptime <- fetch(rs,n=-1)

  limit = ifelse(limit==0, max(platformsuptime$uptime), limit)

  ggplot(platformsuptime, aes(y=uptime, x=platform, fill=platform))  +
    geom_boxplot(outlier.size=1) +
    scale_y_continuous(name="Uptime (days)", limits=c(0, limit)) +
    scale_x_discrete(name="Platform") +
    opts(title="Platform uptime")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

plot_bandwidth_versions_bargraph <- function(start, end, path) {

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste("select sum(d.bandwidthavg) as bandwidthsum, ",
    "    substring(d.platform, 5, 5) as version ",
    "from descriptor d ",
    "join statusentry s on d.descriptor=s.descriptor ",
    "where d.bandwidth is not null ",
    "    and date(s.validafter) >= '",start,"' ",
    "    and date(s.validafter) <= '",end,"' ",
    "group by substring(d.platform, 5, 5)", sep="")

  rs <- dbSendQuery(con, q)
  bandwidth <- fetch(rs,n=-1)

  ggplot(bandwidth, aes(x="", y=bandwidthsum, fill=version)) +
    geom_bar(position="dodge") +
    scale_y_continuous(name="") +
    scale_x_discrete(name="Version") +
    scale_colour_brewer(name="Version") +
    opts(title="Bandwidth distribution per version")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}

plot_bandwidth_platforms_piechart <- function(start, end, path)  {

  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste (" select sum(d.bandwidthavg) as bandwidthsum, ",
    "      (case when platform like '%Windows%' then 'Windows' ",
    "      when platform like '%Linux%' then 'Linux' ",
    "      when platform like '%FreeBSD%' then 'FreeBSD' ",
    "      when platform like '%Darwin%' then 'Darwin' else 'other' end) as platform ",
    " from descriptor d ",
    " join statusentry s on d.descriptor=s.descriptor ",
    " where bandwidthavg is not null ",
    "     and date(s.validafter) >= '",start,"' ",
    "     and date(s.validafter) <= '",end,"' ",
    " group by (case when platform like '%Windows%' then 'Windows' ",
    "      when platform like '%Linux%' then 'Linux' ",
    "      when platform like '%FreeBSD%' then 'FreeBSD' ",
    "      when platform like '%Darwin%' then 'Darwin' else 'other' end)", sep="")

  rs <- dbSendQuery(con, q)
  bandwidth <- fetch(rs,n=-1)

  bandwidth$bandwidthsum = bandwidth$bandwidthsum / sum(bandwidth$bandwidthsum)
  pct_windows = round(bandwidth$bandwidthsum[bandwidth$platform=="Windows"]*100, 1)
  pct_linux = round(bandwidth$bandwidthsum[bandwidth$platform=="Linux"]*100, 1)
  pct_freebsd = round(bandwidth$bandwidthsum[bandwidth$platform=="FreeBSD"]*100, 1)
  pct_darwin = round(bandwidth$bandwidthsum[bandwidth$platform=="Darwin"]*100, 1)
  pct_other = round(bandwidth$bandwidthsum[bandwidth$platform=="other"]*100, 1)

  ggplot(bandwidth, aes(x="", y=bandwidthsum, fill=platform)) +
    geom_bar() +
    scale_y_continuous(name="", labels=NULL, breaks=NULL) +
    scale_x_discrete(name="", labels=NULL, breaks=NULL) +
    scale_fill_brewer(name="Platform",
        breaks=c("Windows","Linux","FreeBSD","Darwin","other"),
        labels=c(paste("Windows - ",pct_windows,"%",sep=""),
            paste("Linux - ",pct_linux,"%",sep=""),
            paste("FreeBSD - ",pct_freebsd,"%",sep=""),
            paste("Darwin - ",pct_darwin,"%",sep=""),
            paste("other - ",pct_other,"%",sep=""))) +
    coord_polar("y") +
    opts(title="Bandwidth distribution per platform")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)

}

plot_bandwidth_guardexit_piechart <- function(start, end, path) {
  drv <- dbDriver("PostgreSQL")
  con <- dbConnect(drv, user=dbuser, password=dbpassword, dbname=db)

  q <- paste("select sum(d.bandwidthavg) as bandwidthsum, ",
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
  bandwidth <- fetch(rs,n=-1)

  ggplot(bandwidth, aes(x="", y=bandwidthsum, fill=guardexit)) +
    geom_bar() +
    scale_y_continuous(name="") +
    scale_x_discrete(name="") +
    scale_colour_brewer(name="Guard/exit flags") +
    coord_polar("y") +
    opts(title="Bandwidth distribution per guard/exit/relay flags")

  ggsave(filename=path, width=8, height=5, dpi=72)

  #Close database connection
  dbDisconnect(con)
  dbUnloadDriver(drv)
}
