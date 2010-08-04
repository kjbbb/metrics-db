/* Copyright 2010 The Tor Project
 * See LICENSE for licensing information */
package org.torproject.ernie.db;

import java.util.*;
import java.util.logging.*;

/**
 * Coordinate downloading and parsing of descriptors and extraction of
 * statistically relevant data for later processing with R.
 */
public class Main {
  public static void main(String[] args) {

    /* Initialize logging configuration. */
    new LoggingConfiguration();

    Logger logger = Logger.getLogger(Main.class.getName());
    logger.info("Starting ERNIE.");

    // Initialize configuration
    Configuration config = new Configuration();

    // Use lock file to avoid overlapping runs
    LockFile lf = new LockFile();
    if (!lf.acquireLock()) {
      logger.severe("Warning: ERNIE is already running or has not exited "
          + "cleanly! Exiting!");
      System.exit(1);
    }

    // Define which stats we are interested in
    SortedSet<String> countries = config.getDirreqBridgeCountries();
    SortedSet<String> directories = config.getDirreqDirectories();

    // Prepare writing relay descriptors to database
    RelayDescriptorDatabaseImporter rddi =
        config.getWriteRelayDescriptorDatabase() ?
        new RelayDescriptorDatabaseImporter(
        config.getRelayDescriptorDatabaseJDBC()) : null;

    // Prepare writing bridge descriptors to database
    BridgeDescriptorDatabaseImporter bddi =
        config.getWriteBridgeDescriptorDatabase() ?
        new BridgeDescriptorDatabaseImporter(
        config.getRelayDescriptorDatabaseJDBC()) : null;

    // Prepare writing torperf statistics to database
    TorperfDatabaseImporter tpdi =
        config.getWriteTorperfDatabase() ?
        new TorperfDatabaseImporter(
        config.getRelayDescriptorDatabaseJDBC()) : null;

    // Prepare stats file handlers (only if we are writing stats)
    ConsensusStatsFileHandler csfh = config.getWriteConsensusStats() ?
        new ConsensusStatsFileHandler() : null;
    BridgeStatsFileHandler bsfh = config.getWriteBridgeStats() ?
        new BridgeStatsFileHandler(countries, bddi) : null;
    DirreqStatsFileHandler dsfh = config.getWriteDirreqStats() ?
        new DirreqStatsFileHandler(countries) : null;
    ServerDescriptorStatsFileHandler sdsfh =
        config.getWriteServerDescriptorStats() ?
        new ServerDescriptorStatsFileHandler(config.getRelayVersions(),
        config.getRelayPlatforms()) : null;

    // Prepare consensus health checker
    ConsensusHealthChecker chc = config.getWriteConsensusHealth() ?
        new ConsensusHealthChecker() : null;

    // Prepare writing relay descriptor archive to disk
    ArchiveWriter aw = config.getWriteDirectoryArchives() ?
        new ArchiveWriter(config.getDirectoryArchivesOutputDirectory())
        : null;

    // Prepare relay descriptor parser (only if we are writing stats or
    // directory archives to disk)
    RelayDescriptorParser rdp = config.getWriteConsensusStats() ||
        config.getWriteBridgeStats() || config.getWriteDirreqStats() ||
        config.getWriteServerDescriptorStats() ||
        config.getWriteDirectoryArchives() ||
        config.getWriteRelayDescriptorDatabase() ||
        config.getWriteConsensusHealth() ?
        new RelayDescriptorParser(csfh, bsfh, dsfh, sdsfh, aw, rddi, chc,
            countries, directories) : null;

    // Import/download relay descriptors from the various sources
    if (rdp != null) {
      RelayDescriptorDownloader rdd = null;
      if (config.getDownloadRelayDescriptors()) {
        List<String> dirSources =
            config.getDownloadFromDirectoryAuthorities();
        boolean downloadCurrentConsensus = aw != null || csfh != null ||
            bsfh != null || sdsfh != null || rddi != null || chc != null;
        boolean downloadCurrentVotes = aw != null || chc != null;
        boolean downloadAllServerDescriptors = aw != null ||
            sdsfh != null || rddi != null;
        boolean downloadAllExtraInfos = aw != null;
        Set<String> downloadDescriptorsForRelays = bsfh != null ||
            dsfh != null ? directories : new HashSet<String>();
        rdd = new RelayDescriptorDownloader(rdp, dirSources,
            downloadCurrentConsensus, downloadCurrentVotes,
            downloadAllServerDescriptors, downloadAllExtraInfos,
            downloadDescriptorsForRelays);
        rdp.setRelayDescriptorDownloader(rdd);
      }
      if (config.getImportCachedRelayDescriptors()) {
        new CachedRelayDescriptorReader(rdp,
            config.getCachedRelayDescriptorDirectory());
        if (aw != null) {
          aw.intermediateStats("importing relay descriptors from local "
              + "Tor data directories");
        }
      }
      if (config.getImportDirectoryArchives()) {
        new ArchiveReader(rdp, config.getDirectoryArchivesDirectory(),
            config.getKeepDirectoryArchiveImportHistory());
        if (aw != null) {
          aw.intermediateStats("importing relay descriptors from local "
              + "directory");
        }
      }
      if (rdd != null) {
        rdd.downloadMissingDescriptors();
        rdd.writeFile();
        rdd = null;
        if (aw != null) {
          aw.intermediateStats("downloading relay descriptors from the "
              + "directory authorities");
        }
      }
    }

    // Close database connection (if active)
    if (rddi != null)   {
      rddi.closeConnection();
    }

    // Write output to disk that only depends on relay descriptors
    if (chc != null) {
      chc.writeStatusWebsite();
      chc = null;
    }
    if (aw != null) {
      aw.dumpStats();
      aw = null;
    }
    if (dsfh != null) {
      dsfh.writeFile();
      dsfh = null;
    }
    if (sdsfh != null) {
      sdsfh.writeFiles();
      sdsfh = null;
    }

    // Prepare sanitized bridge descriptor writer
    SanitizedBridgesWriter sbw = config.getWriteSanitizedBridges() ?
        new SanitizedBridgesWriter(
        config.getSanitizedBridgesWriteDirectory()) : null;

    // Prepare bridge descriptor parser
    BridgeDescriptorParser bdp = config.getWriteConsensusStats() ||
        config.getWriteBridgeStats() || config.getWriteSanitizedBridges()
        ? new BridgeDescriptorParser(csfh, bsfh, sbw, countries) : null;

    // Import bridge descriptors
    if (bdp != null && config.getImportSanitizedBridges()) {
      new SanitizedBridgesReader(bdp,
          config.getSanitizedBridgesDirectory(), countries,
          config.getKeepSanitizedBridgesImportHistory());
    }
    if (bdp != null && config.getImportBridgeSnapshots()) {
      new BridgeSnapshotReader(bdp, config.getBridgeSnapshotsDirectory(),
          countries);
    }

    // Finish writing sanitized bridge descriptors to disk
    if (sbw != null) {
      sbw.finishWriting();
      sbw = null;
    }

    // Write updated stats files to disk
    if (bsfh != null) {
      bsfh.writeFiles();
      bsfh = null;
    }
    if (csfh != null) {
      csfh.writeFiles();
      csfh = null;
    }

    if (bddi != null) {
      bddi.closeConnection();
    }

    // Import and process torperf stats
    if (config.getImportWriteTorperfStats()) {
      new TorperfProcessor(config.getTorperfDirectory(), tpdi);
    }

    // Download and process GetTor stats
    if (config.getDownloadProcessGetTorStats()) {
      new GetTorProcessor(config.getGetTorStatsUrl());
    }

    // Download exit list and store it to disk
    if (config.getDownloadExitList()) {
      new ExitListDownloader();
    }

    // Remove lock file
    lf.releaseLock();

    logger.info("Terminating ERNIE.");
  }
}
