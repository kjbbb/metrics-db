/* Copyright 2010 The Tor Project
 * See LICENSE for licensing information */
package org.torproject.ernie.db;

import java.sql.*;
import java.util.*;
import java.util.logging.*;
import java.text.*;
import java.sql.Date;
import java.sql.Timestamp;

/**
 * Inserts bridge descriptor data into the database.
 */
public final class BridgeDescriptorDatabaseImporter {

  /**
   * Database connection.
   */
  private Connection conn;

  /**
   * Prepared Statement to insert descriptors and times into
   * bridge descriptors table.
   */
  private PreparedStatement psBd;

  /**
   * Prepared statement to find the most recently inserted
   * bridge data.
   */
  private PreparedStatement psMaxdate;

  /**
   * Date object from psMaxdate query.
   */
  private Date maxDate;

  /**
   * SimpleDateFormat formatter to be compatible with Postgres
   */
  private SimpleDateFormat df;

  /**
   * Logger for this class.
   */
  private Logger logger;

  public BridgeDescriptorDatabaseImporter(String connectionURL) {
    this.logger = Logger.getLogger(
        BridgeDescriptorDatabaseImporter.class.getName());
    try {
      this.conn = DriverManager.getConnection(connectionURL);
      this.psBd = conn.prepareStatement("INSERT INTO bridge_stats " +
          "(validafter, bh, cn, cu, et, ir, mm, sa, sy, tm, tn, " +
           "uz, vn, ye) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, " +
           "?)");
      this.psMaxdate = conn.prepareStatement("SELECT " +
          "MAX(DATE(validafter)) AS maxdate FROM bridge_stats");

      ResultSet rs = psMaxdate.executeQuery();
      maxDate = (rs.next() && rs.getDate("maxdate") != null) ?
          rs.getDate("maxdate") : new Date(0L);

      df = new SimpleDateFormat();
      df.applyPattern("yyyy-MM-dd");
    } catch (SQLException e)  {
      this.logger.log(Level.WARNING, "Could not connect to database or " +
          "prepare statements.", e);
    }
  }

  /**
   * Add bridge descriptor data to database.
   */
  public void addBridgeData(String date, double[] upd) {
    try {
      Timestamp timestamp = new Timestamp(df.parse(date).getTime());

      /* Add new bridge users data */
      if (timestamp.after(maxDate)) {
        psBd.clearParameters();
        psBd.setTimestamp(1, timestamp);
        psBd.setDouble(2, upd[0]);
        psBd.setDouble(3, upd[1]);
        psBd.setDouble(4, upd[2]);
        psBd.setDouble(5, upd[3]);
        psBd.setDouble(6, upd[4]);
        psBd.setDouble(7, upd[5]);
        psBd.setDouble(8, upd[6]);
        psBd.setDouble(9, upd[7]);
        psBd.setDouble(10, upd[8]);
        psBd.setDouble(11, upd[9]);
        psBd.setDouble(12, upd[10]);
        psBd.setDouble(13, upd[11]);
        psBd.setDouble(14, upd[12]);
        psBd.execute();
      }
    } catch (SQLException e) {
      this.logger.log(Level.WARNING, "Failed to insert bridge data for" +
          " date: " + date, e);
    } catch (ParseException e)  {
      this.logger.log(Level.WARNING, "Could not parse date " +
          date, e);
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
