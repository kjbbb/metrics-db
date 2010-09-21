-- Copyright 2010 The Tor Project
-- See LICENSE for licensing information

-- TABLE descriptor
-- Contains all of the descriptors published by routers.
CREATE TABLE descriptor (
    descriptor CHARACTER(40) NOT NULL,
    nickname CHARACTER VARYING(19) NOT NULL,
    address CHARACTER VARYING(15) NOT NULL,
    orport INTEGER NOT NULL,
    dirport INTEGER NOT NULL,
    fingerprint CHARACTER(40) NOT NULL,
    bandwidthavg BIGINT NOT NULL,
    bandwidthburst BIGINT NOT NULL,
    bandwidthobserved BIGINT NOT NULL,
    platform CHARACTER VARYING(256),
    published TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    uptime BIGINT,
    extrainfo CHARACTER(40),
    rawdesc BYTEA NOT NULL,
    CONSTRAINT descriptor_pkey PRIMARY KEY (descriptor)
);

-- TABLE extrainfo
-- Contains all of the extra-info descriptors published by the routers.
CREATE TABLE extrainfo (
    extrainfo CHARACTER(40) NOT NULL,
    nickname CHARACTER VARYING(19) NOT NULL,
    fingerprint CHARACTER(40) NOT NULL,
    published TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    rawdesc BYTEA NOT NULL,
    CONSTRAINT extrainfo_pkey PRIMARY KEY (extrainfo)
);

-- TABLE statusentry
-- Contains all of the consensus entries published by the directories.
-- Each statusentry references a valid descriptor.
CREATE TABLE statusentry (
    validafter TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    nickname CHARACTER VARYING(19) NOT NULL,
    fingerprint CHARACTER(40) NOT NULL,
    descriptor CHARACTER(40) NOT NULL,
    published TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    address CHARACTER VARYING(15) NOT NULL,
    orport INTEGER NOT NULL,
    dirport INTEGER NOT NULL,
    isauthority BOOLEAN DEFAULT FALSE NOT NULL,
    isbadexit BOOLEAN DEFAULT FALSE NOT NULL,
    isbaddirectory BOOLEAN DEFAULT FALSE NOT NULL,
    isexit BOOLEAN DEFAULT FALSE NOT NULL,
    isfast BOOLEAN DEFAULT FALSE NOT NULL,
    isguard BOOLEAN DEFAULT FALSE NOT NULL,
    ishsdir BOOLEAN DEFAULT FALSE NOT NULL,
    isnamed BOOLEAN DEFAULT FALSE NOT NULL,
    isstable BOOLEAN DEFAULT FALSE NOT NULL,
    isrunning BOOLEAN DEFAULT FALSE NOT NULL,
    isunnamed BOOLEAN DEFAULT FALSE NOT NULL,
    isvalid BOOLEAN DEFAULT FALSE NOT NULL,
    isv2dir BOOLEAN DEFAULT FALSE NOT NULL,
    isv3dir BOOLEAN DEFAULT FALSE NOT NULL,
    version CHARACTER VARYING(50),
    bandwidth BIGINT,
    ports TEXT,
    rawdesc BYTEA NOT NULL,
    CONSTRAINT statusentry_pkey PRIMARY KEY (validafter, fingerprint)
);

-- TABLE consensus
-- Contains all of the consensuses published by the directories.
CREATE TABLE consensus (
    validafter TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    rawdesc BYTEA NOT NULL,
    CONSTRAINT consensus_pkey PRIMARY KEY (validafter)
);

-- TABLE vote
-- Contains all of the votes published by the directories
CREATE TABLE vote (
    validafter TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    dirsource CHARACTER(40) NOT NULL,
    rawdesc BYTEA NOT NULL,
    CONSTRAINT vote_pkey PRIMARY KEY (validafter, dirsource)
);

-- Create the various indexes we need for searching relays
CREATE INDEX statusentry_address ON statusentry (address);
CREATE INDEX statusentry_descriptor ON statusentry (descriptor);
CREATE INDEX statusentry_fingerprint ON statusentry (fingerprint);
CREATE INDEX statusentry_nickname_lower ON statusentry (LOWER(nickname));
CREATE INDEX statusentry_validafter ON statusentry (validafter);

-- And create an index that we use for precalculating statistics
CREATE INDEX statusentry_validafter_date ON statusentry (DATE(validafter));

-- TABLE network_size
-- TODO Instead of having a separate column for each flag we could add
-- two columns 'flag' and 'relays' to add more flags more easily.
CREATE TABLE network_size (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    avg_running INTEGER NOT NULL,
    avg_exit INTEGER NOT NULL,
    avg_guard INTEGER NOT NULL,
    avg_fast INTEGER NOT NULL,
    avg_stable INTEGER NOT NULL,
    CONSTRAINT network_size_pkey PRIMARY KEY(date)
);

