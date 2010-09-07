/* Copyright 2010 The Tor Project
 * See LICENSE for licensing information */
package org.torproject.ernie.db;

import java.io.*;
import java.net.*;
import java.util.*;
import java.util.logging.*;

/**
 * Initialize configuration with hard-coded defaults, overwrite with
 * configuration in config file, if exists, and answer Main.java about our
 * configuration.
 */
public class Configuration {
  private boolean writeConsensusStats = false;
  private boolean writeDirreqStats = false;
  private SortedSet<String> dirreqBridgeCountries = new TreeSet<String>(
      Arrays.asList(("au,bh,br,ca,cn,cu,de,et,fr,gb,ir,it,jp,kr,mm,pl,ru,"
          + "sa,se,sy,tn,tm,us,uz,vn,ye").split(",")));
  private SortedSet<String> dirreqDirectories = new TreeSet<String>(
      Arrays.asList(("8522EB98C91496E80EC238E732594D1509158E77,"
      + "9695DFC35FFEB861329B9F1AB04C46397020CE31").split(",")));
  private boolean writeBridgeStats = false;
  private boolean writeServerDescriptorStats = false;
  private List<String> relayVersions = new ArrayList<String>(
      Arrays.asList("0.1.2,0.2.0,0.2.1,0.2.2".split(",")));
  private List<String> relayPlatforms = new ArrayList<String>(
      Arrays.asList("Linux,Windows,Darwin,FreeBSD".split(",")));
  private boolean writeDirectoryArchives = false;
  private String directoryArchivesOutputDirectory = "directory-archive/";
  private boolean importCachedRelayDescriptors = false;
  //this.cachedRelayDescriptorDirectory.add
  private List<String> cachedRelayDescriptorsDirectory =
      new ArrayList<String>(Arrays.asList("cacheddesc/".split(",")));
  private boolean importDirectoryArchives = false;
  private String directoryArchivesDirectory = "archives/";
  private boolean keepDirectoryArchiveImportHistory = false;
  private boolean writeRelayDescriptorDatabase = false;
  private boolean writeBridgeDescriptorDatabase = false;
  private String relayDescriptorDatabaseJdbc =
      "jdbc:postgresql://localhost/tordir?user=ernie&password=password";
  private boolean writeSanitizedBridges = false;
  private String sanitizedBridgesWriteDirectory = "sanitized-bridges/";
  private boolean importSanitizedBridges = false;
  private String sanitizedBridgesDirectory = "bridges/";
  private boolean keepSanitizedBridgesImportHistory = false;
  private boolean importBridgeSnapshots = false;
  private String bridgeSnapshotsDirectory = "bridge-directories/";
  private boolean importWriteTorperfStats = false;
  private String torperfDirectory = "torperf/";
  private boolean writeTorperfDatabase = false;
  private boolean downloadRelayDescriptors = false;
  private List<String> downloadFromDirectoryAuthorities = Arrays.asList(
      "86.59.21.38,194.109.206.212,80.190.246.100:8180".split(","));
  private boolean downloadProcessGetTorStats = false;
  private String getTorStatsUrl = "http://gettor.torproject.org:8080/"
      + "~gettor/gettor_stats.txt";
  private boolean writeGetTorDatabase = false;
  private boolean downloadExitList = false;
  private boolean importGeoIPDatabases = false;
  private String geoIPDatabasesDirectory = "geoipdb/";
  private boolean downloadGeoIPDatabase = false;
  private String maxmindLicenseKey = "";
  private boolean writeConsensusHealth = false;
  public Configuration() {

    /* Initialize logger. */
    Logger logger = Logger.getLogger(Configuration.class.getName());

    /* Read config file, if present. */
    File configFile = new File("config");
    if (!configFile.exists()) {
      logger.warning("Could not find config file. In the default "
          + "configuration, we are not configured to read data from any "
          + "data source or write data to any data sink. You need to "
          + "create a config file (" + configFile.getAbsolutePath()
          + ") and provide at least one data source and one data sink. "
          + "Refer to the manual for more information.");
      return;
    }
    String line = null;
    boolean containsCachedRelayDescriptorsDirectory = false;
    try {
      BufferedReader br = new BufferedReader(new FileReader(configFile));
      while ((line = br.readLine()) != null) {
        if (line.startsWith("#") || line.length() < 1) {
          continue;
        } else if (line.startsWith("WriteConsensusStats")) {
          this.writeConsensusStats = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("WriteDirreqStats")) {
          this.writeDirreqStats = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("DirreqBridgeCountries")) {
          this.dirreqBridgeCountries = new TreeSet<String>();
          for (String country : line.split(" ")[1].split(",")) {
            if (country.length() != 2) {
              logger.severe("Configuration file contains illegal country "
                  + "code in line '" + line + "'! Exiting!");
              System.exit(1);
            }
            this.dirreqBridgeCountries.add(country);
          }
        } else if (line.startsWith("DirreqDirectories")) {
          this.dirreqDirectories = new TreeSet<String>(
              Arrays.asList(line.split(" ")[1].split(",")));
        } else if (line.startsWith("WriteBridgeStats")) {
          this.writeBridgeStats = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("WriteServerDescriptorStats")) {
          this.writeServerDescriptorStats = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("RelayVersions")) {
          this.relayVersions = new ArrayList<String>(
              Arrays.asList(line.split(" ")[1].split(",")));
        } else if (line.startsWith("RelayPlatforms")) {
          this.relayPlatforms = new ArrayList<String>(
              Arrays.asList(line.split(" ")[1].split(",")));
        } else if (line.startsWith("WriteDirectoryArchives")) {
          this.writeDirectoryArchives = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("DirectoryArchivesOutputDirectory")) {
          this.directoryArchivesOutputDirectory = line.split(" ")[1];
        } else if (line.startsWith("ImportCachedRelayDescriptors")) {
          this.importCachedRelayDescriptors = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("CachedRelayDescriptorsDirectory")) {
          if (!containsCachedRelayDescriptorsDirectory) {
            this.cachedRelayDescriptorsDirectory.clear();
            containsCachedRelayDescriptorsDirectory = true;
          }
          this.cachedRelayDescriptorsDirectory.add(line.split(" ")[1]);
        } else if (line.startsWith("ImportDirectoryArchives")) {
          this.importDirectoryArchives = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("DirectoryArchivesDirectory")) {
          this.directoryArchivesDirectory = line.split(" ")[1];
        } else if (line.startsWith("KeepDirectoryArchiveImportHistory")) {
          this.keepDirectoryArchiveImportHistory = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("WriteRelayDescriptorDatabase")) {
          this.writeRelayDescriptorDatabase = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("WriteBridgeDescriptorDatabase")) {
          this.writeBridgeDescriptorDatabase = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("WriteTorperfDatabase")) {
          this.writeTorperfDatabase = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("WriteGetTorDatabase"))  {
          this.writeGetTorDatabase = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("RelayDescriptorDatabaseJDBC")) {
          this.relayDescriptorDatabaseJdbc = line.split(" ")[1];
        } else if (line.startsWith("WriteSanitizedBridges")) {
          this.writeSanitizedBridges = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("SanitizedBridgesWriteDirectory")) {
          this.sanitizedBridgesWriteDirectory = line.split(" ")[1];
        } else if (line.startsWith("ImportSanitizedBridges")) {
          this.importSanitizedBridges = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("SanitizedBridgesDirectory")) {
          this.sanitizedBridgesDirectory = line.split(" ")[1];
        } else if (line.startsWith("KeepSanitizedBridgesImportHistory")) {
          this.keepSanitizedBridgesImportHistory = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("ImportBridgeSnapshots")) {
          this.importBridgeSnapshots = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("BridgeSnapshotsDirectory")) {
          this.bridgeSnapshotsDirectory = line.split(" ")[1];
        } else if (line.startsWith("ImportWriteTorperfStats")) {
          this.importWriteTorperfStats = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("TorperfDirectory")) {
          this.torperfDirectory = line.split(" ")[1];
        } else if (line.startsWith("DownloadRelayDescriptors")) {
          this.downloadRelayDescriptors = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("DownloadFromDirectoryAuthorities")) {
          this.downloadFromDirectoryAuthorities = new ArrayList<String>();
          for (String dir : line.split(" ")[1].split(",")) {
            // test if IP:port pair has correct format
            if (dir.length() < 1) {
              logger.severe("Configuration file contains directory "
                  + "authority IP:port of length 0 in line '" + line
                  + "'! Exiting!");
              System.exit(1);
            }
            new URL("http://" + dir + "/");
            this.downloadFromDirectoryAuthorities.add(dir);
          }
        } else if (line.startsWith("DownloadProcessGetTorStats")) {
          this.downloadProcessGetTorStats = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("GetTorStatsURL")) {
          String newUrl = line.split(" ")[1];
          /* Test if URL has correct format. */
          new URL(newUrl);
          this.getTorStatsUrl = newUrl;
        } else if (line.startsWith("DownloadExitList")) {
          this.downloadExitList = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("ImportGeoIPDatabases")) {
          this.importGeoIPDatabases = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("GeoIPDatabasesDirectory")) {
          this.geoIPDatabasesDirectory = line.split(" ")[1];
        } else if (line.startsWith("DownloadGeoIPDatabase")) {
          this.downloadGeoIPDatabase = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else if (line.startsWith("MaxmindLicenseKey")) {
          this.maxmindLicenseKey = line.split(" ")[1];
        } else if (line.startsWith("WriteConsensusHealth")) {
          this.writeConsensusHealth = Integer.parseInt(
              line.split(" ")[1]) != 0;
        } else {
          logger.severe("Configuration file contains unrecognized "
              + "configuration key in line '" + line + "'! Exiting!");
          System.exit(1);
        }
      }
      br.close();
    } catch (ArrayIndexOutOfBoundsException e) {
      logger.severe("Configuration file contains configuration key "
          + "without value in line '" + line + "'. Exiting!");
      System.exit(1);
    } catch (MalformedURLException e) {
      logger.severe("Configuration file contains illegal URL or IP:port "
          + "pair in line '" + line + "'. Exiting!");
      System.exit(1);
    } catch (NumberFormatException e) {
      logger.severe("Configuration file contains illegal value in line '"
          + line + "' with legal values being 0 or 1. Exiting!");
      System.exit(1);
    } catch (IOException e) {
      logger.log(Level.SEVERE, "Unknown problem while reading config "
          + "file! Exiting!", e);
      System.exit(1);
    }

    /** Make some checks if configuration is valid. */
    if (!this.importCachedRelayDescriptors &&
        !this.importDirectoryArchives && !this.downloadRelayDescriptors &&
        !this.importSanitizedBridges && !this.importBridgeSnapshots &&
        !this.importWriteTorperfStats &&
        !this.downloadProcessGetTorStats && !this.downloadExitList &&
        !this.writeDirectoryArchives &&
        !this.writeRelayDescriptorDatabase &&
        !this.writeBridgeDescriptorDatabase &&
        !this.writeTorperfDatabase &&
        !this.writeGetTorDatabase &&
        !this.writeSanitizedBridges && !this.writeConsensusStats &&
        !this.writeDirreqStats && !this.writeBridgeStats &&
        !this.writeServerDescriptorStats && !this.writeConsensusHealth) {
      logger.warning("We have not been configured to read data from any "
          + "data source or write data to any data sink. You need to "
          + "edit your config file (" + configFile.getAbsolutePath()
          + ") and provide at least one data source and one data sink. "
          + "Refer to the manual for more information.");
    }
    if ((this.importCachedRelayDescriptors ||
        this.importDirectoryArchives || this.downloadRelayDescriptors) &&
        !(this.writeDirectoryArchives ||
        this.writeRelayDescriptorDatabase || this.writeConsensusStats ||
        this.writeDirreqStats || this.writeBridgeStats ||
        this.writeServerDescriptorStats || this.writeConsensusHealth)) {
      logger.warning("We are configured to import/download relay "
          + "descriptors, but we don't have a single data sink to write "
          + "relay descriptors to.");
    }
    if (!(this.importCachedRelayDescriptors ||
        this.importDirectoryArchives || this.downloadRelayDescriptors) &&
        (this.writeDirectoryArchives ||
        this.writeRelayDescriptorDatabase || this.writeDirreqStats ||
        this.writeServerDescriptorStats)) {
      logger.warning("We are configured to write relay descriptor to at "
          + "least one data sink, but we don't have a single data source "
          + "containing relay descriptors.");
    }
    if (!(this.importCachedRelayDescriptors ||
        this.importDirectoryArchives || this.downloadRelayDescriptors ||
        this.importSanitizedBridges || this.importBridgeSnapshots) &&
        (this.writeBridgeStats || this.writeConsensusStats)) {
      logger.warning("We are configured to write relay or bridge "
          + "descriptors to at least one data sink, but we have neither "
          + "data sources containing relay nor bridge descriptors.");
    }
    if ((this.importSanitizedBridges || this.importBridgeSnapshots) &&
        !(this.writeSanitizedBridges || this.writeConsensusStats ||
        this.writeBridgeStats || this.writeBridgeDescriptorDatabase)) {
      logger.warning("We are configured to import/download bridge "
          + "descriptors, but we don't have a single data sink to write "
          + "bridge descriptors to.");
    }
    if (!(this.importSanitizedBridges || this.importBridgeSnapshots) &&
        (this.writeSanitizedBridges)) {
      logger.warning("We are configured to write bridge descriptor to at "
          + "least one data sink, but we don't have a single data source "
          + "containing bridge descriptors.");
    }
  }
  public boolean getWriteConsensusStats() {
    return this.writeConsensusStats;
  }
  public boolean getWriteDirreqStats() {
    return this.writeDirreqStats;
  }
  public SortedSet<String> getDirreqBridgeCountries() {
    return this.dirreqBridgeCountries;
  }
  public SortedSet<String> getDirreqDirectories() {
    return this.dirreqDirectories;
  }
  public boolean getWriteBridgeStats() {
    return this.writeBridgeStats;
  }
  public boolean getWriteServerDescriptorStats() {
    return this.writeServerDescriptorStats;
  }
  public List<String> getRelayVersions() {
    return this.relayVersions;
  }
  public List<String> getRelayPlatforms() {
    return this.relayPlatforms;
  }
  public boolean getWriteDirectoryArchives() {
    return this.writeDirectoryArchives;
  }
  public String getDirectoryArchivesOutputDirectory() {
    return this.directoryArchivesOutputDirectory;
  }
  public boolean getImportCachedRelayDescriptors() {
    return this.importCachedRelayDescriptors;
  }
  public List<String> getCachedRelayDescriptorDirectory() {
    return this.cachedRelayDescriptorsDirectory;
  }
  public boolean getImportDirectoryArchives() {
    return this.importDirectoryArchives;
  }
  public String getDirectoryArchivesDirectory() {
    return this.directoryArchivesDirectory;
  }
  public boolean getKeepDirectoryArchiveImportHistory() {
    return this.keepDirectoryArchiveImportHistory;
  }
  public boolean getWriteRelayDescriptorDatabase() {
    return this.writeRelayDescriptorDatabase;
  }
  public boolean getWriteBridgeDescriptorDatabase() {
    return this.writeBridgeDescriptorDatabase;
  }
  public boolean getWriteTorperfDatabase() {
    return this.writeTorperfDatabase;
  }
  public boolean getWriteGetTorDatabase() {
    return this.writeGetTorDatabase;
  }
  public String getRelayDescriptorDatabaseJDBC() {
    return this.relayDescriptorDatabaseJdbc;
  }
  public boolean getWriteSanitizedBridges() {
    return this.writeSanitizedBridges;
  }
  public String getSanitizedBridgesWriteDirectory() {
    return this.sanitizedBridgesWriteDirectory;
  }
  public boolean getImportSanitizedBridges() {
    return this.importSanitizedBridges;
  }
  public String getSanitizedBridgesDirectory() {
    return this.sanitizedBridgesDirectory;
  }
  public boolean getKeepSanitizedBridgesImportHistory() {
    return this.keepSanitizedBridgesImportHistory;
  }
  public boolean getImportBridgeSnapshots() {
    return this.importBridgeSnapshots;
  }
  public String getBridgeSnapshotsDirectory() {
    return this.bridgeSnapshotsDirectory;
  }
  public boolean getImportWriteTorperfStats() {
    return this.importWriteTorperfStats;
  }
  public String getTorperfDirectory() {
    return this.torperfDirectory;
  }
  public boolean getDownloadRelayDescriptors() {
    return this.downloadRelayDescriptors;
  }
  public List<String> getDownloadFromDirectoryAuthorities() {
    return this.downloadFromDirectoryAuthorities;
  }
  public boolean getDownloadProcessGetTorStats() {
    return this.downloadProcessGetTorStats;
  }
  public String getGetTorStatsUrl() {
    return this.getTorStatsUrl;
  }
  public boolean getDownloadExitList() {
    return this.downloadExitList;
  }
  public boolean getImportGeoIPDatabases() {
    return this.importGeoIPDatabases;
  }
  public String getGeoIPDatabasesDirectory() {
    return this.geoIPDatabasesDirectory;
  }
  public boolean getDownloadGeoIPDatabase() {
    return this.downloadGeoIPDatabase;
  }
  public String getMaxmindLicenseKey() {
    return this.maxmindLicenseKey;
  }
  public boolean getWriteConsensusHealth() {
    return this.writeConsensusHealth;
  }
}

