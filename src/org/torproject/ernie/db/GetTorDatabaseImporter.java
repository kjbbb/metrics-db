/* Copyright 2010 The Tor Project
 * See LICENSE for licensing information */
package org.torproject.ernie.db;

import java.sql.*;
import java.util.*;
import java.util.logging.*;
import java.text.*;
import java.util.Date;
import java.sql.Timestamp;

/**
 * Inserts Torperf data into the database.
 */
public final class GetTorDatabaseImporter {

  /**
   * Database connection.
   */
  private Connection conn;

  /**
    * Prepared Statement to insert GetTor stats.
    */
  private PreparedStatement psGtstats;

  /**
   * Prepared Statement to find the minimum current date known.
   */
  private PreparedStatement psMaxdate;

  /**
   * Logger for this class.
   */
  private Logger logger;

  public GetTorDatabaseImporter(String connectionURL) {
    this.logger = Logger.getLogger(
        GetTorDatabaseImporter.class.getName());
    try {
      this.conn = DriverManager.getConnection(connectionURL);
      this.psGtstats = conn.prepareStatement("INSERT INTO gettor_stats "
          + "(date, bundle, count) VALUES (?, ?, ?)");
      this.psMaxdate = conn.prepareStatement("SELECT MAX(DATE(time)) " +
          "as maxdate FROM gettor_stats");
    } catch (SQLException e)  {
      this.logger.log(Level.WARNING, "Could not connect to database or " +
          "prepare statements.", e);
    }
  }

  /**
   * Add Torperf statistics to database.
   */
  public void addGetTorStats(SortedSet<String> columns,
      SortedMap<String, Map<String, Integer>> data) {
    try {
      SimpleDateFormat df = new SimpleDateFormat();
      df.applyPattern("yyyy-MM-dd");

      ResultSet rs = psMaxdate.executeQuery();
      Date maxDate = (rs.next() && rs.getDate("maxdate") != null) ?
          rs.getDate("maxdate") : new Date(0L);

      for (String date : data.keySet()) {
        /* Make timestamp compatable with postgres format */
        Date curDate = df.parse(date);

        /* Add any new GetTor data */
        if (curDate.after(maxDate))  {
          for (String column : columns) {
            psGtstats.clearParameters();
            psGtstats.setDate(1, new java.sql.Date(curDate.getTime()));
            psGtstats.setString(2, column);
            psGtstats.setInt(3, data.get(date).get(column));
            psGtstats.execute();
          }
        }
      }
    } catch (SQLException e) {
      this.logger.log(Level.WARNING, "Failed to insert GetTor data." + e,
          e);
    } catch (ParseException e)  {
      this.logger.log(Level.WARNING, "Failed to insert GetTor data." + e,
          e);
    }
  }

/**
 * Close the database connection.
 */
  public void closeConnection() {
    try {
      this.conn.close();
    } catch (SQLException e)  {
      this.logger.log(Level.WARNING, "Could not close database "
          + "connection.", e);
    }
  }
}