-- TABLE relay_platforms
CREATE TABLE relay_platforms (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    avg_linux INTEGER NOT NULL,
    avg_darwin INTEGER NOT NULL,
    avg_bsd INTEGER NOT NULL,
    avg_windows INTEGER NOT NULL,
    avg_other INTEGER NOT NULL,
    CONSTRAINT relay_platforms_pkey PRIMARY KEY(date)
);

-- TABLE relay_versions
-- TODO It might be more flexible to use columns 'date', 'versions', and
-- 'relays'.
CREATE TABLE relay_versions (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    "0.1.0" INTEGER NOT NULL,
    "0.1.1" INTEGER NOT NULL,
    "0.1.2" INTEGER NOT NULL,
    "0.2.0" INTEGER NOT NULL,
    "0.2.1" INTEGER NOT NULL,
    "0.2.2" INTEGER NOT NULL,
    "0.2.3" INTEGER NOT NULL,
    CONSTRAINT relay_versions_pkey PRIMARY KEY(date)
);

-- TABLE total_bandwidth
-- Contains information for the whole network's total bandwidth which is
-- used in the bandwidth graphs.
-- TODO We should add bwadvertised as MIN(bwavg, bwobserved) which is used
-- by 0.2.0.x clients for path selection.
CREATE TABLE total_bandwidth (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    bwavg BIGINT NOT NULL,
    bwburst BIGINT NOT NULL,
    bwobserved BIGINT NOT NULL,
    CONSTRAINT total_bandwidth_pkey PRIMARY KEY(date)
);

-- TABLE relay_statuses_per_day
-- A helper table which is commonly used to update the tables above in the
-- refresh_* functions.
CREATE TABLE relay_statuses_per_day (
    date DATE NOT NULL,
    count INTEGER NOT NULL,
    CONSTRAINT relay_statuses_per_day_pkey PRIMARY KEY(date)
);

-- TABLE updates
-- A helper table which is used to keep track of what tables and where
-- need to be updated upon refreshes.
CREATE TABLE updates (
    "date" date NOT NULL,
    CONSTRAINT updates_pkey PRIMARY KEY(date)
);

CREATE LANGUAGE plpgsql;

-- FUNCTION update_status
-- This keeps the updates table up to date for the time graphs.
CREATE OR REPLACE FUNCTION update_status() RETURNS TRIGGER AS $$
    BEGIN
    IF (TG_OP='INSERT' OR TG_OP='UPDATE') THEN
        IF (SELECT COUNT(*) FROM updates
            WHERE DATE=DATE(new.validafter)) = 0 THEN
            INSERT INTO updates
            VALUES (DATE(NEW.validafter));
        END IF;
    END IF;
    IF (TG_OP='DELETE' OR TG_OP='UPDATE') THEN
        IF (SELECT COUNT(*) FROM updates
            WHERE DATE=DATE(old.validafter)) = 0 THEN
            INSERT INTO updates
            VALUES (DATE(OLD.validafter));
        END IF;
    END IF;
    RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$$ LANGUAGE plpgsql;

-- TRIGGER update_status
-- This calls the function update_status() each time a row is inserted,
-- updated, or deleted from the statusentry table.
CREATE TRIGGER update_status
AFTER INSERT OR UPDATE OR DELETE
ON statusentry
    FOR EACH ROW EXECUTE PROCEDURE update_status();

-- FUNCTION update_desc
-- This keeps the updates table up to date for the time graphs.
CREATE OR REPLACE FUNCTION update_desc() RETURNS TRIGGER AS $$
    BEGIN
    IF (TG_OP='INSERT' OR TG_OP='UPDATE') THEN
      BEGIN
        IF (SELECT COUNT(*) FROM updates
            WHERE DATE=DATE(new.published)) = 0 THEN
            INSERT INTO updates
            VALUES (DATE(NEW.published));
        END IF;
        IF (SELECT COUNT(*) FROM updates
            WHERE DATE=DATE(new.published)+1) = 0 THEN
            INSERT INTO updates
            VALUES (DATE(NEW.published)+1);
        END IF;
      END;
    END IF;
    IF (TG_OP='DELETE' OR TG_OP='UPDATE') THEN
      BEGIN
        IF (SELECT COUNT(*) FROM updates
            WHERE DATE=DATE(old.published)) = 0 THEN
            INSERT INTO updates
            VALUES (DATE(OLD.published));
        END IF;
        IF (SELECT COUNT(*) FROM updates
            WHERE DATE=DATE(old.published)+1) = 0 THEN
            INSERT INTO updates
            VALUES (DATE(OLD.published)+1);
        END IF;
      END;
    END IF;
    RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$$ LANGUAGE plpgsql;

