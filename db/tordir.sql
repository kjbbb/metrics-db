SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

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

--TABLE descriptor_statusentry: Unnormalized table containing both descriptors and
--status entries in one big table.
CREATE TABLE descriptor_statusentry (
    descriptor character(40) NOT NULL,
    address character varying(15),
    orport integer,
    dirport integer,
    bandwidthavg bigint,
    bandwidthburst bigint,
    bandwidthobserved bigint,
    platform character varying(256),
    published timestamp without time zone,
    uptime bigint,
    validafter timestamp without time zone,
    isauthority boolean DEFAULT false,
    isbadexit boolean DEFAULT false,
    isbaddirectory boolean DEFAULT false,
    isexit boolean DEFAULT false,
    isfast boolean DEFAULT false,
    isguard boolean DEFAULT false,
    ishsdir boolean DEFAULT false,
    isnamed boolean DEFAULT false,
    isstable boolean DEFAULT false,
    isrunning boolean DEFAULT false,
    isunnamed boolean DEFAULT false,
    isvalid boolean DEFAULT false,
    isv2dir boolean DEFAULT false,
    isv3dir boolean DEFAULT false
);

CREATE TABLE bridge_stats (
    validafter timestamp without time zone not null,
    bh float,
    cn float,
    cu float,
    et float,
    ir float,
    mm float,
    sa float,
    sy float,
    tm float,
    tn float,
    uz float,
    vn float,
    ye float
);

CREATE TABLE torperf_stats (
    source character varying(32) NOT NULL,
    time timestamp without time zone NOT NULL,
    size character varying(8) NOT NULL,
    q1 integer NOT NULL,
    md integer NOT NULL,
    q3 integer NOT NULL
);

CREATE TABLE gettor_stats (
    time timestamp without time zone NOT NULL,
    bundle character varying(32) NOT NULL,
    count integer NOT NULL
);

CREATE TABLE network_size (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    avg_running INTEGER NOT NULL,
    avg_exit INTEGER NOT NULL,
    avg_guard INTEGER NOT NULL
);

CREATE TABLE updates (
    "date" date NOT NULL
);

CREATE TABLE relay_platforms (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    avg_linux INTEGER NOT NULL,
    avg_darwin INTEGER NOT NULL,
    avg_bsd INTEGER NOT NULL,
    avg_windows INTEGER NOT NULL,
    avg_other INTEGER NOT NULL
);

CREATE TABLE relay_versions (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    "0.1.2" INTEGER NOT NULL,
    "0.2.0" INTEGER NOT NULL,
    "0.2.1" INTEGER NOT NULL,
    "0.2.2" INTEGER NOT NULL
);

CREATE TABLE relay_bandwidth (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    bwavg BIGINT NOT NULL,
    bwburst BIGINT NOT NULL,
    bwobserved BIGINT NOT NULL
);

CREATE TABLE total_bandwidth (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    bwavg BIGINT NOT NULL,
    bwburst BIGINT NOT NULL,
    bwobserved BIGINT NOT NULL
);

CREATE TABLE platforms_uptime_month (
    month date NOT NULL,
    avg_windows INTEGER NOT NULL,
    avg_darwin INTEGER NOT NULL,
    avg_linux INTEGER NOT NULL,
    avg_freebsd INTEGER NOT NULL
);

ALTER TABLE ONLY descriptor
    ADD CONSTRAINT descriptor_pkey PRIMARY KEY (descriptor);

ALTER TABLE ONLY statusentry
    ADD CONSTRAINT statusentry_pkey PRIMARY KEY (validafter, descriptor);

ALTER TABLE ONLY bridge_stats
    ADD CONSTRAINT bridge_stats_pkey PRIMARY KEY (validafter);

ALTER TABLE ONLY torperf_stats
    ADD CONSTRAINT torperf_stats_pkey PRIMARY KEY (source, size, time);

ALTER TABLE gettor_stats
    ADD CONSTRAINT gettor_stats_pkey PRIMARY KEY(time, bundle);

ALTER TABLE platforms_uptime_month
    ADD CONSTRAINT platforms_uptime_month_pkey PRIMARY KEY(month);

ALTER TABLE relay_platforms
    ADD CONSTRAINT relay_platforms_pkey PRIMARY KEY(date);

