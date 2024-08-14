INSERT INTO account_profiles(id,name,driver,loginConfiguration,authenticationMethod,vendorOpacUrl,patronApiUrl,recordSource,weight,databaseHost,databaseName,databaseUser,databasePassword,sipHost,sipPort,sipUser,sipPassword,databasePort,databaseTimezone,oAuthClientId,oAuthClientSecret,ils,apiVersion,staffUsername,staffPassword,workstationId,domain)
VALUES(2,'ils','Koha','barcode_pin','ils','http://kohadev-koha-1:8080','http://kohadev-koha-1:8080','ils',0,'kohadev-db-1','koha_kohadev','koha_kohadev','password',NULL,NULL,NULL,NULL,3306,'GMT',NULL,NULL,'koha',NULL,NULL,NULL,NULL,NULL);
UNLOCK TABLES;
LOCK TABLES indexing_profiles WRITE;
INSERT INTO indexing_profiles (id, name, marcPath, marcEncoding, groupingClass, indexingClass, recordDriver, recordUrlComponent, formatSource, recordNumberTag, itemTag, itemRecordNumber, useItemBasedCallNumbers, callNumber, location, shelvingLocation,collection, volume, barcode, totalCheckouts, totalRenewals, iType, dueDate, dateCreated, dateCreatedFormat, format, catalogDriver, filenamesToInclude, doAutomaticEcontentSuppression, recordNumberSubfield, recordNumberPrefix, noteSubfield, lastCheckinFormat, runFullUpdate) VALUES (1,'ils','/data/aspen-discovery/test.localhostaspen/ils/marc','UTF8','MarcRecordGrouper','Koha','MarcRecordDriver','Record','item','999','952','9',1,'o','a','c','8','h','p','l','m','y','k','d','yyyy-MM-dd','y','Koha','.*\\.ma?rc',1,'c', '', 'z', '',1);
UNLOCK TABLES;
LOCK TABLES library_records_to_include WRITE;
INSERT INTO library_records_to_include (id, libraryId, indexingProfileId, location, subLocation, includeHoldableOnly, includeItemsOnOrder, includeEContent, weight, iType, audience, format, marcTagToMatch, marcValueToMatch, includeExcludeMatches, urlToMatch, urlReplacement, locationsToExclude, subLocationsToExclude, markRecordsAsOwned) VALUES (1,1,1,'.*','.*',0,1,1,1,'','','','','',1,'','','','', 1);
UNLOCK TABLES;
LOCK TABLES status_map_values WRITE;
INSERT INTO status_map_values (id, indexingProfileId, value, status, groupedStatus, suppress) VALUES (1,1,'Checked Out','Checked Out','Checked Out',0),(2,1,'Claims Returned','Claims Returned','Currently Unavailable',1),(3,1,'On Shelf','On Shelf','On Shelf',0),(4,1,'Damaged','Damaged','Currently Unavailable',1),(5,1,'In Transit','In Transit','In Transit',0),(6,1,'Library Use Only','Library Use Only','Library Use Only',0),(7,1,'Long Overdue (Lost)','Long Overdue (Lost)','Currently Unavailable',1),(8,1,'Lost','Lost','Currently Unavailable',1),(9,1,'Lost and Paid For','Lost and Paid For','Currently Unavailable',1),(10,1,'Missing','Missing','Currently Unavailable',1),(11,1,'On Hold Shelf','On Hold Shelf','Checked Out',0),(12,1,'On Order','On Order','On Order',0),(13,1,'Discard','Discard','Currently Unavailable',1),(14,1,'Lost Claim','Lost Claim','Currently Unavailable',1);
UNLOCK TABLES;
LOCK TABLES translation_maps WRITE;
INSERT INTO translation_maps VALUES (1,1,'location',0),(2,1,'sub_location',0),(3,1,'shelf_location',0),(5,1,'itype',0);
UNLOCK TABLES;

UPDATE modules set enabled = 1 where name = 'Koha';