-- TRIGGER update_desc
-- This calls the function update_desc() each time a row is inserted,
-- updated, or deleted from the descriptors table.
CREATE TRIGGER update_desc
AFTER INSERT OR UPDATE OR DELETE
ON descriptor
    FOR EACH ROW EXECUTE PROCEDURE update_desc();

-- FUNCTION refresh_relay_statuses_per_day()
-- Updates helper table which is used to refresh the aggregate tables.
CREATE OR REPLACE FUNCTION refresh_relay_statuses_per_day()
RETURNS INTEGER AS $$
    BEGIN
    DELETE FROM relay_statuses_per_day
    WHERE date IN (SELECT * FROM updates);
    INSERT INTO relay_statuses_per_day (date, count)
    SELECT DATE(validafter) AS date, COUNT(*) AS count
    FROM (SELECT DISTINCT validafter
          FROM statusentry
          WHERE DATE(validafter) >= (SELECT MIN(date) FROM updates)
          AND DATE(validafter) <= (SELECT MAX(date) FROM updates)
          AND DATE(validafter) IN (SELECT date FROM updates))
          distinct_consensuses
    GROUP BY DATE(validafter);
    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- refresh_* functions
-- The following functions keep their corresponding aggregate tables
-- up-to-date. They should be called every time ERNIE is run, or when new
-- data is finished being added to the descriptor or statusentry tables.
-- They find what new data has been entered or updated based on the
-- updates table.

-- FUNCTION refresh_network_size()
CREATE OR REPLACE FUNCTION refresh_network_size() RETURNS INTEGER AS $$
    BEGIN

    DELETE FROM network_size
    WHERE date IN (SELECT * FROM updates);

        INSERT INTO network_size
        (date, avg_running, avg_exit, avg_guard, avg_fast, avg_stable)
        SELECT
              DATE(validafter) as date,
              COUNT(*) / relay_statuses_per_day.count AS avg_running,
              SUM(CASE WHEN isexit IS TRUE THEN 1 ELSE 0 END)
                  / relay_statuses_per_day.count AS avg_exit,
              SUM(CASE WHEN isguard IS TRUE THEN 1 ELSE 0 END)
                  / relay_statuses_per_day.count AS avg_guard,
              SUM(CASE WHEN isfast IS TRUE THEN 1 ELSE 0 END)
                  / relay_statuses_per_day.count AS avg_fast,
              SUM(CASE WHEN isstable IS TRUE THEN 1 ELSE 0 END)
                  / relay_statuses_per_day.count AS avg_stable
          FROM statusentry
          JOIN relay_statuses_per_day
          ON DATE(validafter) = relay_statuses_per_day.date
          WHERE isrunning = TRUE
              AND DATE(validafter) >= (SELECT MIN(date) FROM updates)
              AND DATE(validafter) <= (SELECT MAX(date) FROM updates)
              AND DATE(validafter) IN (SELECT date FROM updates)
          GROUP BY DATE(validafter), relay_statuses_per_day.count;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_relay_platforms()
CREATE OR REPLACE FUNCTION refresh_relay_platforms() RETURNS INTEGER AS $$
    BEGIN

    DELETE FROM relay_platforms
    WHERE date IN (SELECT * FROM updates);

    INSERT INTO relay_platforms
    (date, avg_linux, avg_darwin, avg_bsd, avg_windows, avg_other)
    SELECT DATE(validafter),
        SUM(CASE WHEN platform LIKE '%Linux%' THEN 1 ELSE 0 END) /
            relay_statuses_per_day.count AS avg_linux,
        SUM(CASE WHEN platform LIKE '%Darwin%' THEN 1 ELSE 0 END) /
            relay_statuses_per_day.count AS avg_darwin,
        SUM(CASE WHEN platform LIKE '%BSD%' THEN 1 ELSE 0 END) /
            relay_statuses_per_day.count AS avg_bsd,
        SUM(CASE WHEN platform LIKE '%Windows%' THEN 1 ELSE 0 END) /
            relay_statuses_per_day.count AS avg_windows,
        SUM(CASE WHEN platform NOT LIKE '%Windows%'
            AND platform NOT LIKE '%Darwin%'
            AND platform NOT LIKE '%BSD%'
            AND platform NOT LIKE '%Linux%' THEN 1 ELSE 0 END) /
            relay_statuses_per_day.count AS avg_other
    FROM descriptor RIGHT JOIN statusentry
    ON statusentry.descriptor = descriptor.descriptor
    JOIN relay_statuses_per_day
    ON DATE(validafter) = relay_statuses_per_day.date
    WHERE isrunning = TRUE
          AND DATE(validafter) >= (SELECT MIN(date) FROM updates)
          AND DATE(validafter) <= (SELECT MAX(date) FROM updates)
          AND DATE(validafter) IN (SELECT date FROM updates)
          AND DATE(relay_statuses_per_day.date) >=
              (SELECT MIN(date) FROM updates)
          AND DATE(relay_statuses_per_day.date) <=
              (SELECT MAX(date) FROM updates)
          AND DATE(relay_statuses_per_day.date) IN
              (SELECT date FROM updates)
    GROUP BY DATE(validafter), relay_statuses_per_day.count;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_relay_versions()
