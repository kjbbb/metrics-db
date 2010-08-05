----MATVIEWREFRESH.SQL----
----This script should be run every time ernie is run to
----keep data sinks up to date.

CREATE LANGUAGE plpgsql

CREATE OR REPLACE FUNCTION refresh_network_size() AS $$
    DECLARE
        max_statusentry_date statusentry.validafter%TYPE;
        max_network_size_date network_size.date%TYPE;
    BEGIN

        SELECT DATE(MAX(validafter))
        INTO max_statusentry_date
        FROM statusentry
        LIMIT 1;

        SELECT DATE(MAX(date))
        INTO max_network_size_date
        FROM network_size
        LIMIT 1;

        IF max_statusentry_date - max_network_size_date > 0 THEN
            SELECT
                DATE(validafter),
                COUNT(*) / relay_statuses_per_day.count AS avg_running,
                SUM(CASE WHEN isexit IS TRUE THEN 1 ELSE 0 END)
                    / relay_statuses_per_day.count AS avg_exit,
                SUM(CASE WHEN isguard IS TRUE THEN 1 ELSE 0 END)
                    / relay_statuses_per_day.count AS avg_guard
            INTO network_size
            FROM statusentry
            JOIN (SELECT COUNT(*) AS count, DATE(validafter) AS date
                FROM (SELECT DISTINCT validafter FROM statusentry) distinct_consensuse
                GROUP BY DATE(validafter)) relay_statuses_per_day
            ON DATE(validafter) = relay_statuses_per_day.date
            WHERE DATE(validafter) = relay_statuses_per_day.date
                AND DATE(validafter) > max_network_size_date
            GROUP BY DATE(validafter), relay_statuses_per_day.count
        END IF;
        RETURN;
    END;
$$ LANGUAGE plpgsql
