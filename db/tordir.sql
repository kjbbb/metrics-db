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

-- TABLE bandwidth
-- Contains bandwidth histories contained in extra-info descriptors.
-- Every row represents a 15-minute interval and can have read, written,
-- dirread, and dirwritten set or not. We're making sure that there's only
-- one interval for each extrainfo. However, it's possible that an
-- interval is contained in another extra-info descriptor of the same
-- relay. These duplicates need to be filtered when aggregating bandwidth
-- histories.
CREATE TABLE bwhist (
    fingerprint CHARACTER(40) NOT NULL,
    extrainfo CHARACTER(40) NOT NULL,
    intervalend TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    read BIGINT,
    written BIGINT,
    dirread BIGINT,
    dirwritten BIGINT,
    CONSTRAINT bwhist_pkey PRIMARY KEY (extrainfo, intervalend)
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

-- TABLE relays_seen_day
-- Stores all of the unique routers appearing in each separate day.
CREATE TABLE relays_seen_day (
    day DATE NOT NULL,
    fingerprint CHARACTER(40) NOT NULL,
    CONSTRAINT relays_seen_week_pkey PRIMARY KEY(week, fingerprint)
);

-- TABLE relays_seen_week
CREATE TABLE relays_seen_week (
    week DATE NOT NULL,
    fingerprint CHARACTER(40) NOT NULL,
    CONSTRAINT relays_seen_week_pkey PRIMARY KEY(week, fingerprint)
);

-- TABLE relays_seen_month
CREATE TABLE relays_seen_month (
    month DATE NOT NULL,
    fingerprint CHARACTER(40) NOT NULL,
    CONSTRAINT relays_seen_month_pkey PRIMARY KEY(month, fingerprint)
);

-- TABLE relay_churn_day
-- This statistic shows how many routers from one cohort are still running
-- the next. The ratio is portrayed as a percent.
CREATE TABLE relay_churn_day (
    day DATE NOT NULL,
    ratio FLOAT NOT NULL,
    CONSTRAINT relay_churn_day_pkey PRIMARY KEY(day)
);

-- TABLE relay_churn_week
CREATE TABLE relay_churn_week (
    week DATE NOT NULL,
    ratio FLOAT NOT NULL,
    CONSTRAINT relay_churn_week_pkey PRIMARY KEY(week)
);

-- TABLE relay_churn_month
CREATE TABLE relay_churn_month (
    month DATE NOT NULL,
    ratio FLOAT NOT NULL
    CONSTRAINT relay_churn_month_pkey PRIMARY KEY(month)
);

-- Create the various indexes we need for searching relays
CREATE INDEX statusentry_validafter_address
  ON statusentry (validafter, address);
CREATE INDEX statusentry_descriptor ON statusentry (descriptor);
CREATE INDEX statusentry_validafter_fingerprint
  ON statusentry (validafter, fingerprint);
CREATE INDEX statusentry_validafter_nickname
  ON statusentry (validafter, LOWER(nickname));
CREATE INDEX statusentry_validafter ON statusentry (validafter);

-- And create an index that we use for precalculating statistics
CREATE INDEX statusentry_validafter_date ON statusentry (DATE(validafter));

-- TABLE network_size
CREATE TABLE network_size (
    date DATE NOT NULL,
    avg_running INTEGER NOT NULL,
    avg_exit INTEGER NOT NULL,
    avg_guard INTEGER NOT NULL,
    avg_fast INTEGER NOT NULL,
    avg_stable INTEGER NOT NULL,
    CONSTRAINT network_size_pkey PRIMARY KEY(date)
);

-- TABLE network_size_hour
CREATE TABLE network_size_hour (
    validafter TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    avg_running INTEGER NOT NULL,
    avg_exit INTEGER NOT NULL,
    avg_guard INTEGER NOT NULL,
    avg_fast INTEGER NOT NULL,
    avg_stable INTEGER NOT NULL,
    CONSTRAINT network_size_hour_pkey PRIMARY KEY(validafter)
);

-- TABLE relay_platforms
CREATE TABLE relay_platforms (
    date DATE NOT NULL,
    avg_linux INTEGER NOT NULL,
    avg_darwin INTEGER NOT NULL,
    avg_bsd INTEGER NOT NULL,
    avg_windows INTEGER NOT NULL,
    avg_other INTEGER NOT NULL,
    CONSTRAINT relay_platforms_pkey PRIMARY KEY(date)
);

-- TABLE relay_versions
CREATE TABLE relay_versions (
    date DATE NOT NULL,
    version CHARACTER(5) NOT NULL,
    relays INTEGER NOT NULL,
    CONSTRAINT relay_versions_pkey PRIMARY KEY(date, version)
);

-- TABLE total_bandwidth
-- Contains information for the whole network's total bandwidth which is
-- used in the bandwidth graphs.
CREATE TABLE total_bandwidth (
    date DATE NOT NULL,
    bwavg BIGINT NOT NULL,
    bwburst BIGINT NOT NULL,
    bwobserved BIGINT NOT NULL,
    bwadvertised BIGINT NOT NULL,
    CONSTRAINT total_bandwidth_pkey PRIMARY KEY(date)
);

-- TABLE total_bwhist
-- Contains the total number of read/written and the number of dir bytes
-- read/written by all relays in the network on a given day. The dir bytes
-- are an estimate based on the subset of relays that count dir bytes.
CREATE TABLE total_bwhist (
    date DATE NOT NULL,
    read BIGINT,
    written BIGINT,
    dirread BIGINT,
    dirwritten BIGINT,
    CONSTRAINT total_bwhist_pkey PRIMARY KEY(date)
);

-- TABLE user_stats
-- Aggregate statistics on directory requests and byte histories that we
-- use to estimate user numbers.
CREATE TABLE user_stats (
    date DATE NOT NULL,
    country CHARACTER(2) NOT NULL,
    r BIGINT,
    dw BIGINT,
    dr BIGINT,
    drw BIGINT,
    drr BIGINT,
    bw BIGINT,
    br BIGINT,
    bwd BIGINT,
    brd BIGINT,
    bwr BIGINT,
    brr BIGINT,
    bwdr BIGINT,
    brdr BIGINT,
    bwp BIGINT,
    brp BIGINT,
    bwn BIGINT,
    brn BIGINT,
    CONSTRAINT user_stats_pkey PRIMARY KEY(date, country)
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

-- FUNCTION update_bwhist
-- This keeps the updates table up to date for the time graphs.
CREATE OR REPLACE FUNCTION update_bwhist() RETURNS TRIGGER AS $$
    BEGIN
    IF (TG_OP='INSERT' OR TG_OP='UPDATE') THEN
      IF (SELECT COUNT(*) FROM updates
          WHERE DATE = DATE(NEW.intervalend)) = 0 THEN
          INSERT INTO updates
          VALUES (DATE(NEW.intervalend));
      END IF;
    END IF;
    IF (TG_OP='DELETE' OR TG_OP='UPDATE') THEN
      IF (SELECT COUNT(*) FROM updates
          WHERE DATE = DATE(OLD.intervalend)) = 0 THEN
          INSERT INTO updates
          VALUES (DATE(OLD.intervalend));
      END IF;
    END IF;
    RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$$ LANGUAGE plpgsql;

-- TRIGGER update_desc
-- This calls the function update_desc() each time a row is inserted,
-- updated, or deleted from the descriptors table.
CREATE TRIGGER update_bwhist
AFTER INSERT OR UPDATE OR DELETE
ON bwhist
    FOR EACH ROW EXECUTE PROCEDURE update_bwhist();

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
              DATE(validafter) AS date,
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

-- FUNCTION refresh_network_size_hour()
CREATE OR REPLACE FUNCTION refresh_network_size_hour() RETURNS INTEGER AS $$
    BEGIN

    DELETE FROM network_size_hour
    WHERE DATE(validafter) IN (SELECT * FROM updates);

    INSERT INTO network_size_hour
    (validafter, avg_running, avg_exit, avg_guard, avg_fast, avg_stable)
    SELECT validafter, COUNT(*) AS avg_running,
    SUM(CASE WHEN isexit IS TRUE THEN 1 ELSE 0 END) AS avg_exit,
    SUM(CASE WHEN isguard IS TRUE THEN 1 ELSE 0 END) AS avg_guard,
    SUM(CASE WHEN isfast IS TRUE THEN 1 ELSE 0 END) AS avg_fast,
    SUM(CASE WHEN isstable IS TRUE THEN 1 ELSE 0 END) AS avg_stable
    FROM statusentry
    WHERE isrunning = TRUE
    AND DATE(validafter) >= (SELECT MIN(date) FROM updates)
    AND DATE(validafter) <= (SELECT MAX(date) FROM updates)
    AND DATE(validafter) IN (SELECT date FROM updates)
    GROUP BY validafter;

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
    (date, version, relays)
    SELECT DATE(validafter), SUBSTRING(platform, 5, 5) AS version,
           COUNT(*) / relay_statuses_per_day.count AS relays
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
          AND platform IS NOT NULL
    GROUP BY 1, 2, relay_statuses_per_day.count;

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
    (bwavg, bwburst, bwobserved, bwadvertised, date)
    SELECT (SUM(bandwidthavg)
            / relay_statuses_per_day.count)::BIGINT AS bwavg,
        (SUM(bandwidthburst)
            / relay_statuses_per_day.count)::BIGINT AS bwburst,
        (SUM(bandwidthobserved)
            / relay_statuses_per_day.count)::BIGINT AS bwobserved,
        (SUM(LEAST(bandwidthavg, bandwidthobserved))
            / relay_statuses_per_day.count)::BIGINT AS bwadvertised,
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

-- FUNCTION refresh_total_bwhist()
CREATE OR REPLACE FUNCTION refresh_total_bwhist() RETURNS INTEGER AS $$
  BEGIN
  DELETE FROM total_bwhist WHERE date IN (SELECT * FROM updates);
  INSERT INTO total_bwhist (date, read, written, dirread, dirwritten)
  SELECT date,
         SUM(read) AS read,
         SUM(written) AS written,
         SUM(dirread) * (SUM(written) + SUM(read)) / (1
           + SUM(CASE WHEN dirwritten IS NULL THEN NULL ELSE written END)
           + SUM(CASE WHEN dirread IS NULL THEN NULL ELSE read END))
           AS dirread,
         SUM(dirwritten) * (SUM(written) + SUM(read)) / (1
           + SUM(CASE WHEN dirwritten IS NULL THEN NULL ELSE written END)
           + SUM(CASE WHEN dirread IS NULL THEN NULL ELSE read END))
           AS dirwritten
  FROM (
    SELECT fingerprint,
           DATE(intervalend) AS date,
           SUM(read) AS read,
           SUM(written) AS written,
           SUM(dirread) AS dirread,
           SUM(dirwritten) AS dirwritten
    FROM (
      SELECT DISTINCT fingerprint,
                      intervalend,
                      read,
                      written,
                      dirread,
                      dirwritten
      FROM bwhist
      WHERE DATE(intervalend) >= (SELECT MIN(date) FROM updates)
      AND DATE(intervalend) <= (SELECT MAX(date) FROM updates)
      AND DATE(intervalend) IN (SELECT date FROM updates)
    ) byinterval
    GROUP BY fingerprint, DATE(intervalend)
  ) byrelay
  GROUP BY date;
  RETURN 1;
  END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_user_stats()
-- This function refreshes our user statistics by weighting reported
-- directory request statistics of directory mirrors with bandwidth
-- histories.
CREATE OR REPLACE FUNCTION refresh_user_stats() RETURNS INTEGER AS $$
  BEGIN
  -- Start by deleting user statistics of the dates we're about to
  -- regenerate.
  DELETE FROM user_stats WHERE date IN (SELECT * FROM updates);
  -- Now insert new user statistics.
  INSERT INTO user_stats (date, country, r, dw, dr, drw, drr, bw, br, bwd,
      brd, bwr, brr, bwdr, brdr, bwp, brp, bwn, brn)
  SELECT
         -- We want to learn about total requests by date and country.
         dirreq_stats_by_country.date AS date,
         dirreq_stats_by_country.country AS country,
         dirreq_stats_by_country.r AS r,
         -- In order to weight the reported directory requests, we're
         -- counting bytes of relays (except directory authorities)
         -- matching certain criteria: whether or not they are reporting
         -- directory requests, whether or not they are reporting
         -- directory bytes, and whether their directory port is open or
         -- closed.
         SUM(CASE WHEN authority IS NOT NULL
           THEN NULL ELSE dirwritten END) AS dw,
         SUM(CASE WHEN authority IS NOT NULL
           THEN NULL ELSE dirread END) AS dr,
         SUM(CASE WHEN requests IS NULL OR authority IS NOT NULL
           THEN NULL ELSE dirwritten END) AS dwr,
         SUM(CASE WHEN requests IS NULL OR authority IS NOT NULL
           THEN NULL ELSE dirread END) AS drr,
         SUM(CASE WHEN authority IS NOT NULL
           THEN NULL ELSE written END) AS bw,
         SUM(CASE WHEN authority IS NOT NULL
           THEN NULL ELSE read END) AS br,
         SUM(CASE WHEN dirwritten IS NULL OR authority IS NOT NULL
           THEN NULL ELSE written END) AS bwd,
         SUM(CASE WHEN dirwritten IS NULL OR authority IS NOT NULL
           THEN NULL ELSE read END) AS brd,
         SUM(CASE WHEN requests IS NULL OR authority IS NOT NULL
           THEN NULL ELSE written END) AS bwr,
         SUM(CASE WHEN requests IS NULL OR authority IS NOT NULL
           THEN NULL ELSE read END) AS brr,
         SUM(CASE WHEN dirwritten IS NULL OR requests IS NULL
           OR authority IS NOT NULL THEN NULL ELSE written END) AS bwdr,
         SUM(CASE WHEN dirwritten IS NULL OR requests IS NULL
           OR authority IS NOT NULL THEN NULL ELSE read END) AS brdr,
         SUM(CASE WHEN opendirport IS NULL OR authority IS NOT NULL
           THEN NULL ELSE written END) AS bwp,
         SUM(CASE WHEN opendirport IS NULL OR authority IS NOT NULL
           THEN NULL ELSE read END) AS brp,
         SUM(CASE WHEN opendirport IS NOT NULL OR authority IS NOT NULL
           THEN NULL ELSE written END) AS bwn,
         SUM(CASE WHEN opendirport IS NOT NULL OR authority IS NOT NULL
           THEN NULL ELSE read END) AS brn
  FROM (
    -- The first sub-select tells us the total number of directory
    -- requests per country reported by all directory mirrors.
    SELECT dirreq_stats_by_date.date AS date, country, SUM(requests) AS r
    FROM (
      SELECT fingerprint, date, country, SUM(requests) AS requests
      FROM (
        -- There are two selects here, because in most cases the directory
        -- request statistics cover two calendar dates.
        SELECT LOWER(source) AS fingerprint, DATE(statsend) AS date,
          country, FLOOR(requests * (CASE
          WHEN EXTRACT(EPOCH FROM DATE(statsend)) >
          EXTRACT(EPOCH FROM statsend) - seconds
          THEN EXTRACT(EPOCH FROM statsend) -
          EXTRACT(EPOCH FROM DATE(statsend))
          ELSE seconds END) / seconds) AS requests
        FROM dirreq_stats
        UNION
        SELECT LOWER(source) AS fingerprint, DATE(statsend) - 1 AS date,
          country, FLOOR(requests *
          (EXTRACT(EPOCH FROM DATE(statsend)) -
          EXTRACT(EPOCH FROM statsend) + seconds)
          / seconds) AS requests
        FROM dirreq_stats
        WHERE EXTRACT(EPOCH FROM DATE(statsend)) -
        EXTRACT(EPOCH FROM statsend) + seconds > 0
      ) dirreq_stats_split
      GROUP BY 1, 2, 3
    ) dirreq_stats_by_date
    -- We're only interested in requests by directory mirrors, not
    -- directory authorities, so we exclude all relays with the Authority
    -- flag.
    RIGHT JOIN (
      SELECT fingerprint, DATE(validafter) AS date
      FROM statusentry
      WHERE DATE(validafter) >= (SELECT MIN(date) FROM updates)
      AND DATE(validafter) <= (SELECT MAX(date) FROM updates)
      AND DATE(validafter) IN (SELECT date FROM updates)
      AND isauthority IS FALSE
      GROUP BY 1, 2
    ) statusentry_dirmirrors
    ON dirreq_stats_by_date.fingerprint =
       statusentry_dirmirrors.fingerprint
    AND dirreq_stats_by_date.date = statusentry_dirmirrors.date
    GROUP BY 1, 2
  ) dirreq_stats_by_country
  LEFT JOIN (
    -- In the next step, we expand the result by bandwidth histories of
    -- all relays.
    SELECT fingerprint,
           DATE(intervalend) AS date,
           SUM(read) AS read, SUM(written) AS written,
           SUM(dirread) AS dirread, SUM(dirwritten) AS dirwritten
    FROM (
      SELECT DISTINCT fingerprint, intervalend,
        read, written, dirread, dirwritten
      FROM bwhist
      WHERE DATE(intervalend) >= (SELECT MIN(date) FROM updates)
      AND DATE(intervalend) <= (SELECT MAX(date) FROM updates)
      AND DATE(intervalend) IN (SELECT date FROM updates)
    ) distinct_bwhist
    GROUP BY 1, 2
  ) bwhist_by_relay
  ON dirreq_stats_by_country.date = bwhist_by_relay.date
  LEFT JOIN (
    -- For each relay, tell how often it had an open directory port and
    -- how often it had the Authority flag assigned on a given date.
    SELECT fingerprint, DATE(validafter) AS date,
      SUM(CASE WHEN dirport > 0 THEN 1 ELSE NULL END) AS opendirport,
      SUM(CASE WHEN isauthority IS TRUE THEN 1 ELSE NULL END) AS authority
    FROM statusentry
    WHERE DATE(validafter) >= (SELECT MIN(date) FROM updates)
    AND DATE(validafter) <= (SELECT MAX(date) FROM updates)
    AND DATE(validafter) IN (SELECT date FROM updates)
    GROUP BY 1, 2
  ) statusentry_by_relay
  ON bwhist_by_relay.fingerprint = statusentry_by_relay.fingerprint
  AND bwhist_by_relay.date = statusentry_by_relay.date
  LEFT JOIN (
    -- For each relay, tell if it has reported directory request
    -- statistics on a given date. Again, we have to take into account
    -- that statistics intervals cover more than one calendar date in most
    -- cases. The exact number of requests isn't relevant here, but only
    -- whether the relay reported directory requests or not.
    SELECT fingerprint, date, 1 AS requests
    FROM (
      SELECT LOWER(source) AS fingerprint, DATE(statsend) AS date
      FROM dirreq_stats
      WHERE DATE(statsend) >= (SELECT MIN(date) FROM updates)
      AND DATE(statsend) <= (SELECT MAX(date) FROM updates)
      AND DATE(statsend) IN (SELECT date FROM updates)
      AND country = 'zy'
      UNION
      SELECT LOWER(source) AS fingerprint, DATE(statsend) - 1 AS date
      FROM dirreq_stats
      WHERE DATE(statsend) - 1 >= (SELECT MIN(date) FROM updates)
      AND DATE(statsend) - 1 <= (SELECT MAX(date) FROM updates)
      AND DATE(statsend) - 1 IN (SELECT date FROM updates)
      AND country = 'zy'
      AND EXTRACT(EPOCH FROM DATE(statsend)) -
      EXTRACT(EPOCH FROM statsend) + seconds > 0
    ) dirreq_stats_split
    GROUP BY 1, 2
  ) dirreq_stats_by_relay
  ON bwhist_by_relay.fingerprint = dirreq_stats_by_relay.fingerprint
  AND bwhist_by_relay.date = dirreq_stats_by_relay.date
  WHERE dirreq_stats_by_country.country IS NOT NULL
  -- Group by date, country, and total reported directory requests,
  -- summing up the bandwidth histories.
  GROUP BY 1, 2, 3;
  RETURN 1;
  END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_relay_churn_*
-- The churn tables find the percentage of relays from each
-- week/month/year that appear in the following week/month/year.
CREATE OR REPLACE FUNCTION refresh_relay_churn_day()
RETURNS INTEGER AS $$
    BEGIN

    DELETE FROM relays_seen_day
    WHERE DATE(day) IN (SELECT * FROM updates);

    INSERT INTO
    relays_seen_day (fingerprint, day)
    SELECT DISTINCT fingerprint,
        DATE_TRUNC('day', validafter) AS day
    FROM descriptor LEFT JOIN statusentry
    ON descriptor.descriptor=statusentry.descriptor
    WHERE DATE_TRUNC('day', validafter) IN
        (SELECT DATE_TRUNC('day', date) FROM updates)
        AND DATE_TRUNC('day', validafter) IS NOT NULL
    GROUP BY 1, 2;

    DELETE FROM relay_churn_day;

    INSERT INTO relay_churn_day
    (day, ratio)
    SELECT relays_seen_day.day AS day,
        (churn.count::FLOAT/COUNT(DISTINCT fingerprint)::FLOAT) AS ratio
    FROM relays_seen_day
    JOIN ( SELECT COUNT(DISTINCT now.fingerprint) AS count, now.day
        FROM relays_seen_day now
        JOIN relays_seen_day future
        ON DATE(now.day)=DATE(future.day + interval '1 day')
        AND now.fingerprint=future.fingerprint
        GROUP BY 2) AS churn
    ON relays_seen_day.day=churn.day
    GROUP BY 1, churn.count;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_relay_churn_week
CREATE OR REPLACE FUNCTION refresh_relay_churn_week()
RETURNS INTEGER AS $$

    DELETE FROM relays_seen_week
    WHERE DATE(week) IN (SELECT * FROM updates);

    INSERT INTO
    relays_seen_week (fingerprint, week)
    SELECT DISTINCT fingerprint,
        DATE_TRUNC('week', validafter) AS week
    FROM descriptor LEFT JOIN statusentry
    ON descriptor.descriptor=statusentry.descriptor
    WHERE DATE_TRUNC('week', validafter) IN
        (SELECT DATE_TRUNC('week', date) FROM updates)
        AND DATE_TRUNC('week', validafter) IS NOT NULL
    GROUP BY 1, 2;

    DELETE FROM relay_churn_week;

    INSERT INTO relay_churn_week
    (week, ratio)
    SELECT relays_seen_week.week AS week,
        (churn.count::FLOAT/COUNT(DISTINCT fingerprint)::FLOAT) AS ratio
    FROM relays_seen_week
    JOIN ( SELECT COUNT(DISTINCT now.fingerprint) AS count, now.week
        FROM relays_seen_week now
        JOIN relays_seen_week future
        ON DATE(now.week)=DATE(future.week + interval '1 week')
        AND now.fingerprint=future.fingerprint
        GROUP BY 2) AS churn
    ON relays_seen_week.week=churn.week
    GROUP BY 1, churn.count;

    DELETE FROM relay_churn_month;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_relay_churn_month
CREATE OR REPLACE FUNCTION refresh_relay_churn_month()
RETURNS INTEGER AS $$

    DELETE FROM relays_seen_month
    WHERE DATE(month) IN (SELECT * FROM updates);

    INSERT INTO
    relays_seen_month (fingerprint, month)
    SELECT DISTINCT fingerprint,
        DATE_TRUNC('month', validafter) AS month
    FROM descriptor LEFT JOIN statusentry
    ON descriptor.descriptor=statusentry.descriptor
    WHERE DATE_TRUNC('month', validafter) IN
        (SELECT DATE_TRUNC('month', date) FROM updates)
        AND DATE_TRUNC('month', validafter) IS NOT NULL
    GROUP BY 1, 2;

    INSERT INTO relay_churn_month
    (month, ratio)
    SELECT relays_seen_month.month,
        (churn.count::float/count(distinct fingerprint)::float) as ratio
    FROM relays_seen_month
    JOIN ( SELECT COUNT(DISTINCT now.fingerprint) AS count, now.month
        FROM relays_seen_month now
        JOIN relays_seen_month future
        ON DATE(now.month)=DATE(future.month + interval '1 month')
        AND now.fingerprint=future.fingerprint
        GROUP BY 2) AS churn
    ON relays_seen_month.month=churn.month
    GROUP BY 1, churn.count;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- non-relay statistics
-- The following tables contain pre-aggregated statistics that are not
-- based on relay descriptors or that are not yet derived from the relay
-- descriptors in the database.

-- TABLE bridge_network_size
-- Contains average number of running bridges.
CREATE TABLE bridge_network_size (
    "date" DATE NOT NULL,
    avg_running INTEGER NOT NULL,
    CONSTRAINT bridge_network_size_pkey PRIMARY KEY(date)
);

-- TABLE dirreq_stats
-- Contains daily users by country.
CREATE TABLE dirreq_stats (
    source CHARACTER(40) NOT NULL,
    statsend TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    seconds INTEGER NOT NULL,
    country CHARACTER(2) NOT NULL,
    requests INTEGER NOT NULL,
    CONSTRAINT dirreq_stats_pkey
    PRIMARY KEY (source, statsend, seconds, country)
);

-- TABLE bridge_stats
-- Contains daily bridge users by country.
CREATE TABLE bridge_stats (
    "date" DATE NOT NULL,
    country CHARACTER(2) NOT NULL,
    users INTEGER NOT NULL,
    CONSTRAINT bridge_stats_pkey PRIMARY KEY ("date", country)
);

-- TABLE torperf_stats
-- Quantiles and medians of daily torperf results.
CREATE TABLE torperf_stats (
    "date" DATE NOT NULL,
    source CHARACTER VARYING(32) NOT NULL,
    q1 INTEGER NOT NULL,
    md INTEGER NOT NULL,
    q3 INTEGER NOT NULL,
    CONSTRAINT torperf_stats_pkey PRIMARY KEY("date", source)
);

-- TABLE gettor_stats
-- Packages requested from GetTor
CREATE TABLE gettor_stats (
    "date" DATE NOT NULL,
    bundle CHARACTER VARYING(32) NOT NULL,
    downloads INTEGER NOT NULL,
    CONSTRAINT gettor_stats_pkey PRIMARY KEY("date", bundle)
);

