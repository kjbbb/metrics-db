#!/bin/bash
#Temporary test script for triggers and unnormalized data.
#Don't use this on the real database.

if [ $# != 2 ]; then
  echo "usage: $0 dbname dbuser"
  exit
fi
DB=$1
USER=$2

/usr/local/pgsql/bin/psql -A -t -q $DB $USER <<EOF
begin;
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
    isv3dir boolean DEFAULT false NOT NULL,
    PRIMARY KEY (validafter, descriptor)
);

--
--  descriptor-status: Unnormalized table containing both descriptors and
--  status entries in one big table.
--

CREATE TABLE descriptor_statusentry (
    descriptor character(40) NOT NULL,
    address character varying(15) NOT NULL,
    orport integer NOT NULL,
    dirport integer NOT NULL,
    bandwidthavg bigint NOT NULL,
    bandwidthburst bigint NOT NULL,
    bandwidthobserved bigint NOT NULL,
    platform character varying(256),
    published timestamp without time zone NOT NULL,
    uptime bigint,
    validafter timestamp without time zone NOT NULL,
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
    isv3dir boolean DEFAULT false NOT NULL,
    PRIMARY KEY (validafter, descriptor)
);

--
--mirror_ds() - TRIGGER
--We want the unnormalized table 'descriptor_status' to have any
--inserts to statusentry.
--
--TODO - Is there a better way to do this (without join, more succinct)?
--

CREATE LANGUAGE plpgsql;

CREATE FUNCTION mirror_ds() RETURNS TRIGGER AS \$mirror_ds\$
BEGIN
    INSERT INTO descriptor_statusentry (
        SELECT d.descriptor AS descriptor, d.address AS address,
               d.orport AS orport, d.dirport AS dirport,
               d.bandwidthavg AS bandwidthavg, d.bandwidthburst AS bandwidthburst,
               d.bandwidthobserved AS bandwidthobserved, d.platform AS platform,
               d.published AS published, d.uptime AS uptime, s.validafter
               AS validafter, s.isauthority AS isauthority, s.isbadexit AS
               isbadexit, s.isbaddirectory AS isbaddirectory, s.isexit AS
               isexit, s.isfASt AS isfASt, s.isguard AS isguard, s.ishsdir AS
               ishsdir, s.isnamed AS isnamed, s.isstable AS isstable,
               s.isrunning AS isrunning, s.isunnamed AS isunnamed,
               s.isvalid AS isvalid, s.isv2dir AS isv2dir, s.isv3dir
               AS isv3dir
        FROM descriptor d, statusentry s
        WHERE d.descriptor=s.descriptor
              AND d.descriptor=NEW.descriptor AND s.validafter=NEW.validafter
    );
RETURN NEW;
END;
\$mirror_ds\$ LANGUAGE plpgsql;

CREATE TRIGGER mirror_ds AFTER INSERT OR UPDATE ON statusentry
    FOR EACH ROW EXECUTE PROCEDURE mirror_ds();

--
--TEST QUERIES - To make sure data stays consistent.
--

insert into descriptor values ('ff0613a644c1406cc2ea42ef46a32ed572ed9386', '119.42.144.18',
                                9001, 0, 20480, 40960, 0, 'Tor 0.2.1.19 on Linux i686',
                                '2010-03-16 07:11:14', 10);
insert into statusentry values ('2010-03-19 15:00:00',
                                'ff0613a644c1406cc2ea42ef46a32ed572ed9386', 't', 'f', 'f',
                                'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f');
insert into statusentry values ('2010-03-20 16:00:00',
                                'ff0613a644c1406cc2ea42ef46a32ed572ed9386', 't', 'f', 'f',
                                'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f');
select * from descriptor;
select * from statusentry;
select * from descriptor_statusentry;
rollback;
EOF
