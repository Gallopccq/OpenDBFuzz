#!/bin/bash

echo "=== Apollo Fuzzing ==="

if ! docker info >/dev/null 2>&1; then
	echo "Error: The Docker daemon is not running. Please start Docker first."
	exit 1
fi

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

docker compose up -d

echo ""
echo "=== Usage ==="
echo "1. Enter: docker exec -it apollo /bin/bash"
echo "2. PostgreSQL Fuzzing steps:"
echo "   cd /home/apollo/src/sqlfuzz"
echo "   ./fuzz.py -c configuration/postgres.yaml"
echo "3. Stop the service: docker compose down"

echo "Supported databases: PostgreSQL, SQLite3, CockroachDB"
echo ""

# Optional: Enter the container directly
read -p "Enter now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "Entering Apollo container..."
	docker exec -it apollo /bin/bash
fi
