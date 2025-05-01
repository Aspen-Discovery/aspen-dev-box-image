-- Map item barcodes to parts
\o parts.csv
SELECT 
     bmp.record AS bib_id
    ,bmp.label AS part_label 
    ,bmp.id AS part_id 
    ,acp.barcode 
FROM 
    biblio.monograph_part bmp 
JOIN 
    asset.copy_part_map cpm ON cpm.part = bmp.id
JOIN 
    asset.copy acp ON acp.id = cpm.target_copy
JOIN
    asset.copy_location acpl ON acpl.id = acp.location
JOIN
    config.copy_status ccs ON ccs.id = acp.status
JOIN
    actor.org_unit aou ON aou.id = acp.circ_lib
WHERE 
    NOT bmp.deleted 
    AND NOT acp.deleted
    AND acp.opac_visible
    AND acpl.opac_visible
    AND ccs.opac_visible
    AND aou.opac_visible
;

-- Items and create dates
\o barcode_active_dates.csv
SELECT 
     barcode
    ,DATE(create_date)
FROM 
    asset.copy acp
JOIN
    asset.copy_location acpl ON acpl.id = acp.location
JOIN
    config.copy_status ccs ON ccs.id = acp.status
JOIN
    actor.org_unit aou ON aou.id = acp.circ_lib
WHERE 
    NOT acp.deleted
    AND acp.opac_visible
    AND acpl.opac_visible
    AND ccs.opac_visible
    AND aou.opac_visible
;



-- Anything below here is an *actual* csv. @_@
\pset fieldsep ','

-- Hold count on bibs
\o holds.csv
SELECT
    rhrr.bib_record
   ,COUNT(rhrr.id) AS num_holds
FROM
    reporter.hold_request_record rhrr
JOIN
    action.hold_request ahr ON (rhrr.id = ahr.id AND ahr.fulfillment_time IS NULL AND ahr.cancel_time IS NULL)
WHERE rhrr.bib_record > 0
GROUP BY 1
; 

