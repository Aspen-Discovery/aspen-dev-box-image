# How To Bootstrap Evergreen + Aspen

## Bring up the Stack

* Bring up the stack
  ```
  docker compose -f docker-compose.yml -f docker-compose.evergreen.yml up -d --force-recreate
  ```

* Wait for
  * [Aspen to be available](http://localhost:8083)
  * [Evergreen to be available](https://localhost)

## Import Records

* Run the Evergreen export
  ```
  docker exec -it aspen-dev-box-evergreen-ils-1 //mnt/export_utils/evergreen/weekly.sh
  ```

* Copy the exported files into the Aspen import area
  ```
  docker exec -it containeraspen //mnt/export_utils/evergreen/aspen_import_weekly.sh
  ```

* Watch the [ILS Export Log](http://localhost:8083/ILS/IndexingLog) page until the importer runs the next time

## Fix up the Hierarchy

* Edit [Library System HHPL](http://localhost:8083/Admin/Libraries?objectAction=edit&id=2), and mark it as "Default Library".  

## Status Summary

* Search kind of works in that you can find things, e.g. [Search for "Ready Player One"](http://localhost:8083/Union/Search?view=list&showCovers=on&lookfor=Ready+Player+One&searchIndex=Keyword&searchSource=local)

* Issue: the status on items always says "Available from another library"

* Issue: no bookjacket images are displayed, only placeholders
