#!/bin/bash

echo "=== DQE Fuzzing ==="

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
	echo "Error: The Docker daemon is not running. Please start Docker first."
	exit 1
fi

docker compose up -d


# get config
CONFIG_FILE="${1:-config.properties}"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config file not exist: $CONFIG_FILE"
    exit 1
fi
source <(grep -v '^#' "$CONFIG_FILE" | grep '=')

# Database selection
: ${DBMS:=$(read -p "Enter database (sqlite3/mysql, default: sqlite3): " value; echo ${value:-sqlite3})}

echo ""
echo "Tips: If you want change detailed parameter, edit in file \"config.properties\""
echo ""

cmd=""

if [ "$DBMS" = "sqlite3" ]; then
    cmd="java -jar ${DQE_TOOL_JAR} --timeout-seconds ${TIMEOUT_SECONDS} --num-threads ${NUM_THREADS} --num-tries ${NUM_TRIES} --print-progress-summary ${PRINT_PROGRESS_SUMMARY} --use-reducer $DBMS --oracle ${SQLITE_ORACLE}"

	
elif [ "$DBMS" = "mysql" ]; then
	cmd="java -jar ${DQE_TOOL_JAR} --host ${MYSQL_HOST} --username ${MYSQL_USERNAME} --password ${MYSQL_PASSWORD} --timeout-seconds ${TIMEOUT_SECONDS} --num-threads ${NUM_THREADS} --num-tries ${NUM_TRIES} --print-progress-summary ${PRINT_PROGRESS_SUMMARY} --use-reducer $DBMS --oracle ${MYSQL_ORACLE}"	
	echo "Start $DBMS"
	cd ../../DBMSs/MySQL/ && docker compose up -d
else
    echo "Error: Unsupported database type: $DBMS"
    exit 1
fi

echo -e "\n=== Usage ==="
echo "1. Enter: docker exec -it dqe bash"
echo "2. SQLite Fuzzing:"
echo "  cd /home/dqetool/target"
echo "  java -jar dqetool-2.0.0.jar --timeout-seconds 1440 --num-threads 60 --num-tries 100000000 --print-progress-summary true --use-reducer sqlite3 --oracle DQE"
echo "3. MySQL Fuzzing:"
echo "  cd /home/dqetool/target"
echo "  java -jar dqetool-2.0.0.jar --host mysql-8.0.16 --username root --password root --timeout-seconds 1440 --num-threads 60 --num-tries 100000000 --print-progress-summary true --use-reducer mysql --oracle PQS"
echo "4. Stop: docker compose down"

echo ""

echo "Current DQE Command:"
echo "${cmd}"
echo

read -p "Run now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting fuzzing..."
	docker exec dqe bash -c "cd /home/dqetool/target && $cmd"
fi