#!/bin/bash
echo "Starting SQLite fuzz testing..."
echo "command: bash /home/sqlite/scripts/run_sqlright_sqlite_fuzzing_helper.sh --start-core 0 --num-concurrent 10 -O TLP"
docker exec -it sqlright_sqlite /bin/bash
