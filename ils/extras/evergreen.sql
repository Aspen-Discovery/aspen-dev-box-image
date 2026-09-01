INSERT INTO library_records_to_include(
    libraryId, indexingProfileId, location, subLocation,
    includeHoldableOnly, includeItemsOnOrder, includeEContent, weight,
    includeExcludeMatches, markRecordsAsOwned
) VALUES (1, 1, '.*', '.*', 0, 1, 1, 1, 1, 1);

INSERT INTO status_map_values (indexingProfileId, value, status, groupedStatus, suppress) VALUES
(1, 'Checked Out', 'Checked Out', 'Checked Out', 0),
(1, 'Claims Returned', 'Claims Returned', 'Currently Unavailable', 1),
(1, 'On Shelf', 'On Shelf', 'On Shelf', 0),
(1, 'Damaged', 'Damaged', 'Currently Unavailable', 1),
(1, 'In Transit', 'In Transit', 'In Transit', 0),
(1, 'Library Use Only', 'Library Use Only', 'Library Use Only', 0),
(1, 'Long Overdue (Lost)', 'Long Overdue (Lost)', 'Currently Unavailable', 1),
(1, 'Lost', 'Lost', 'Currently Unavailable', 1),
(1, 'Lost and Paid For', 'Lost and Paid For', 'Currently Unavailable', 1),
(1, 'Missing', 'Missing', 'Currently Unavailable', 1),
(1, 'On Hold Shelf', 'On Hold Shelf', 'Checked Out', 0),
(1, 'On Order', 'On Order', 'On Order', 0),
(1, 'Discard', 'Discard', 'Currently Unavailable', 1),
(1, 'Lost Claim', 'Lost Claim', 'Currently Unavailable', 1);

INSERT INTO translation_maps (indexingProfileId, name, usesRegularExpressions) VALUES
(1, 'location', 0),
(1, 'sub_location', 0),
(1, 'shelf_location', 0),
(1, 'itype', 0);
