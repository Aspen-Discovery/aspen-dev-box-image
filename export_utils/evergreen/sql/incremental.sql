-- Change to suit, note that you need to schedule the cron job to match
\set edit_int '10 minutes'

\o incremental_changes.ids
SELECT DISTINCT id FROM (
    -- bre edits
    SELECT
        id
    FROM
        biblio.record_entry
    WHERE
        id <> -1
        AND NOT deleted
        AND edit_date > NOW() - :'edit_int'::INTERVAL
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

UNION ALL

    -- acn edits
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
            AND edit_date  > NOW() - :'edit_int'::INTERVAL
        )

UNION ALL

    -- acp edits
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
                  AND   edit_date  > NOW() - :'edit_int'::INTERVAL
            ) AND owning_lib IN (
                SELECT id FROM actor.org_unit WHERE opac_visible
            )
        )
) incremental_bibs
ORDER BY id;

-- NOTE: When changing this or the marc21.ids extract in weekly.sql make sure that
-- everything from 'SELECT DISTINCT' through ') bibs' matches!
\o all_bib.ids
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
ORDER BY id;

