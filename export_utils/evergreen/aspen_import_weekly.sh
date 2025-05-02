#!/bin/bash -
#
# aspen_import_weekly.sh -
#
#       Copy the weekly export from Evergreen to the Aspen import area
#
#       Should be run inside the Aspen container
#       See ./README.md

su - aspen -c "cp /mnt/export_utils/evergreen/scratch/* /data/aspen-discovery/test.localhostaspen/ils/marc"
