#!/usr/bin/env bash
if [ -z "$1" ]; then
    echo "Error: You need to specify a project"
    echo "Use: ./debug.sh <project>"
    echo "Example: ./debug.sh koha_export"
    exit 1
fi

if pgrep -f "jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005" > /dev/null; then
  echo "⚠️ There is a debug process running yet (port 5005)."
  exit 0
fi

declare -A projects
projects["koha_export"]="com/turning_leaf_technologies.koha_export.KohaExportMain"
projects["oai_indexer"]="com.turning_leaf_technologies.oai.OaiIndexerMain"
projects["overdrive_extract"]="com.turning_leaf_technologies.overdrive.ExtractOverDriveInfoMain"
projects["palace_project_export"]="org.aspendiscovery.palace_project.PalaceProjectExportMain"
projects["polaris_export"]="com.turning_leaf_technologies.polaris.PolarisExportMain"
projects["reindexer"]="org.aspen_discovery.reindexer.GroupedReindexMain"
projects["series_indexer"]="com.turning_leaf_technologies.series.SeriesMain"
projects["sideload_processing"]="com.turning_leaf_technologies.sideloading.SideLoadingMain"
projects["sierra_export_api"]="com.turning_leaf_technologies.sierra.SierraExportAPIMain"
projects["symphony_export"]="com.turning_leaf_technologies.symphony.SymphonyExportMain"
projects["user_list_indexer"]="com.turning_leaf_technologies.reindexer.UserListIndexerMain"

name="$1"

if [[ -z "${projects[$name]}" ]]; then
  echo "Proyecto '$name' no encontrado"
  exit 1
fi

appDir="/usr/local/aspen-discovery"
path="$appDir/code/$name"
binDir="/tmp/aspen-debug/$name"
echo "Executing '$name' in path: $path"

echo "=== CHANGING TO DIRECTORY: /usr/local/aspen-discovery/code/$name ==="
cd "$path" || exit 1

if [ ! -d "src" ]; then
    echo "Error: Missing folder 'src' in $(pwd)"
    exit 1
fi

echo "=== COMPILING FOR DEBUGGING ==="
rm -rf "$binDir"
mkdir -p "$binDir"
classpath="$binDir:$(find "$appDir/code" -name '*.jar' | tr '\n' ':')"
javac -cp "$classpath" -d "$binDir" $(find src -name '*.java') $(find $appDir/code/java_shared_libraries -name '*.java')

echo "=== INITIALIZING DEBUGGING ==="
echo "Waiting for VSC to connect to 5005 port..."
echo "▶ Run debugger now (F5)"

java -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005 \
     -cp "$classpath" \
     "${projects[$name]}" \
     "$SITE_NAME" \
     &
