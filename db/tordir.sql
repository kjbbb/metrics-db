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

ALTER TABLE ONLY descriptor
    ADD CONSTRAINT descriptor_pkey PRIMARY KEY (descriptor);

ALTER TABLE ONLY statusentry
    ADD CONSTRAINT statusentry_pkey PRIMARY KEY (validafter, descriptor);

--ALTER TABLE ONLY descriptor_statusentry
--    ADD CONSTRAINT descriptor_statusentry_pkey PRIMARY KEY (validafter, descriptor);

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

CREATE TRIGGER mirror_statusentry AFTER INSERT OR UPDATE OR DELETE ON statusentry
    FOR EACH ROW EXECUTE PROCEDURE mirror_statusentry();

CREATE TRIGGER mirror_descriptor AFTER INSERT OR UPDATE OR DELETE ON descriptor
    FOR EACH ROW EXECUTE PROCEDURE mirror_descriptor();

CREATE TABLE network_size (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    avg_running INTEGER NOT NULL,
    avg_exit INTEGER NOT NULL,
    avg_guard INTEGER NOT NULL
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

CREATE TABLE relay_uptime (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    uptime INTEGER NOT NULL,
    stddev INTEGER NOT NULL
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

CREATE OR REPLACE FUNCTION refresh_network_size() RETURNS INTEGER AS $$
    DECLARE
        max_statusentry_time statusentry.validafter%TYPE;
        max_network_size_time network_size.date%TYPE;
    BEGIN

        SELECT MAX(validafter)
        INTO max_statusentry_time
        FROM statusentry;

        SELECT MAX(date)
        INTO max_network_size_time
        FROM network_size;

        IF max_network_size_time IS NULL THEN
            max_network_size_time := date '1970-01-01';
        END IF;

        --If the difference in time from the latest status entry and aggregated
        --network size table is greater than an hour, then recreate data from
        --that day, or create a new day.
        IF EXTRACT('epoch' from (max_statusentry_time - max_network_size_time))/3600 > 0 THEN
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
                AND DATE(validafter) > max_network_size_time
            GROUP BY DATE(validafter), relay_statuses_per_day.count;
        END IF;
        RETURN 1;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION refresh_relay_platforms() RETURNS INTEGER AS $$
    DECLARE
        max_statusentry_time statusentry.validafter%TYPE;
        max_relay_platforms_time relay_platforms.date%TYPE;
    BEGIN

        SELECT MAX(validafter)
        INTO max_statusentry_time
        FROM statusentry;

        SELECT MAX(date)
        INTO max_relay_platforms_time
        FROM relay_platforms;

        IF max_relay_platforms_time IS NULL THEN
            max_relay_platforms_time := date '1970-01-01';
        END IF;

        IF EXTRACT('epoch' from (max_statusentry_time - max_relay_platforms_time))/3600 > 0 THEN
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
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                    FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuse
                    GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE DATE(validafter) > max_relay_platforms_time
            GROUP BY DATE(validafter), relay_statuses_per_day.count;
        END IF;
        RETURN 1;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION refresh_relay_versions() RETURNS INTEGER AS $$
    DECLARE
        max_statusentry_time statusentry.validafter%TYPE;
        max_relay_versions_time relay_versions.date%TYPE;
    BEGIN

        SELECT MAX(validafter)
        INTO max_statusentry_time
        FROM statusentry;

        SELECT MAX(date)
        INTO max_relay_versions_time
        FROM relay_versions;

        IF max_relay_versions_time IS NULL THEN
            max_relay_versions_time := date '1970-01-01';
        END IF;

        IF EXTRACT('epoch' from (max_statusentry_time - max_relay_versions_time))/3600 > 0 THEN
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
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                    FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                    GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE DATE(validafter) > max_relay_versions_time
            GROUP BY DATE(validafter), relay_statuses_per_day.count;
        END IF;
        RETURN 1;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION refresh_relay_uptime() RETURNS INTEGER AS $$
    DECLARE
        max_statusentry_time statusentry.validafter%TYPE;
        max_relay_uptime_time relay_uptime.date%TYPE;
    BEGIN

        SELECT MAX(validafter)
        INTO max_statusentry_time
        FROM statusentry;

        SELECT MAX(date)
        INTO max_relay_uptime_time
        FROM relay_uptime;

        IF max_relay_uptime_time IS NULL THEN
            max_relay_uptime_time := date '1970-01-01';
        END IF;

        IF EXTRACT('epoch' from (max_statusentry_time - max_relay_uptime_time))/3600 > 0 THEN
            INSERT INTO relay_uptime
            (uptime, stddev, date)
            SELECT (AVG(uptime) / relay_statuses_per_day.count)::INT AS uptime,
                (STDDEV(uptime) / relay_statuses_per_day.count)::INT AS stddev,
                DATE(validafter)
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE validafter IS NOT NULL
                AND DATE(validafter) > max_relay_uptime_time
            GROUP BY DATE(validafter), relay_statuses_per_day.count;
        END IF;
        RETURN 1;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION refresh_relay_bandwidth() RETURNS INTEGER AS $$
    DECLARE
        max_statusentry_time statusentry.validafter%TYPE;
        max_relay_bandwidth_time relay_bandwidth.date%TYPE;
    BEGIN

        SELECT DATE(MAX(validafter))
        INTO max_statusentry_time
        FROM statusentry;

        SELECT DATE(MAX(date))
        INTO max_relay_bandwidth_time
        FROM relay_bandwidth;

        IF max_relay_bandwidth_time IS NULL THEN
            max_relay_bandwidth_time := date '1970-01-01';
        END IF;

        IF EXTRACT('epoch' from (max_statusentry_time - max_relay_bandwidth_time))/3600 > 0 THEN
            INSERT INTO relay_bandwidth
            (bwavg, bwburst, bwobserved, date)
            SELECT (AVG(bandwidthavg)
                    / relay_statuses_per_day.count)::INT AS bwavg,
                (AVG(bandwidthburst)
                    / relay_statuses_per_day.count)::INT AS bwburst,
                (AVG(bandwidthobserved)
                    / relay_statuses_per_day.count)::INT AS bwobserved,
                DATE(validafter)
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                        FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                        GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE validafter IS NOT NULL
                AND DATE(validafter) > max_relay_bandwidth_time
            GROUP BY DATE(validafter), relay_statuses_per_day.count;
        END IF;
        RETURN 1;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION refresh_total_bandwidth() RETURNS INTEGER AS $$
    DECLARE
        max_statusentry_time statusentry.validafter%TYPE;
        max_total_bandwidth_time total_bandwidth.date%TYPE;
    BEGIN

        SELECT DATE(MAX(validafter))
        INTO max_statusentry_time
        FROM statusentry;

        SELECT DATE(MAX(date))
        INTO max_total_bandwidth_time
        FROM total_bandwidth;

        IF max_total_bandwidth_time IS NULL THEN
            max_total_bandwidth_time := date '1970-01-01';
        END IF;

        IF EXTRACT('epoch' from (max_statusentry_time - max_total_bandwidth_time))/3600 > 0 THEN
            INSERT INTO total_bandwidth
            (bwavg, bwburst, bwobserved, date)
            SELECT (SUM(bandwidthavg)
                    / relay_statuses_per_day.count)::BIGINT AS bwavg,
                (SUM(bandwidthburst)
                    / relay_statuses_per_day.count)::BIGINT AS bwburst,
                (SUM(bandwidthobserved)
                    / relay_statuses_per_day.count)::BIGINT AS bwobserved,
                DATE(validafter)
            FROM descriptor_statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                        FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuses
                        GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE validafter IS NOT NULL
                AND DATE(validafter) > max_total_bandwidth_time
            GROUP BY DATE(validafter), relay_statuses_per_day.count;
        END IF;
        RETURN 1;
    END;
$$ LANGUAGE plpgsql;

CREATE VIEW platforms_uptime_month_v AS
    SELECT avg_darwin.month, avg_darwin.avg::INTEGER AS avgdarwin,
        avg_windows.avg::INTEGER AS avgwindows, avg_linux.avg::INTEGER AS avglinux,
        avg_freebsd.avg::INTEGER AS avgfreebsd
    FROM (SELECT AVG(uniq_uptimes.avg)/3600 AS AVG, DATE(uniq_uptimes.pub) AS MONTh
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
        WHERE d.platform LIKE '%Linux%'
        GROUP BY d.fingerprint) AS uniq_uptimes
      GROUP BY DATE(uniq_uptimes.pub)) AS avg_freebsd
    ON avg_freebsd.month=avg_linux.month;

GRANT INSERT, SELECT, UPDATE, DELETE
ON descriptor, statusentry, descriptor_statusentry,
    network_size, relay_platforms, relay_versions, relay_uptime,
    relay_bandwidth, total_bandwidth, bridge_stats, gettor_stats,
    torperf_stats
TO ernie;
