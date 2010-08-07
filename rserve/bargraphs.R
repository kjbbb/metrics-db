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