CREATE OR REPLACE FUNCTION refresh_relay_versions() RETURNS INTEGER AS $$
    BEGIN

    DELETE FROM relay_versions
    WHERE date IN (SELECT * FROM updates);

    INSERT INTO relay_versions
    (date, "0.1.0", "0.1.1", "0.1.2", "0.2.0", "0.2.1", "0.2.2", "0.2.3")
    SELECT DATE(validafter),
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.1.0' THEN 1 ELSE 0 END)
            / relay_statuses_per_day.count AS "0.1.0",
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.1.1' THEN 1 ELSE 0 END)
            / relay_statuses_per_day.count AS "0.1.1",
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.1.2' THEN 1 ELSE 0 END)
            / relay_statuses_per_day.count AS "0.1.2",
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.2.0' THEN 1 ELSE 0 END)
            / relay_statuses_per_day.count AS "0.2.0",
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.2.1' THEN 1 ELSE 0 END)
            / relay_statuses_per_day.count AS "0.2.1",
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.2.2' THEN 1 ELSE 0 END)
            / relay_statuses_per_day.count AS "0.2.2",
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.2.3' THEN 1 ELSE 0 END)
            / relay_statuses_per_day.count AS "0.2.3"
    FROM descriptor RIGHT JOIN statusentry
    ON descriptor.descriptor = statusentry.descriptor
    JOIN relay_statuses_per_day
    ON DATE(validafter) = relay_statuses_per_day.date
    WHERE isrunning = TRUE
          AND DATE(validafter) >= (SELECT MIN(date) FROM updates)
          AND DATE(validafter) <= (SELECT MAX(date) FROM updates)
          AND DATE(validafter) IN (SELECT date FROM updates)
          AND DATE(relay_statuses_per_day.date) >=
              (SELECT MIN(date) FROM updates)
          AND DATE(relay_statuses_per_day.date) <=
              (SELECT MAX(date) FROM updates)
          AND DATE(relay_statuses_per_day.date) IN
              (SELECT date FROM updates)
    GROUP BY DATE(validafter), relay_statuses_per_day.count;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_total_bandwidth()
-- This keeps the table total_bandwidth up-to-date when necessary.
CREATE OR REPLACE FUNCTION refresh_total_bandwidth() RETURNS INTEGER AS $$
    BEGIN

    DELETE FROM total_bandwidth
    WHERE date IN (SELECT * FROM updates);

    INSERT INTO total_bandwidth
    (bwavg, bwburst, bwobserved, date)
    SELECT (SUM(bandwidthavg)
            / relay_statuses_per_day.count)::BIGINT AS bwavg,
        (SUM(bandwidthburst)
            / relay_statuses_per_day.count)::BIGINT AS bwburst,
        (SUM(bandwidthobserved)
            / relay_statuses_per_day.count)::BIGINT AS bwobserved,
        DATE(validafter)
    FROM descriptor RIGHT JOIN statusentry
    ON descriptor.descriptor = statusentry.descriptor
    JOIN relay_statuses_per_day
    ON DATE(validafter) = relay_statuses_per_day.date
    WHERE isrunning = TRUE
          AND DATE(validafter) >= (SELECT MIN(date) FROM updates)
          AND DATE(validafter) <= (SELECT MAX(date) FROM updates)
          AND DATE(validafter) IN (SELECT date FROM updates)
          AND DATE(relay_statuses_per_day.date) >=
              (SELECT MIN(date) FROM updates)
          AND DATE(relay_statuses_per_day.date) <=
              (SELECT MAX(date) FROM updates)
          AND DATE(relay_statuses_per_day.date) IN
              (SELECT date FROM updates)
    GROUP BY DATE(validafter), relay_statuses_per_day.count;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

