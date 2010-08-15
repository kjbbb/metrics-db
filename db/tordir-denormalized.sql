-- Denormalization is a data warehousing technique to speed
-- up queries on very large data sets to avoid joins. This script will
-- keep a denormalized table through row-level triggers. Keep in mind
-- that inserts with this technique will be slow. A similar end-result
-- could be achieved by creating a denormalized table after all of the
-- inserts, and populating it by doing something like:
--
-- SELECT *
-- INTO descriptor_statusentry
-- FROM descriptor LEFT JOIN statusentry
-- ON descriptor.descriptor=statusentry.descriptor

-- TABLE descriptor_statusentry: Denormalized table containing both
-- descriptors and status entries in one big table. The table
-- reflects a left join of descriptor on statusentry.

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

CREATE INDEX descriptorstatusid ON descriptor_statusentry
    USING btree (descriptor, validafter);

--TRIGGER mirror_statusentry()
--Reflect any changes to statusentry in descriptor_statusentry
CREATE FUNCTION mirror_statusentry() RETURNS TRIGGER
AS $mirror_statusentry$
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
            ishsdir=NEW.ishsdir, isnamed=NEW.isnamed,
            isstable=NEW.isstable,isrunning=NEW.isrunning,
            isunnamed=NEW.isunnamed, isvalid=NEW.isvalid,
            isv2dir=NEW.isv2dir, isv3dir=NEW.isv3dir
        WHERE descriptor=NEW.descriptor AND validafter=NEW.validafter;
    ELSIF (TG_OP = 'DELETE') THEN
        DELETE FROM descriptor_statusentry
        WHERE validafter=OLD.validafter AND descriptor=OLD.descriptor;
    END IF;
    RETURN NEW;
END;
$mirror_statusentry$ LANGUAGE plpgsql;

--Reflect changes in descriptor_statusentry when changes are made to
--the descriptor table
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
                NEW.descriptor, NEW.address, NEW.orport, NEW.dirport,
                NEW.bandwidthavg, NEW.bandwidthburst,
                NEW.bandwidthobserved, NEW.platform, NEW.published,
                NEW.uptime, null, null, null, null, null, null, null,
                null, null, null, null, null, null, null, null);
        ELSE
            UPDATE descriptor_statusentry
            SET address=NEW.address, orport=NEW.orport,
                dirport=NEW.dirport, bandwidthavg=NEW.bandwidthavg,
                bandwidthburst=NEW.bandwidthburst,
                bandwidthobserved=NEW.bandwidthobserved,
                platform=NEW.platform, published=NEW.published,
                uptime=NEW.uptime
            WHERE descriptor=NEW.descriptor;
        END IF;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE descriptor_statusentry
        SET address=NEW.address, orport=NEW.orport, dirport=NEW.dirport,
            bandwidthavg=NEW.bandwidthavg,
            bandwidthburst=NEW.bandwidthburst,
            bandwidthobserved=NEW.bandwidthobserved,
            platform=NEW.platform, published=NEW.published,
            uptime=NEW.uptime
        WHERE descriptor=NEW.descriptor;
    ELSIF (TG_OP = 'DELETE') THEN
    END IF;
    RETURN NEW;
END;
$mirror_descriptor$ LANGUAGE plpgsql;

CREATE TRIGGER mirror_statusentry
AFTER INSERT OR UPDATE OR DELETE
ON statusentry
    FOR EACH ROW EXECUTE PROCEDURE mirror_statusentry();

CREATE TRIGGER mirror_descriptor
AFTER INSERT OR UPDATE OR DELETE
ON descriptor
    FOR EACH ROW EXECUTE PROCEDURE mirror_descriptor();
