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
public final class TorperfDatabaseImporter {

  /**
   * Database connection.
   */
  private Connection conn;

  /**
    * Prepared Statement to insert Torperf data.
    */
  private PreparedStatement psTp;

  /**
   * Prepared Statement to find most recent date added.
   */
  private PreparedStatement psMaxdate;

  /**
   * Date object to hold the results from psMaxdate.
   */
  private Date maxDate;

  /**
   * Make timestamp compatible with postgres format.
   */
  private SimpleDateFormat df;

  /**
   * Logger for this class.
   */
  private Logger logger;

  public TorperfDatabaseImporter(String connectionURL) {
    this.logger = Logger.getLogger(
        BridgeDescriptorDatabaseImporter.class.getName());
    try {
      this.conn = DriverManager.getConnection(connectionURL);
      this.psTp = conn.prepareStatement("INSERT INTO torperf_stats " +
          "(source, time, q1, md, q3) VALUES (?, ?, ?, ?, ?)");
      this.psMaxdate = conn.prepareStatement("SELECT MAX(DATE(time)) " +
          "as maxdate FROM torperf_stats");

      ResultSet rs = psMaxdate.executeQuery();
      maxDate = (rs != null && rs.next() &&
          rs.getDate("maxdate") != null) ?
              rs.getDate("maxdate") : new Date(0L);

    } catch (SQLException e)  {
      this.logger.log(Level.WARNING, "Could not connect to database or " +
          "prepare statements.", e);
    }

    df = new SimpleDateFormat();
    df.applyPattern("yyyy-MM-dd");
  }

  /**
   * Add Torperf statistics to database.
   */
  public void addTorperfStats(String values) {
    try {
      String[] parts = values.split(",");
      Timestamp timestamp = new Timestamp(df.parse(parts[1]).getTime());

      /* Add new torperf data */
      if (timestamp.after(maxDate)) {
        psTp.clearParameters();
        psTp.setString(1, parts[0]);
        psTp.setTimestamp(2, timestamp);
        psTp.setInt(3, Integer.parseInt(parts[2]));
        psTp.setInt(4, Integer.parseInt(parts[3]));
        psTp.setInt(5, Integer.parseInt(parts[4]));
        psTp.execute();
      }

    } catch (SQLException e) {
      this.logger.log(Level.WARNING, "Failed to insert torperf data for" +
          " date: " + values.split(",")[1], e);
    } catch (ParseException e)  {
      this.logger.log(Level.WARNING, "Could not parse date " +
          values.split(",")[1], e);
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
