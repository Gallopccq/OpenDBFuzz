#!/bin/bash
echo ""
echo "=== SQLancer Fuzzing ==="
#!/bin/bash
echo "Database Testing Tool Supported:"
echo "==================================="
echo ""
echo "Database    TLP  NoREC  PQS  DQE  DQP  CODDTest"
echo "----------------------------------------------"
echo "MySQL        √           √    √    √     √"
echo "SQLite       √     √     √    √          √"
echo "MariaDB            √               √"
echo "TiDB         √                     √      "
echo "PostgreSQL          √     √"
echo ""
echo "Legend:"
echo "√ - Supports the testing tool"
echo "Empty - Does not support the testing tool"
echo ""

docker compose up -d

# get config
CONFIG_FILE="${1:-config.properties}"
# check config file
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi
source <(grep -v '^#' "$CONFIG_FILE" | grep '=')

# set config
dbms=${dbms:-postgres}
version=${version:-12}
oracle=${oracle:-PQS}
username=${username:-postgres}
password=${password:-postgres}
host=${host:-localhost}
port=${port:-5432}
timeout_seconds=${timeout_seconds:-1440}
num_threads=${num_threads:-4}
num_tries=${num_tries:-10000}
print_progress_summary=${print_progress_summary:-true}
use_reducer=${use_reducer:-""}

# Get user input
: ${SQLANCER_DBMS:=$(read -p "Enter database (postgres/mysql/sqlite/tidb/mariadb, default: postgres): " value; echo ${value:-postgres})}
: ${SQLANCER_ORACLE:=$(read -p "Enter test type (PQS/DQE/DQP/TLP/NoREC/CODDTest, default: PQS): " value; echo ${value:-PQS})}
echo ""
echo "Tips: If you want change detailed parameter, edit in file \"config.properties\""
echo ""

if [ "$SQLANCER_DBMS" = "postgres" ]; then
    dbms=${pg_dbms:-postgres}
	version=${pg_version:-12}
	oracle=${SQLANCER_ORACLE:-pg_oracle}
	username=${pg_username:-postgres}
	password=${pg_password:-postgres}
	host=${pg_host:-postgres-12}
	port=${pg_port:-5432}

	if [[ "$(docker ps | grep $host 2> /dev/null)" == "" ]]; then
		echo "$dbms not running, try to start..."
		cd ../../DBMSs/PostgreSQL/
		docker compose up -d
	fi
elif [ "$SQLANCER_DBMS" = "mysql" ]; then
    dbms=${my_dbms:-mysql}
	version=${my_version:-8.0.16}
	oracle=${SQLANCER_ORACLE:-PQS}
	username=${my_username:-root}
	password=${my_password:-123456}
	host=${my_host:-mysql-8.0.16}
	port=${my_port:-3306}

	if [[ "$(docker ps | grep $host 2> /dev/null)" == "" ]]; then
		echo "$dbms not running, try to start..."
		cd ../../DBMSs/MySQL/
		docker compose up -d
	fi

elif [ "$SQLANCER_DBMS" = "tidb" ]; then
	if [ "$SQLANCER_ORACLE" = "tlp" ]; then
		SQLANCER_ORACLE=QUERY_PARTITIONING
	fi
	if [ "$SQLANCER_ORACLE" = "TLP" ]; then
		SQLANCER_ORACLE=QUERY_PARTITIONING
	fi
	dbms=${tidb_dbms:-mysql}
	version=${tidb_version:-8.0.16}
	oracle=${SQLANCER_ORACLE:-PQS}
	username=${tidb_username:-root}
	password=${tidb_password:-""}
	host=${tidb_host:-mysql-8.0.16}
	port=${tidb_port:-3306}

	if [[ "$(docker ps | grep  "0.0.0.0:4004" 2> /dev/null)" == "" ]]; then
		echo "$dbms not running, try to start..."
		cd ../../DBMSs/TiDB/
		docker compose up -d
	fi
elif [ "$SQLANCER_DBMS" = "sqlite" ]; then
    dbms=${sqlite_dbms:-mysql}
	version=${sqlite_version:-8.0.16}
	oracle=${SQLANCER_ORACLE:-PQS}
	username=${sqlite_username:-root}
	password=${sqlite_password:-123456}
	host=${sqlite_host:-mysql-8.0.16}
	port=${sqlite_port:-3306}

elif [ "$SQLANCER_DBMS" = "mariadb" ]; then
	dbms=${mariadb_dbms:-mysql}
	version=${mariadb_version:-8.0.16}
	oracle=${SQLANCER_ORACLE:-PQS}
	username=${mariadb_username:-root}
	password=${mariadb_password:-123456}
	host=${mariadb_host:-mysql-8.0.16}
	port=${mariadb_port:-3306}

	if [[ "$(docker ps | grep $host 2> /dev/null)" == "" ]]; then
		echo "$dbms not running, try to start..."
		cd ../../DBMSs/MariaDB/
		docker compose up -d
	fi
else
    echo "Error: Unsupported database type: $SQLANCER_DBMS"
    exit 1
fi

echo "Press Enter to continue..."
read

echo ""
echo "=== $dbms Testing Configuration ==="
echo "Database: $dbms-$version"
echo "Oracle: $oracle"
echo "Username: $username"
echo "Password: $password"
echo "Host: $host"
echo "Port: $port"
echo "Timeout: $timeout seconds"
echo "Thread Count: $num_threads"
echo "Number of Tries: $num_tries"
echo "Number of Tries: $num_tries"
echo "Print_progress_summary: $print_progress_summary"
echo "Use-reducer: $use_reducer"
echo ""

# generate command
cmd="java -jar sqlancer-*.jar"
if [[ ! $host =~ "none" ]]; then
	cmd="$cmd --host $host"	
fi
if [[ ! "$port" =~ "none" ]]; then
	cmd="$cmd --port $port"
fi
if [[ ! "$username" =~ "none" ]]; then
	cmd="$cmd --username $username"
fi
if [[ ! "$password" =~ "none" ]]; then
	cmd="$cmd --password $password"
fi

cmd="$cmd --timeout-seconds $timeout_seconds"
cmd="$cmd --num-threads $num_threads"
cmd="$cmd --num-tries $num_tries"
cmd="$cmd --print-progress-summary $print_progress_summary"
cmd="$cmd --use-reducer $use_reducer"
cmd="$cmd $dbms"
cmd="$cmd --oracle $oracle"

echo "Current command:"
echo "$cmd"


# Interactive Confirmation
read -p "Start $dbms fuzz testing? (y/N): " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    exit 0
fi

# PostgreSQL Testing
echo "=== Starting $dbms Testing ==="
start_time=$(date +%s)

docker compose exec sqlancer bash -c "cd /home/sqlancer/target && $cmd"

exit_code=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "=== Testing Complete ==="
echo "Test Duration: $duration seconds"
echo "Exit Code: $exit_code"
echo "Log File Location: ./sqlancer-logs/"
echo "Use the following command to view real-time logs:"
echo "docker compose logs -f sqlancer"