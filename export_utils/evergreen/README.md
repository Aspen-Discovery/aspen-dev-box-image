# How To

* Bring up the stack
  ```
  docker compose -f docker-compose.yml -f docker-compose.evergreen.yml up -d --force-recreate
  ```

* Run the Evergreen export
  ```
  docker exec -it aspen-dev-box-evergreen-ils-1 //mnt/export_utils/evergreen/weekly.sh
  ```

* Copy the exported files into the Aspen import area
  ```
  docker exec -it containeraspen //mnt/export_utils/evergreen/aspen_import_weekly.sh
  ```
