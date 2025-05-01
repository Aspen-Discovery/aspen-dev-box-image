-- Temp table to try to avoid creating invalid records (>99999 chars) because of high 852-field counts
-- Change to suit
\set copy_limit 300

CREATE TEMPORARY TABLE aspen_many_copies AS 
    SELECT acn.record, COUNT(acp.id) AS acp_count
    FROM asset.copy acp
    JOIN asset.call_number acn ON acn.id = acp.call_number
    JOIN asset.copy_location acpl ON acpl.id = acp.location
    JOIN config.copy_status ccs ON ccs.id = acp.status
    WHERE NOT acp.deleted AND NOT acn.deleted
    AND acn.record IN (SELECT id FROM biblio.record_entry WHERE NOT deleted)
    AND acn.record != -1
    AND acn.owning_lib IN (SELECT id FROM actor.org_unit WHERE opac_visible)
    AND acp.opac_visible
    AND acpl.opac_visible
    AND ccs.opac_visible
    GROUP BY 1
    HAVING COUNT(acp.id) >= :'copy_limit'
;

-- Extract the id lists

\o marcxml.ids
SELECT DISTINCT record FROM aspen_many_copies ORDER BY record;

-- NOTE: When changing this or the all_bib.ids extract in incremental.sql make sure that
-- everything from 'SELECT DISTINCT' through ') bibs' matches!
\o marc21.ids
SELECT DISTINCT id FROM (
    SELECT
        id
    FROM
        biblio.record_entry
    WHERE
        id <> -1
        AND NOT deleted
        AND id IN (
            SELECT DISTINCT record FROM asset.call_number WHERE id IN (
                SELECT DISTINCT call_number
                FROM asset.copy acp
                JOIN asset.copy_location acpl ON (acp.location = acpl.id)
                JOIN config.copy_status ccs ON (acp.status = ccs.id)
                WHERE NOT acp.deleted
                AND   acp.opac_visible
                AND   acpl.opac_visible
                AND   ccs.opac_visible
           ) AND owning_lib IN (
                SELECT id FROM actor.org_unit WHERE opac_visible
           )
        )
) bibs
-- This where clause should only be here, not in incremental.sql
WHERE id NOT IN (SELECT record FROM aspen_many_copies)
ORDER BY id;

