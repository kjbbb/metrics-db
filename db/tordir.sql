SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

-- TABLE descriptor
-- Contains all of the descriptors published by routers. This is updated
-- and written to by the Java data processor. (See
-- src/org/torproject/ernie/db/RelayDescriptorDatabaseImporter.java).
CREATE TABLE descriptor (
    descriptor character(40) NOT NULL,
    address character varying(15) NOT NULL,
    orport integer NOT NULL,
    dirport integer NOT NULL,
    bandwidthavg bigint NOT NULL,
    bandwidthburst bigint NOT NULL,
    bandwidthobserved bigint NOT NULL,
    platform character varying(256),
    published timestamp without time zone NOT NULL,
    uptime bigint
);

-- TABLE statusentry
-- Contains all of the consensuses published by the directories. Each
-- statusentry references a valid descriptor. This is written to by the
-- java data processor. (See
-- src/org/torproject/ernie/db/RelayDescriptorDatabaseImporter.java)
CREATE TABLE statusentry (
    validafter timestamp without time zone NOT NULL,
    descriptor character(40) NOT NULL,
    isauthority boolean DEFAULT false NOT NULL,
    isbadexit boolean DEFAULT false NOT NULL,
    isbaddirectory boolean DEFAULT false NOT NULL,
    isexit boolean DEFAULT false NOT NULL,
    isfast boolean DEFAULT false NOT NULL,
    isguard boolean DEFAULT false NOT NULL,
    ishsdir boolean DEFAULT false NOT NULL,
    isnamed boolean DEFAULT false NOT NULL,
    isstable boolean DEFAULT false NOT NULL,
    isrunning boolean DEFAULT false NOT NULL,
    isunnamed boolean DEFAULT false NOT NULL,
    isvalid boolean DEFAULT false NOT NULL,
    isv2dir boolean DEFAULT false NOT NULL,
    isv3dir boolean DEFAULT false NOT NULL
);

-- The tables bridge_stats, torperf_stats, gettor_stats, networksize,
-- relay_platforms, relay_versions, platforms_uptime_month, and the
-- relay_churn_* tables are all aggregate tables kept up-to-date for use
-- in generating graphs, since keeping their statistics takes too long
-- elsewhere. They are kept up-to-date by their respective refresh_*
-- functions.

-- TABLE bridge_status
-- Contains the bridge statistics for the bridge users time graphs.
-- See src/org/torproject/ernie/db/BridgeDescriptorDatabaseImporter.java
-- TODO normalize this table by country.
CREATE TABLE bridge_stats (
    date DATE NOT NULL,
    bh FLOAT,
    cn FLOAT,
    cu FLOAT,
    et FLOAT,
    ir FLOAT,
    mm FLOAT,
    sa FLOAT,
    sy FLOAT,
    tm FLOAT,
    tn FLOAT,
    uz FLOAT,
    vn FLOAT,
    ye FLOAT
);

-- TABLE torperf_stats
-- See src/org/torproject/ernie/db/TorperfDatabaseImporter.java
CREATE TABLE torperf_stats (
    source character varying(32) NOT NULL,
    time timestamp without time zone NOT NULL,
    size character varying(8) NOT NULL,
    q1 integer NOT NULL,
    md integer NOT NULL,
    q3 integer NOT NULL
);

-- TABLE gettor_stats
-- See src/org/torproject/ernie/db/GetTorDatabaseImporter.java
CREATE TABLE gettor_stats (
    time timestamp without time zone NOT NULL,
    bundle character varying(32) NOT NULL,
    count integer NOT NULL
);

-- TABLE network_size
-- Aggregate table created from the descriptor/statusentry tables.
CREATE TABLE network_size (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    avg_running INTEGER NOT NULL,
    avg_exit INTEGER NOT NULL,
    avg_guard INTEGER NOT NULL
);

-- TABLE relay_platforms
-- Aggregate table created from the descriptor/statusentry tables.
CREATE TABLE relay_platforms (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    avg_linux INTEGER NOT NULL,
    avg_darwin INTEGER NOT NULL,
    avg_bsd INTEGER NOT NULL,
    avg_windows INTEGER NOT NULL,
    avg_other INTEGER NOT NULL
);

-- TABLE relay_versions
-- Aggregate table created from the descriptor/statusentry tables.
CREATE TABLE relay_versions (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    "0.1.2" INTEGER NOT NULL,
    "0.2.0" INTEGER NOT NULL,
    "0.2.1" INTEGER NOT NULL,
    "0.2.2" INTEGER NOT NULL
);

