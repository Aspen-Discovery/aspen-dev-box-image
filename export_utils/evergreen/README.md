# How To Bootstrap Evergreen + Aspen

## Bring up the Stack

* Bring up the stack
  ```
  docker compose -f docker-compose.yml -f docker-compose.evergreen.yml up -d --force-recreate
  ```

* Wait for [Aspen](http://localhost:8083) and [Evergreen](https://localhost) to be available.
    ```
    bin/wait-until 'curl -qsS localhost:8083' 900 && bin/wait-until 'curl -qsS localhost:80' 900 && echo EVERYTHING IS UP
    ```

## Import Records

NB: The "//" in these commands prevents Git Bash on Windows from rewriting paths to Windows-style.

* Run the Evergreen export
  ```
  docker exec -it aspen-dev-box-evergreen-ils-1 //mnt/export_utils/evergreen/weekly.sh
  ```

* Copy the exported files into the Aspen import area
  ```
  docker exec -it containeraspen //mnt/export_utils/evergreen/aspen_import_weekly.sh
  ```

* Refresh the [ILS Export Log](http://localhost:8083/ILS/IndexingLog) page until the importer runs the next time

## Fix up the Hierarchy

* Edit [Library System HHPL](http://localhost:8083/Admin/Libraries?objectAction=edit&id=2), check "Default Library", and Save it

## Issue Summary

* Search kind of works in that you can find things, e.g. [Search for "Ready Player One"](http://localhost:8083/Union/Search?view=list&showCovers=on&lookfor=Ready+Player+One&searchIndex=Keyword&searchSource=local)

* Issue: the status on items always says "Available from another library"

* Issue: no bookjacket images are displayed, only placeholders

* Issue: placing a hold as user "Thomas Trollshaws" fails with, "This account is not associated with a library, please contact your library.".  That user's home library is SPLS-BPL.  In Evergreen, that is a Branch, but in Aspen, it's a "System"!?
