#!/bin/bash

echo "=== AMOEBA Fuzzing ==="

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
	echo "Error: The Docker daemon is not running. Please start Docker first."
	exit 1
fi
docker compose up -d

# read config
CONFIG_FILE="${1:-config.properties}"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config file not exist: $CONFIG_FILE"
    exit 1
fi
source <(grep -v '^#' "$CONFIG_FILE" | grep '=')

cmd="timeout ${TIMEOUT} ${TEST_DRIVER} --workers ${WORKERS} --output ${OUTPUT_DIR} --queries ${QUERIES} --rewriter ${REWRITER} --dbms=${DBMS}"

if [ "${VALIDATE}" = "true" ]; then
	cmd="${cmd} --validate"
fi
cmd="$cmd --num_loops=${NUM_LOOPS} --feedback=${FEEDBACK} --dbconf=${DB_CONF} --query_timeout ${QUERY_TIMEOUT}"


echo "Current AMOEBA Command:"
echo "${cmd}"

echo -e "\n=== Usage ==="
echo "1. Enter: docker exec -it amoeba bash"
echo "2. Setup: cd /workspace && eval \"\$(direnv hook bash)\" && start_pg13.sh"
echo "3. Run: "
echo "    timeout 1440 ./test_driver.py --workers 30 --output /home/postgres/exps/1 --queries 20000 --rewriter ./calcite-fuzzing --dbms=postgresql --validate --num_loops=100 --feedback=none --dbconf=db_conf_demo.json --query_timeout 30"
echo "4. Stop: docker compose down"
echo

read -p "Enter now? [y/N] " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "Entering AMOEBA container..."
	docker exec -it amoeba /bin/bash
fi
