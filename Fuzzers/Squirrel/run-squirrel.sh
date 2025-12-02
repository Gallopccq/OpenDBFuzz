#!/bin/bash

echo "=== Squirrel Fuzzing ==="

# Check Docker
if ! docker info > /dev/null 2>&1; then
    echo "Error: Please start Docker first"
    exit 1
fi

# Load config
CONFIG_FILE="${1:-config.properties}"
[[ -f "$CONFIG_FILE" ]] && source <(grep -v '^#' "$CONFIG_FILE" | grep '=')

COMPOSE_FILE="docker-compose.yml"

# Database selection
: ${DBMS:=$(read -p "Enter database (sqlite3/mysql/mariadb/postgres, default: sqlite3): " value; echo ${value:-sqlite3})}
echo "Selected: $DBMS"

# Map DB to service name
case "$DBMS" in
    "sqlite3"|"sqlite") SERVICE="squirrel-sqlite"; DB_TYPE="sqlite" ;;
    "mysql") SERVICE="squirrel-mysql"; DB_TYPE="mysql" ;;
    "mariadb") SERVICE="squirrel-mariadb"; DB_TYPE="mariadb" ;;
    "postgres"|"postgresql") SERVICE="squirrel-postgres"; DB_TYPE="postgresql" ;;
    *) echo "Error: Unsupported DB: $DBMS"; exit 1 ;;
esac

# Start service
docker compose -f docker-compose.yml up -d $SERVICE

# Build command
CMD="python3 /home/Squirrel/scripts/utils/run.py $DB_TYPE /home/Squirrel/data/fuzz_root/input --output_dir ${OUTPUT_PATH:-/home/Squirrel/outputs}"

echo -e "\n=== Usage ==="
echo "1. Enter: docker exec -it squirrel /bin/bash"
echo "2. Run: cd /home/Squirrel/scripts/utils && python3 run.py sqlite /home/Squirrel/data/fuzz_root/input"
echo "3. Stop: docker compose down"

echo -e "\nCurrent Command: "
echo $CMD

read -p "Run now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting fuzzing..."
	docker compose -f docker-compose.yml exec $SERVICE bash -c "$CMD"
fi