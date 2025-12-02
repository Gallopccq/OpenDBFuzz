#!/bin/bash

echo "=== Radar Fuzzing ==="

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
	echo "Error: The Docker daemon is not running. Please start Docker first."
	exit 1
fi
docker compose -f docker-compose.yml up -d


# get config
CONFIG_FILE="${1:-config.properties}"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config file not exist: $CONFIG_FILE"
    exit 1
fi
# read config
source <(grep -v '^#' "$CONFIG_FILE" | grep '=')

# Database selection
: ${DBMS:=$(read -p "Enter database (default: sqlite3): " value; echo ${value:-sqlite3})}
[[ "$DBMS" != "sqlite3" ]] && { echo "Error: Only sqlite3 supported"; exit 1; }

echo "Tips: If you want change detailed parameter, edit in file \"config.properties\""
echo ""

cmd=""

if [ "$DBMS" = "sqlite3" ]; then
    cmd="java -jar ${Radar_TOOL_JAR}"
	cmd="${cmd} --timeout-seconds ${TIMEOUT_SECONDS}"
	cmd="${cmd} --num-threads ${NUM_THREADS}"
	cmd="${cmd} --num-tries ${NUM_TRIES}"
	cmd="${cmd} --print-progress-summary ${PRINT_PROGRESS_SUMMARY}"
	cmd="${cmd} --use-reducer"
	cmd="$cmd $DBMS"
else
    echo "Error: Unsupported database type: $DBMS"
    exit 1
fi

echo ""
echo -e "\n=== Usage ==="
echo "1. Enter: docker exec -it radar bash"
echo "2. SQLite Fuzzing:"
echo " cd /home/radar/target"
echo " java -jar sqlancer-2.0.0.jar --timeout-seconds 1440 --num-threads 60 --num-tries 100000000 --print-progress-summary true --use-reducer sqlite3"
echo 
echo "Current Radar Command:"
echo "${cmd}"
echo

read -p "Run now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting fuzzing..."
	docker compose exec radar bash -c "cd /home/radar/target && $cmd"
fi