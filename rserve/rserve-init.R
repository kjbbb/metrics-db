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

plot_networksize <- function(start, end, path) {
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
plot_versions <- function(start, end, path) {
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
plot_platforms <- function(start, end, path) {
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
plot_bandwidth <- function(start, end, path) {
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
plot_bridge_users <- function(country, start, end, path)  {
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

plot_torperf_stats <- function (source, size, start, end, path) {
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

plot_gettor_stats <- function (bundle, start, end, path)  {
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
