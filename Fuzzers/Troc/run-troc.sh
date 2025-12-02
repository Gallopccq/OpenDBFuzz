#!/bin/bash

echo "=== Troc Fuzzing ==="

# Check Docker
if ! docker info > /dev/null 2>&1; then
    echo "Error: Please start Docker first"
    exit 1
fi

# Start services
echo "Starting Troc container..."
docker compose up -d


# Load config
CONFIG_FILE="${1:-config.properties}"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# read config
source <(grep -v '^#' "$CONFIG_FILE" | grep '=')

# Database selection
: ${DBMS:=$(read -p "Enter database (mysql/mariadb, default: mysql): " value; echo ${value:-mysql})}


ARGS=()
if [ "$DBMS" = "mysql" ]; then
	ARGS+=("--dbms" "$my_dbms")
	ARGS+=("--host" "$my_host")
	ARGS+=("--username" "$my_username")
	ARGS+=("--password" "$my_password")
	ARGS+=("--db" "$my_db")
elif [ "$DBMS" = "mariadb" ]; then
	ARGS+=("--dbms" "$mariadb_dbms")
	ARGS+=("--host" "$mariadb_host")
	ARGS+=("--username" "$mariadb_username")
	ARGS+=("--password" "$mariadb_password")
	ARGS+=("--db" "$mariadb_db")
fi

read -p "Use test case ? [y/N]:" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	if [[ -n "$set_case" && "$set_case" == "true" ]]; then
		ARGS+=("--set-case")
	fi

	if [[ -n "$case_file" ]]; then
		ARGS+=("--case-file" "$case_file")
	fi

	if [[ -n "$table" ]]; then
		ARGS+=("--table" "$table")
	fi
fi

echo "Tips: If you want change detailed parameter, edit in file \"config.properties\""
echo ""

cmd="java -jar troc*.jar ${ARGS[@]}"



echo -e "\n=== Usage ==="
echo "1. Enter: docker exec -it troc bash"
echo "2. Test: cd /home/Troc/target && java -jar troc*.jar --dbms mysql --host mysql-8.0.16 --username root --password root --db test --table t"
echo "3. Test with test cases:"
echo "   java -jar troc*.jar --dbms mysql --host mysql-8.0.16 --username root --password root --db test --set-case --case-file ../cases/test.txt --table t"
echo "4. View test results: Check /home/Troc/target/troc.log file in container"
echo "5. Stop: docker compose down"

echo
echo "Current command: $cmd"
echo ""

# Optional: Enter container directly
read -p "Run now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting Troc..."
    docker exec troc /bin/bash -c "cd /home/Troc/target/ && $cmd"
fi