ALTER TABLE relay_versions
    ADD CONSTRAINT relay_versions PRIMARY KEY(date);

ALTER TABLE total_bandwidth
    ADD CONSTRAINT total_bandwidth PRIMARY KEY(date);

CREATE INDEX descriptorid ON descriptor USING btree (descriptor);
CREATE INDEX statusentryid ON statusentry USING btree (descriptor, validafter);
CREATE INDEX descriptorstatusid ON descriptor_statusentry USING btree (descriptor, validafter);

CREATE LANGUAGE plpgsql;

--TRIGGER mirror_statusentry()
--Reflect any changes to statusentry in descriptor_statusentry
CREATE FUNCTION mirror_statusentry() RETURNS TRIGGER AS $mirror_statusentry$
    DECLARE
        rd descriptor%ROWTYPE;
    BEGIN
        IF (TG_OP = 'INSERT') THEN
            SELECT * INTO rd FROM descriptor WHERE descriptor=NEW.descriptor;
            INSERT INTO descriptor_statusentry
            VALUES (new.descriptor, rd.address, rd.orport, rd.dirport,
                    rd.bandwidthavg, rd.bandwidthburst, rd.bandwidthobserved,
                    rd.platform, rd.published, rd.uptime, new.validafter,
                    new.isauthority, new.isbadexit, new.isbaddirectory,
                    new.isexit, new.isfast, new.isguard, new.ishsdir,
                    new.isnamed, new.isstable, new.isrunning, new.isunnamed,
                    new.isvalid, new.isv2dir, new.isv3dir);

            DELETE FROM descriptor_statusentry
            WHERE descriptor=NEW.descriptor AND validafter IS NULL;

        ELSIF (TG_OP = 'UPDATE') THEN
            UPDATE descriptor_statusentry
            SET isauthority=NEW.isauthority,
                isbadexit=NEW.isbadexit, isbaddirectory=NEW.isbaddirectory,
                isexit=NEW.isexit, isfast=NEW.isfast, isguard=NEW.isguard,
                ishsdir=NEW.ishsdir, isnamed=NEW.isnamed, isstable=NEW.isstable,
                isrunning=NEW.isrunning, isunnamed=NEW.isunnamed,
                isvalid=NEW.isvalid, isv2dir=NEW.isv2dir, isv3dir=NEW.isv3dir
            WHERE descriptor=NEW.descriptor AND validafter=NEW.validafter;
        ELSIF (TG_OP = 'DELETE') THEN
            DELETE FROM descriptor_statusentry
            WHERE validafter=OLD.validafter AND descriptor=OLD.descriptor;
        END IF;
    RETURN NEW;
END;
$mirror_statusentry$ LANGUAGE plpgsql;

--FUNCTION mirror_descriptor
--Reflect changes in descriptor_statusentry when changes made to descriptor table
CREATE FUNCTION mirror_descriptor() RETURNS TRIGGER AS $mirror_descriptor$
    DECLARE
        dcount INTEGER;
    BEGIN
        IF (TG_OP = 'INSERT') THEN
            SELECT COUNT(*) INTO dcount
            FROM descriptor_statusentry
            WHERE descriptor=NEW.descriptor AND validafter IS NOT NULL;

            IF (dcount = 0) THEN
                INSERT INTO descriptor_statusentry VALUES (
                    NEW.descriptor, NEW.address, NEW.orport, NEW.dirport, NEW.bandwidthavg,
                    NEW.bandwidthburst, NEW.bandwidthobserved, NEW.platform, NEW.published,
                    NEW.uptime, null, null, null, null, null, null, null, null, null, null,
                    null, null, null, null, null);
            ELSE
                UPDATE descriptor_statusentry
                SET address=NEW.address, orport=NEW.orport, dirport=NEW.dirport,
                    bandwidthavg=NEW.bandwidthavg, bandwidthburst=NEW.bandwidthburst,
                    bandwidthobserved=NEW.bandwidthobserved, platform=NEW.platform,
                    published=NEW.published, uptime=NEW.uptime
                WHERE descriptor=NEW.descriptor;
            END IF;
        ELSIF (TG_OP = 'UPDATE') THEN
            UPDATE descriptor_statusentry
            SET address=NEW.address, orport=NEW.orport, dirport=NEW.dirport,
                bandwidthavg=NEW.bandwidthavg, bandwidthburst=NEW.bandwidthburst,
                bandwidthobserved=NEW.bandwidthobserved, platform=NEW.platform,
                published=NEW.published, uptime=NEW.uptime
            WHERE descriptor=NEW.descriptor;
        ELSIF (TG_OP = 'DELETE') THEN
        END IF;
    RETURN NEW;