-- TABLE total_bandwidth Contains information for the whole network's total
-- bandwidth which is used in the bandwidth graphs. Aggregate table created
-- from the descriptor/statusentry tables.
CREATE TABLE total_bandwidth (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    bwavg BIGINT NOT NULL,
    bwburst BIGINT NOT NULL,
    bwobserved BIGINT NOT NULL
);

-- TABLE platforms_uptime_month Contains information regarding the average
-- router uptime per month.  This statistic is not perfect and requires the
-- averages to be calculated from sessions. See the function
-- refresh_platforms_uptime_month() for more information.  Aggregate table
-- created from the descriptor/statusentry tables.
CREATE TABLE platforms_uptime_month (
    month DATE NOT NULL,
    avg_windows INTEGER NOT NULL,
    avg_darwin INTEGER NOT NULL,
    avg_linux INTEGER NOT NULL,
    avg_freebsd INTEGER NOT NULL
);

-- TABLE relays_seen_week
-- This table is materialized in refresh_churn(). It finds all of the
-- routers appearing in each separate week.
CREATE TABLE relays_seen_week (
    week DATE NOT NULL,
    fingerprint CHARACTER(40) NOT NULL
);

-- TABLE relays_seen_month
-- This table is materialized in refresh_churn(). It finds all of the
-- routers appearing in each separate month.
CREATE TABLE relays_seen_month (
    month DATE NOT NULL,
    fingerprint CHARACTER(40) NOT NULL
);

-- TABLE relays_seen_year
-- This table is materialized in refresh_churn(). It finds all of the
-- routers appearing in each separate year.
CREATE TABLE relays_seen_year (
    year DATE NOT NULL,
    fingerprint CHARACTER(40) NOT NULL
);

-- TABLE relay_churn_week
-- This statistic shows how many routers from one week are still running
-- the next. The ratio is portrayed as a percent.
CREATE TABLE relay_churn_week (
    week DATE NOT NULL,
    ratio FLOAT NOT NULL
);

-- TABLE relay_churn_month
-- This statistic shows how many routers from one month are still running
-- the next. The ratio is portrayed as a percent.
CREATE TABLE relay_churn_month (
    month DATE NOT NULL,
    ratio FLOAT NOT NULL
);

-- TABLE relay_churn_year
-- This statistic shows how many routers from one year are still running
-- the next. The ratio is portrayed as a percent.
CREATE TABLE relay_churn_year (
    year DATE NOT NULL,
    ratio FLOAT NOT NULL
);

-- TABLE relay_statuses_per_day
-- A helper table which is commonly used to update the tables above in the
-- refresh_* functions.
CREATE TABLE relay_statuses_per_day (
    date DATE NOT NULL,
    count INTEGER NOT NULL
);

-- VIEW relay_statuses_per_day_v
-- This populates the above relay_statuses_per_day table.
CREATE VIEW relay_statuses_per_day_v AS
    SELECT DATE(validafter) AS date, COUNT(*) AS count
    FROM (SELECT DISTINCT validafter
          FROM statusentry) distinct_consensuses
    GROUP BY DATE(validafter);

-- TABLE updates
-- A helper table which is used to keep track of what tables and where need
-- to be updated upon refreshes.
CREATE TABLE updates (
    "date" date NOT NULL
);

ALTER TABLE ONLY descriptor
    ADD CONSTRAINT descriptor_pkey PRIMARY KEY (descriptor);

ALTER TABLE ONLY statusentry
    ADD CONSTRAINT statusentry_pkey PRIMARY KEY (validafter, descriptor);

ALTER TABLE ONLY bridge_stats
    ADD CONSTRAINT bridge_stats_pkey PRIMARY KEY (date);

ALTER TABLE ONLY torperf_stats
    ADD CONSTRAINT torperf_stats_pkey PRIMARY KEY (source, size, time);

ALTER TABLE gettor_stats
    ADD CONSTRAINT gettor_stats_pkey PRIMARY KEY(time, bundle);

ALTER TABLE network_size
    ADD CONSTRAINT network_size_pkey PRIMARY KEY(date);

ALTER TABLE relay_platforms
    ADD CONSTRAINT relay_platforms_pkey PRIMARY KEY(date);

ALTER TABLE relay_versions
    ADD CONSTRAINT relay_versions_pkey PRIMARY KEY(date);

