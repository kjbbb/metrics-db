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

ALTER TABLE ONLY descriptor
    ADD CONSTRAINT descriptor_pkey PRIMARY KEY (descriptor);

ALTER TABLE ONLY statusentry
    ADD CONSTRAINT statusentry_pkey PRIMARY KEY (validafter, descriptor);

--ALTER TABLE ONLY descriptor_statusentry
--    ADD CONSTRAINT descriptor_statusentry_pkey PRIMARY KEY (validafter, descriptor);

ALTER TABLE ONLY bridge_stats
    ADD CONSTRAINT bridge_stats_pkey PRIMARY KEY (validafter);

ALTER TABLE ONLY torperf_stats
    ADD CONSTRAINT torperf_stats_pkey PRIMARY KEY (source, size, time);

ALTER TABLE gettor_stats
    ADD CONSTRAINT gettor_stats_pkey PRIMARY KEY(time, bundle);

CREATE INDEX descriptorid ON descriptor USING btree (descriptor);
CREATE INDEX statusentryid ON statusentry USING btree (descriptor, validafter);
CREATE INDEX descriptorstatusid ON descriptor_statusentry USING btree (descriptor, validafter);
CREATE INDEX bridgestatsid ON bridge_stats USING btree (validafter);
CREATE INDEX torperfstatsid ON torperf_stats USING btree (time);
CREATE INDEX gettorstatsid ON gettor_stats USING btree (time);

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
    '0.1.2' INTEGER NOT NULL,
    '0.2.0' INTEGER NOT NULL,
    '0.2.1' INTEGER NOT NULL,
    '0.2.2' INTEGER NOT NULL
);

CREATE TABLE relay_uptime (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    uptime INTEGER NOT NULL,
    stddev INTEGER NOT NULL
);

CREATE TABLE relay_bandwidth (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    bwavg INTEGER NOT NULL,
    bwburst INTEGER NOT NULL,
    bwobserved INTEGER NOT NULL
);

CREATE TABLE total_bandwidth (
    date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    bwavg INTEGER NOT NULL,
    bwburst INTEGER NOT NULL,
    bwobserved INTEGER NOT NULL
);
