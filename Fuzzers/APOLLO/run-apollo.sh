#!/bin/bash

set -e # 遇到错误立即退出

echo "=== Apollo Fuzzing environment startup script ==="

# 检查 Docker 是否运行
if ! docker info >/dev/null 2>&1; then
	echo "Error: The Docker daemon is not running. Please start Docker first."
	exit 1
fi

# Create output directory
mkdir -p output
mkdir -p config
echo "✓ Create output directory: ./output"
# Check if Dockerfile exists

if [ ! -f "Dockerfile" ]; then
	echo "Warning: Dockerfile not found in the current directory"
	echo "Please download the Dockerfile from https://github.com/sslab-gatech/apollo and place it in the current directory"
	echo "Or execute: git clone https://github.com/sslab-gatech/apollo ."
	read -p "Continue? (If a Dockerfile already exists in another location) [y/N] " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		exit 1
	fi
fi


COMPOSE_FILE="docker-compose.yml"

docker compose up -d

# Start service

echo "Start Apollo container..."

docker compose -f $COMPOSE_FILE up -d

echo ""
echo "=== Instructions ==="
echo ""
echo "1. Enter the container: docker exec -it apollo /bin/bash"
echo ""
echo "2. PostgreSQL Fuzzing steps:"
echo " cd /home/apollo/src/sqlfuzz"
echo " ./fuzz.py -c configuration/postgres.yaml"
echo ""
echo "3. View fuzzing results: ./output/ directory on the host machine"
echo "4. Stop the service: docker compose -f $COMPOSE_FILE down"


# Display Apollo component information
echo "=== Apollo components ==="
echo "• SQLFuzz: Feedback-driven fuzzing to generate SQL statements"
echo "• SQLMin: Automatically simplifies SQL statements that trigger regressions"
echo "• SQLDebug: Diagnoses the root cause of performance regressions"
echo ""
echo "Supported databases: PostgreSQL, SQLite3, CockroachDB"
echo ""

# Optional: Enter the container directly
read -p "Enter the Apollo container now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "Entering the Apollo container..."
	docker exec -it apollo /bin/bash
fi