ALTER TABLE total_bandwidth
    ADD CONSTRAINT total_bandwidth_pkey PRIMARY KEY(date);

ALTER TABLE platforms_uptime_month
    ADD CONSTRAINT platforms_uptime_month_pkey PRIMARY KEY(month);

ALTER TABLE relays_seen_week
    ADD CONSTRAINT relays_seen_week_pkey PRIMARY KEY(week, fingerprint);

ALTER TABLE relays_seen_month
    ADD CONSTRAINT relays_seen_month_pkey PRIMARY KEY(month, fingerprint);

ALTER TABLE relays_seen_year
    ADD CONSTRAINT relays_seen_year_pkey PRIMARY KEY(year, fingerprint);

ALTER TABLE relay_churn_week
    ADD CONSTRAINT relay_churn_week_pkey PRIMARY KEY(week);

ALTER TABLE relay_churn_month
    ADD CONSTRAINT relay_churn_month_pkey PRIMARY KEY(month);

ALTER TABLE relay_churn_year
    ADD CONSTRAINT relay_churn_year_pkey PRIMARY KEY(year);

ALTER TABLE updates
    ADD CONSTRAINT updates_pkey PRIMARY KEY(date);

CREATE INDEX descriptorid ON descriptor
    USING btree (descriptor);

CREATE INDEX statusentryid ON statusentry
    USING btree (descriptor, validafter);

CREATE LANGUAGE plpgsql;

-- FUNCTION update_status
-- This keeps the updates table up to date for the time graphs.
CREATE OR REPLACE FUNCTION update_status() RETURNS TRIGGER AS $$
    BEGIN
    IF (TG_OP='INSERT') THEN
        IF (SELECT COUNT(*) FROM updates
            WHERE DATE=DATE(new.validafter)) = 0 THEN
            INSERT INTO updates
            VALUES (DATE(NEW.validafter));
        END IF;
    ELSIF (TG_OP='DELETE') THEN
        IF (SELECT COUNT(*) FROM updates
            WHERE DATE=DATE(old.validafter)) = 0 THEN
            INSERT INTO updates
            VALUES (DATE(OLD.validafter));
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER update_status
-- This calls the function update_status() each time a row is inserted,
-- updated, or deleted from the updates table.
CREATE TRIGGER update_status
AFTER INSERT OR UPDATE OR DELETE
ON statusentry
    FOR EACH ROW EXECUTE PROCEDURE update_status();

-- refresh_* functions
-- The following functions keep their corresponding aggregate tables
-- up-to-date.  They should be called every time ERNIE is run, or when new
-- data is finished being added to the descriptor or statusentry tables.
-- They find what new data has been entered or updated based on the updates
-- table.

-- FUNCTION refresh_network_size()
CREATE OR REPLACE FUNCTION refresh_network_size() RETURNS INTEGER AS $$
    BEGIN
        --Insert any new dates, or blank dates--
        INSERT INTO network_size
        (date, avg_running, avg_exit, avg_guard)
        SELECT
              DATE(validafter) as date,
              COUNT(*) / relay_statuses_per_day.count AS avg_running,
              SUM(CASE WHEN isexit IS TRUE THEN 1 ELSE 0 END)
                  / relay_statuses_per_day.count AS avg_exit,
              SUM(CASE WHEN isguard IS TRUE THEN 1 ELSE 0 END)
                  / relay_statuses_per_day.count AS avg_guard
          FROM statusentry
          JOIN relay_statuses_per_day
          ON DATE(validafter) = relay_statuses_per_day.date
          WHERE DATE(validafter) = relay_statuses_per_day.date
              AND DATE(validafter) NOT IN
                  (SELECT DATE(date) FROM network_size)
          GROUP BY DATE(validafter), relay_statuses_per_day.count;

        --Update any new values that may have already
        --been inserted, but aren't complete.  based on the 'updates'
        --table.
        UPDATE network_size
        SET avg_running=new_ns.avg_running,
            avg_exit=new_ns.avg_exit,
            avg_guard=new_ns.avg_guard
        FROM (SELECT
                 DATE(validafter) as date,
                 COUNT(*) / relay_statuses_per_day.count AS avg_running,
                  SUM(CASE WHEN isexit IS TRUE THEN 1 ELSE 0 END)
                      / relay_statuses_per_day.count AS avg_exit,
                  SUM(CASE WHEN isguard IS TRUE THEN 1 ELSE 0 END)
                      / relay_statuses_per_day.count AS avg_guard
            FROM statusentry
            JOIN relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE DATE(validafter) IN (SELECT DISTINCT date FROM updates)
            GROUP BY DATE(validafter), relay_statuses_per_day.count)
                AS new_ns
       WHERE new_ns.date=network_size.date;
    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_relay_platforms()
