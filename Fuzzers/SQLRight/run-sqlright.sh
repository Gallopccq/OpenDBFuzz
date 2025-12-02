#!/bin/bash
echo "=== SQLRight Fuzzing ==="

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
	echo "Error: Please start Docker first"
	exit 1
fi

# Database selection
: ${DBMS:=$(read -p "Enter database (sqlite3/postgres/mysql, default: sqlite3): " value; echo ${value:-sqlite3})}
echo "Selected: $DBMS"
echo ""
echo "Tips: If you want change detailed parameter, edit in file \"config.properties\""
echo ""

# get config
CONFIG_FILE="${1:-config.properties}"
if [[ ! -f "$CONFIG_FILE" ]]; then
	echo "Error: Config file not found: $CONFIG_FILE"
	exit 1
fi
# read config
source <(grep -v '^#' "$CONFIG_FILE" | grep '=')

# Map DB to service and script
case "$DBMS" in
    "sqlite3") SERVICE="sqlright_sqlite"; SCRIPT_VAR="SQLITE_SCRIPT" ;;
    "postgres") SERVICE="sqlright_postgres"; SCRIPT_VAR="POSTGRES_SCRIPT" ;;
    "mysql") SERVICE="sqlright_mysql"; SCRIPT_VAR="MYSQL_SCRIPT" ;;
    *) echo "Error: Unsupported DB: $DBMS"; exit 1 ;;
esac

# Start service
docker compose up -d $SERVICE

# Build command
cmd="bash ${!SCRIPT_VAR} --start-core ${START_CORE} --num-concurrent ${NUM_CONCURRENT} -O ${ORACLE_TYPE}"

echo -e "\n=== Usage ==="
echo "1. Enter: docker exec -it $SERVICE bash"
echo "2. SQLite Fuzzing:"
echo "   cd /home/sqlite/fuzzing/fuzz_root"
echo "   bash /home/sqlite/scripts/run_sqlright_sqlite_fuzzing_helper.sh --start-core 0 --num-concurrent 10 -O TLP"
echo "3. Stop: docker compose down"
echo 
echo "Current command:"
echo "${cmd}"
echo ""

# Optional: Enter container directly
read -p "Run now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting fuzzing..."
	    if [ "$DBMS" = "mysql" ]; then
        docker compose exec $SERVICE bash -c "mkdir -p /home/mysql/fuzzing/Bug_Analysis /home/mysql/fuzzing/fuzz_root/outputs && $cmd"
    else
        docker compose exec $SERVICE bash -c "$cmd"
    fi
fi
