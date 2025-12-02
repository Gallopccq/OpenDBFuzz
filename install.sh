cwd=`pwd`

echo "INSTALL SIZE (roughly)"
echo "======================"

echo "REPOSITORY                      SIZE"
echo "radar-radar                     1.02GB"
echo "apollo-apollo                   1.52GB"
echo "squirrel-squirrel-mariadb       8.08GB"
echo "squirrel-squirrel-postgres      1.91GB"
echo "squirrel-squirrel-mysql         11.1GB"
echo "amoeba-amoeba                   19GB"
echo "troc-troc                       754MB"
echo "dqe-dqe                         1.03GB"
echo "squirrel-squirrel-sqlite        2.16GB"
echo "sqlancer-sqlancer               1.7GB"
echo "opendbfuzz-amoeba               19GB"
echo "postgres                        419MB"
echo "pingcap/tidb                    557MB"
echo "steveleungsly/sqlright_sqlite   15.2GB"
echo "steveleungsly/sqlright_mysql    43.8GB"
echo "steveleungsly/sqlright_postgres 3.97GB"
echo "mariadb                         407MB"
echo "mysql                           443MB"

echo
read -p "Start Installing?"

total=$(find . -name docker-compose.yml | wc -l)
current=0
echo "Nums to install: $total"
find . -name docker-compose.yml -exec dirname {} \; | while read dir; do
	((current++))
	cd $cwd
	echo "[$current/$total] Starting: $dir" 
	cd "$dir" && { docker compose up -d; }
done
echo "$total projects started"