CREATE OR REPLACE FUNCTION refresh_relay_platforms() RETURNS INTEGER AS $$
    BEGIN
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
    FROM descriptor LEFT JOIN statusentry
    On statusentry.descriptor = descriptor.descriptor
    JOIN relay_statuses_per_day
    ON DATE(validafter) = relay_statuses_per_day.date
    WHERE DATE(validafter) NOT IN (SELECT DATE(date) FROM relay_platforms)
    GROUP BY DATE(validafter), relay_statuses_per_day.count;

   UPDATE relay_platforms
   SET avg_linux=new_rp.avg_linux,
       avg_darwin=new_rp.avg_darwin,
       avg_windows=new_rp.avg_windows,
       avg_bsd=new_rp.avg_bsd,
       avg_other=new_rp.avg_other
   FROM (SELECT DATE(validafter),
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
        FROM descriptor LEFT JOIN statusentry
        ON statusentry.descriptor = descriptor.descriptor
        JOIN relay_statuses_per_day
        ON DATE(validafter) = relay_statuses_per_day.date
        WHERE DATE(validafter) IN (SELECT DISTINCT date FROM updates)
        GROUP BY DATE(validafter), relay_statuses_per_day.count) as new_rp
    WHERE new_rp.date=relay_platforms.date;
    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_relay_versions()
CREATE OR REPLACE FUNCTION refresh_relay_versions() RETURNS INTEGER AS $$
    BEGIN
    INSERT INTO relay_versions
    (date, "0.1.2", "0.2.0", "0.2.1", "0.2.2")
    SELECT DATE(validafter),
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.1.2' THEN 1 ELSE 0 END)
            / relay_statuses_per_day.count AS "0.1.2",
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.2.0' THEN 1 ELSE 0 END)
            /relay_statuses_per_day.count AS "0.2.0",
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.2.1' THEN 1 ELSE 0 END)
            /relay_statuses_per_day.count AS "0.2.1",
        SUM(CASE WHEN substring(platform, 5, 5)
            LIKE '0.2.2' THEN 1 ELSE 0 END)
            /relay_statuses_per_day.count AS "0.2.2"
    FROM descriptor LEFT JOIN statusentry
    ON descriptor.descriptor = statusentry.descriptor
    JOIN relay_statuses_per_day
    ON DATE(validafter) = relay_statuses_per_day.date
    WHERE DATE(validafter) NOT IN (SELECT DATE(date) FROM relay_versions)
    GROUP BY DATE(validafter), relay_statuses_per_day.count;

    UPDATE relay_versions
    SET "0.1.2"=new_rv."0.1.2",
        "0.2.0"=new_rv."0.2.0",
        "0.2.1"=new_rv."0.2.1",
        "0.2.2"=new_rv."0.2.2"
    FROM (SELECT DATE(validafter),
            SUM(CASE WHEN substring(platform, 5, 5)
                LIKE '0.1.2' THEN 1 ELSE 0 END)
                / relay_statuses_per_day.count AS "0.1.2",
            SUM(CASE WHEN substring(platform, 5, 5)
                LIKE '0.2.0' THEN 1 ELSE 0 END)
                /relay_statuses_per_day.count AS "0.2.0",
            SUM(CASE WHEN substring(platform, 5, 5)
                LIKE '0.2.1' THEN 1 ELSE 0 END)
                /relay_statuses_per_day.count AS "0.2.1",
            SUM(CASE WHEN substring(platform, 5, 5)
                LIKE '0.2.2' THEN 1 ELSE 0 END)
                /relay_statuses_per_day.count AS "0.2.2"
        FROM descriptor LEFT JOIN statusentry
        ON descriptor.descriptor = statusentry.descriptor
        JOIN relay_statuses_per_day
        ON DATE(validafter) = relay_statuses_per_day.date
        WHERE DATE(validafter) IN (SELECT DISTINCT date FROM updates)
        GROUP BY DATE(validafter), relay_statuses_per_day.count) AS new_rv
    WHERE new_rv.date=relay_versions.date;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_total_bandwidth()