END;
$mirror_descriptor$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_status() RETURNS TRIGGER AS $$
    BEGIN
        IF (SELECT COUNT(*)
            FROM updates
            WHERE date = DATE(NEW.validafter) = 0) THEN
            INSERT INTO updates
            VALUES (DATE(NEW.validafter));
        END IF;
    RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER mirror_statusentry AFTER INSERT OR UPDATE OR DELETE ON statusentry
    FOR EACH ROW EXECUTE PROCEDURE mirror_statusentry();

CREATE TRIGGER mirror_descriptor AFTER INSERT OR UPDATE OR DELETE ON descriptor
    FOR EACH ROW EXECUTE PROCEDURE mirror_descriptor();

CREATE TRIGGER update_status AFTER INSERT OR UPDATE ON statusentry
    FOR EACH ROW EXECUTE PROCEDURE update_status();

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
          JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
              FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
              GROUP BY DATE(validafter)) relay_statuses_per_day
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
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE DATE(validafter) IN (SELECT DISTINCT date FROM updates)
            GROUP BY DATE(validafter), relay_statuses_per_day.count) as new_ns
       WHERE new_ns.date=network_size.date;
    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

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
    JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
            FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuse
            GROUP BY DATE(validafter)) relay_statuses_per_day
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
        JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuse
                GROUP BY DATE(validafter)) relay_statuses_per_day
        ON DATE(validafter) = relay_statuses_per_day.date
        WHERE DATE(validafter) IN (SELECT DISTINCT date FROM updates)
        GROUP BY DATE(validafter), relay_statuses_per_day.count) as new_rp
    WHERE new_rp.date=relay_platforms.date;
    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION refresh_relay_versions() RETURNS INTEGER AS $$
    BEGIN
    INSERT INTO relay_versions
    (date, "0.1.2", "0.2.0", "0.2.1", "0.2.2")
    SELECT DATE(validafter),
        SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.1.2' THEN 1 ELSE 0 END)
            / relay_statuses_per_day.count AS "0.1.2",
        SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.2.0' THEN 1 ELSE 0 END)
            /relay_statuses_per_day.count AS "0.2.0",
        SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.2.1' THEN 1 ELSE 0 END)
            /relay_statuses_per_day.count AS "0.2.1",
        SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.2.2' THEN 1 ELSE 0 END)
            /relay_statuses_per_day.count AS "0.2.2"
    FROM descriptor LEFT JOIN statusentry
    ON descriptor.descriptor = statusentry.descriptor
    JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
            FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
            GROUP BY DATE(validafter)) relay_statuses_per_day
    ON DATE(validafter) = relay_statuses_per_day.date
    WHERE DATE(validafter) NOT IN (SELECT DATE(date) FROM relay_versions)
    GROUP BY DATE(validafter), relay_statuses_per_day.count;

    UPDATE relay_versions
    SET "0.1.2"=new_rv."0.1.2",
        "0.2.0"=new_rv."0.2.0",
        "0.2.1"=new_rv."0.2.1",
        "0.2.2"=new_rv."0.2.2"
    FROM (SELECT DATE(validafter),
            SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.1.2' THEN 1 ELSE 0 END)
                / relay_statuses_per_day.count AS "0.1.2",
            SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.2.0' THEN 1 ELSE 0 END)
                /relay_statuses_per_day.count AS "0.2.0",
            SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.2.1' THEN 1 ELSE 0 END)
                /relay_statuses_per_day.count AS "0.2.1",
            SUM(CASE WHEN substring(platform, 5, 5) LIKE '0.2.2' THEN 1 ELSE 0 END)
                /relay_statuses_per_day.count AS "0.2.2"
        FROM descriptor LEFT JOIN statusentry
        ON descriptor.descriptor = statusentry.descriptor
        JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                GROUP BY DATE(validafter)) relay_statuses_per_day
        ON DATE(validafter) = relay_statuses_per_day.date
        WHERE DATE(validafter) IN (SELECT DISTINCT date FROM updates)
        GROUP BY DATE(validafter), relay_statuses_per_day.count) as new_rv
    WHERE new_rv.date=relay_versions.date;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

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
    JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                GROUP BY DATE(validafter)) relay_statuses_per_day
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
        JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                    FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                    GROUP BY DATE(validafter)) relay_statuses_per_day
        ON DATE(validafter) = relay_statuses_per_day.date
        WHERE DATE(validafter) IN (SELECT DISTINCT date FROM updates)
        GROUP BY DATE(validafter), relay_statuses_per_day.count) as new_tb
    WHERE new_tb.date = total_bandwidth.date;

    RETURN 1;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION refresh_platforms_uptime_month() RETURNS INTEGER AS $$
    BEGIN
    INSERT INTO platforms_uptime_month (month,
        avg_windows,
        avg_darwin,
        avg_linux,
        avg_freebsd)
    SELECT avg_darwin.month, avg_darwin.avg::INTEGER AS avgdarwin,
        avg_windows.avg::INTEGER AS avgwindows, avg_linux.avg::INTEGER AS avglinux,
        avg_freebsd.avg::INTEGER AS avgfreebsd
    FROM (SELECT AVG(uniq_uptimes.avg)/3600 AS AVG, DATE(uniq_uptimes.pub) AS month
      FROM (SELECT AVG((CASE WHEN d.uptime IS NULL THEN 0 ELSE d.uptime END)) AS avg,
            fingerprint, MAX(DATE_TRUNC('month', DATE(d.published))) AS PUB
        FROM descriptor d JOIN statusentry s
        ON d.descriptor=s.descriptor
        WHERE d.platform LIKE '%Windows%'
        GROUP BY d.fingerprint) AS uniq_uptimes
      GROUP BY DATE(uniq_uptimes.pub)) AS avg_windows
    JOIN (SELECT AVG(uniq_uptimes.avg)/3600 AS avg, DATE(uniq_uptimes.pub) AS month
      FROM (SELECT AVG((CASE WHEN d.uptime IS NULL THEN 0 ELSE d.uptime END)) AS avg,
            fingerprint, MAX(DATE_TRUNC('month', DATE(d.published))) AS pub
        FROM descriptor d JOIN statusentry s
        ON d.descriptor=s.descriptor
        WHERE d.platform LIKE '%Darwin%'
        GROUP BY d.fingerprint) AS uniq_uptimes
      GROUP BY DATE(uniq_uptimes.pub)) AS avg_darwin
    ON avg_darwin.month=avg_windows.month
    JOIN (SELECT AVG(uniq_uptimes.avg)/3600 AS avg, DATE(uniq_uptimes.pub) AS month
      FROM (SELECT AVG((CASE WHEN d.uptime IS NULL THEN 0 ELSE d.uptime END)) AS avg,
            fingerprint, MAX(DATE_TRUNC('month', DATE(d.published))) AS pub
        FROM descriptor d JOIN statusentry s
        ON d.descriptor=s.descriptor
        WHERE d.platform LIKE '%Linux%'
        GROUP BY d.fingerprint) AS uniq_uptimes
      GROUP BY DATE(uniq_uptimes.pub)) AS avg_linux
    ON avg_darwin.month=avg_linux.month
    JOIN (SELECT AVG(uniq_uptimes.avg)/3600 AS avg, DATE(uniq_uptimes.pub) AS month
      FROM (SELECT AVG((CASE WHEN d.uptime IS NULL THEN 0 ELSE d.uptime END)) AS avg,
            fingerprint, MAX(DATE_TRUNC('month', DATE(d.published))) AS pub
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

GRANT INSERT, SELECT, UPDATE, DELETE
ON descriptor, statusentry, descriptor_statusentry,
    network_size, relay_platforms, relay_versions, relay_uptime,
    relay_bandwidth, total_bandwidth, bridge_stats, gettor_stats,
    torperf_stats, platforms_uptime_month
TO ernie;
