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