-- This keeps the table total_bandwidth up-to-date when necessary.
CREATE OR REPLACE FUNCTION refresh_total_bandwidth() RETURNS INTEGER AS $$
    BEGIN
    INSERT INTO total_bandwidth
    (bwavg, bwburst, bwobserved, date)
    SELECT (SUM(bandwidthavg)
            / relay_statuses_per_day.count)::BIGINT AS bwavg,
        (SUM(bandwidthburst)
            / relay_statuses_per_day.count)::BIGINT AS bwburst,
        (SUM(bandwidthobserved)
            / relay_statuses_per_day.count)::BIGINT AS bwobserved,
        DATE(validafter)
    FROM descriptor LEFT JOIN statusentry
    ON descriptor.descriptor = statusentry.descriptor
    JOIN relay_statuses_per_day
    ON DATE(validafter) = relay_statuses_per_day.date
    WHERE DATE(validafter) NOT IN (SELECT date FROM total_bandwidth)
    GROUP BY DATE(validafter), relay_statuses_per_day.count;

    UPDATE total_bandwidth
    SET bwavg=new_tb.bwavg,
        bwburst=new_tb.bwburst,
        bwobserved=new_tb.bwobserved
    FROM (SELECT (SUM(bandwidthavg)
                / relay_statuses_per_day.count)::BIGINT AS bwavg,
            (SUM(bandwidthburst)
                / relay_statuses_per_day.count)::BIGINT AS bwburst,
            (SUM(bandwidthobserved)
                / relay_statuses_per_day.count)::BIGINT AS bwobserved,
            DATE(validafter)
        FROM descriptor LEFT JOIN statusentry
        ON descriptor.descriptor = statusentry.descriptor
        JOIN relay_statuses_per_day
        ON DATE(validafter) = relay_statuses_per_day.date
        WHERE DATE(validafter) IN (SELECT DISTINCT date FROM updates)
        GROUP BY DATE(validafter), relay_statuses_per_day.count) AS new_tb
    WHERE new_tb.date = total_bandwidth.date;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_churn
-- The churn tables find the percentage of relays from each
-- week/month/year that appear in the following week/month/year.
CREATE OR REPLACE FUNCTION refresh_churn()
RETURNS INTEGER AS $$
    BEGIN

    DELETE FROM relays_seen_week
    WHERE DATE(week) IN (SELECT * FROM updates);

    INSERT INTO
    relays_seen_week (fingerprint, week)
    SELECT DISTINCT fingerprint,
        DATE_TRUNC('week', validafter) AS week
    FROM descriptor LEFT JOIN statusentry
    ON descriptor.descriptor=statusentry.descriptor
    WHERE DATE_TRUNC('week', validafter) IN
        (SELECT DATE_TRUNC('week') FROM updates)
        AND DATE_TRUNC('week', validafter) IS NOT NULL
    GROUP BY 1, 2;

    DELETE FROM relays_seen_month
    WHERE DATE(month) IN (SELECT * FROM updates);

    INSERT INTO
    relays_seen_month (fingerprint, month)
    SELECT DISTINCT fingerprint,
        DATE_TRUNC('month', validafter) AS month
    FROM descriptor LEFT JOIN statusentry
    ON descriptor.descriptor=statusentry.descriptor
    WHERE DATE_TRUNC('month', validafter) IN
        (SELECT DATE_TRUNC('week') FROM updates)
        AND DATE_TRUNC('month', validafter) IS NOT NULL
    GROUP BY 1, 2;

    DELETE FROM relays_seen_year
    WHERE DATE(year) IN (SELECT * FROM updates);

    INSERT INTO
    relays_seen_year (year, fingerprint)
    SELECT DATE_TRUNC('year', validafter) AS year,
        DISTINCT fingerprint
    FROM descriptor LEFT JOIN statusentry
    ON descriptor.descriptor=statusentry.descriptor
    WHERE DATE_TRUNC('year', validafter) IN
        (SELECT DATE_TRUNC('week') FROM updates)
        AND DATE_TRUNC('year', validafter) IS NOT NULL
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

    DELETE FROM relay_churn_year;
    SELECT relays_seen_year.year,
        (churn.count::FLOAT/COUNT(DISTINCT fingerprint)::FLOAT) AS ratio
    FROM relays_seen_year
    JOIN ( SELECT COUNT(DISTINCT now.fingerprint) AS count, now.year
        FROM relays_seen_year now
        JOIN relays_seen_year future
        ON DATE(now.year)=DATE(future.year + interval '1 year')
        AND now.fingerprint=future.fingerprint
        GROUP BY 2) AS churn
    ON relays_seen_year.year=churn.year
    GROUP BY 1, churn.count;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- FUNCTION refresh_platforms_uptime_month()
