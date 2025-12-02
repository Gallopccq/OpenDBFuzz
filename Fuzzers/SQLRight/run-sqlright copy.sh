#!/bin/bash

set -e # Exit immediately on error

echo "=== SQLRight Fuzz Testing Environment Startup Script ==="

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
	echo "Error: Docker daemon is not running, please start Docker first"
	exit 1
fi

# Create output directory
mkdir -p outputs
echo "✓ Created output directory: ./outputs"

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
	echo "Warning: Dockerfile not found in current directory"
	echo "Please download Dockerfile from https://github.com/PSU-Security-Universe/sqlright and place it in current directory"
	echo "Or execute: git clone https://github.com/PSU-Security-Universe/sqlright ."
	read -p "Continue? (if Dockerfile exists elsewhere) [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		exit 1
	fi
fi

# Check if network exists, create if not
if ! docker network inspect mynet >/dev/null 2>&1; then
	echo "Creating Docker network: mynet"
	docker network create mynet
else
	echo "✓ Docker network 'mynet' already exists"
fi

COMPOSE_FILE="docker-compose.yml"

# Build image
echo "1. Checking if SQLRight image exists..."
if [[ "$(docker images -q steveleungsly/sqlright_sqlite 2>/dev/null)" == "" ]]; then
	echo "SQLRight image not found, starting build..."
	docker compose build sqlright
else
	echo "SQLRight image already exists, skipping build."
fi

# Start services
echo "Starting SQLRight container..."
docker compose -f $COMPOSE_FILE up -d sqlright_sqlite

# Wait for container to start
sleep 5

# Check container status
if docker ps | grep -q sqlright; then
	echo "✓ SQLRight container started successfully"
else
	echo "Error: SQLRight container failed to start"
	docker compose -f $COMPOSE_FILE logs sqlright
	exit 1
fi

# Create helper scripts
mkdir -p scripts
cat >scripts/fuzz-sqlite.sh <<'EOF'
#!/bin/bash
echo "Starting SQLite fuzz testing..."
echo "command: bash /home/sqlite/scripts/run_sqlright_sqlite_fuzzing_helper.sh --start-core 0 --num-concurrent 10 -O TLP"
docker exec -it sqlright_sqlite /bin/bash
EOF

cat >scripts/fuzz-mysql.sh <<'EOF'
#!/bin/bash
echo "Starting MySQL fuzz testing..."
echo "command: bash /home/sqlite/scripts/run_sqlright_sqlite_fuzzing_helper.sh --start-core 0 --num-concurrent 10 -O TLP"
docker exec -it sqlright_mysql /bin/bash
EOF

cat >scripts/fuzz-postgres.sh <<'EOF'
#!/bin/bash
echo "Starting PostgreSQL fuzz testing..."
echo "command: bash /home/sqlite/scripts/run_sqlright_sqlite_fuzzing_helper.sh --start-core 0 --num-concurrent 10 -O TLP"
docker exec -it sqlright_postgres /bin/bash
EOF

chmod +x scripts/*.sh
echo "✓ Created helper scripts in ./scripts/ directory"

echo ""
echo "=== SQLRight Usage Instructions ==="
echo ""
echo "1. Enter container: docker exec -it sqlright_sqlite /bin/bash"
echo ""
echo "2. SQLite fuzz testing:"
echo "   cd /home/sqlite/fuzzing/fuzz_root"
echo "   bash /home/sqlite/scripts/run_sqlright_sqlite_fuzzing_helper.sh --start-core 0 --num-concurrent 10 -O TLP"
echo ""
echo "3. View fuzz testing results: Check ./outputs/ directory on host machine"
echo ""
echo "4. Stop services: docker compose -f $COMPOSE_FILE down"
echo ""

# Optional: Enter container directly
read -p "Enter SQLRight container now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "Entering SQLRight container..."
	docker exec -it sqlright_sqlite /bin/bash
fi