CREATE OR REPLACE FUNCTION refresh_platforms_uptime_month()
RETURNS INTEGER AS $$
    BEGIN

    DELETE FROM platforms_uptime_month;
    INSERT INTO platforms_uptime_month (month,
        avg_windows,
        avg_darwin,
        avg_linux,
        avg_freebsd)
    SELECT avg_darwin.month,
           (avg_darwin.avg/3600)::INTEGER AS avgdarwin,
           (avg_windows.avg/3600)::INTEGER AS avgwindows,
           (avg_linux.avg/3600)::INTEGER AS avglinux,
           (avg_freebsd.avg/3600)::INTEGER AS avgfreebsd
    FROM (SELECT AVG(uniq_uptimes.avg) AS AVG,
              DATE(uniq_uptimes.pub) AS month
        FROM (SELECT AVG((CASE WHEN d.uptime IS NULL
                  THEN 0 ELSE d.uptime END)) AS avg,
              fingerprint,
              MAX(DATE_TRUNC('month', DATE(d.published))) AS PUB
          FROM descriptor d JOIN statusentry s
          ON d.descriptor=s.descriptor
          WHERE d.platform LIKE '%Windows%'
          GROUP BY d.fingerprint) AS uniq_uptimes
      GROUP BY DATE(uniq_uptimes.pub)) AS avg_windows
    JOIN (SELECT AVG(uniq_uptimes.avg) AS avg,
              DATE(uniq_uptimes.pub) AS month
        FROM (SELECT AVG((CASE WHEN d.uptime IS NULL
                  THEN 0 ELSE d.uptime END)) AS avg,
              fingerprint,
              MAX(DATE_TRUNC('month', DATE(d.published))) AS pub
          FROM descriptor d JOIN statusentry s
          ON d.descriptor=s.descriptor
          WHERE d.platform LIKE '%Darwin%'
          GROUP BY d.fingerprint) AS uniq_uptimes
        GROUP BY DATE(uniq_uptimes.pub)) AS avg_darwin
    ON avg_darwin.month=avg_windows.month
    JOIN (SELECT AVG(uniq_uptimes.avg) AS avg,
              DATE(uniq_uptimes.pub) AS month
        FROM (SELECT AVG((CASE WHEN d.uptime IS NULL
                  THEN 0 ELSE d.uptime END)) AS avg,
              fingerprint,
              MAX(DATE_TRUNC('month', DATE(d.published))) AS pub
          FROM descriptor d JOIN statusentry s
          ON d.descriptor=s.descriptor
          WHERE d.platform LIKE '%Linux%'
          GROUP BY d.fingerprint) AS uniq_uptimes
        GROUP BY DATE(uniq_uptimes.pub)) AS avg_linux
    ON avg_darwin.month=avg_linux.month
    JOIN (SELECT AVG(uniq_uptimes.avg) AS avg,
              DATE(uniq_uptimes.pub) AS month
        FROM (SELECT AVG((CASE WHEN d.uptime IS NULL
                  THEN 0 ELSE d.uptime END)) AS avg,
              fingerprint,
              MAX(DATE_TRUNC('month', DATE(d.published))) AS pub
          FROM descriptor d JOIN statusentry s
          ON d.descriptor=s.descriptor
          WHERE d.platform LIKE '%FreeBSD%'
          GROUP BY d.fingerprint) AS uniq_uptimes
        GROUP BY DATE(uniq_uptimes.pub)) AS avg_freebsd
    ON avg_freebsd.month=avg_linux.month and avg_darwin.month NOT IN
        (SELECT month FROM platforms_uptime_month);
    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

-- GRANT
GRANT INSERT, SELECT, UPDATE, DELETE
ON descriptor,
    statusentry,
    network_size,
    relay_platforms,
    relay_versions,
    total_bandwidth,
    bridge_stats,
    gettor_stats,
    torperf_stats,
    platforms_uptime_month,
    relays_seen_week,
    relays_seen_month,
    relays_seen_year,
    relay_churn_week,
    relay_churn_month,
    relay_churn_year,
    updates,
    relay_statuses_per_day
TO ernie;
