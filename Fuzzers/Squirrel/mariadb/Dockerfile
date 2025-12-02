from ubuntu:22.04
LABEL maintainer="Squirrel"

# common config
RUN sh -c "sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && apt-get update"
RUN apt-get update
RUN apt-get -y install make cmake build-essential vim sudo git \
    clang libmysqlclient-dev ninja-build pkg-config clang-format \
    libpq-dev libyaml-cpp-dev lld python3-fire

RUN mkdir -p /home && \
    groupadd dobigthing && \
    useradd -l -K UMASK=0000 -d /home -g dobigthing dobigthing && \
    chown dobigthing:dobigthing /home

RUN     echo "dobigthing:dobigthing" | chpasswd && usermod -a -G sudo dobigthing
RUN chmod +w /etc/sudoers && \
    echo "%dobigthing   ALL=(ALL:ALL)NOPASSWD:ALL" >> /etc/sudoers && \
    chmod -w /etc/sudoers

# install mariadb-server
RUN apt-get -y install apt-transport-https curl software-properties-common gnutls-dev
RUN curl -o /etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc \
    'https://mariadb.org/mariadb_release_signing_key.asc'
RUN echo "deb https://ftp.osuosl.org/pub/mariadb/repo/10.11/ubuntu jammy main" >> /etc/apt/sources.list
RUN echo "deb-src https://ftp.osuosl.org/pub/mariadb/repo/10.11/ubuntu jammy main" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y build-dep mariadb

USER dobigthing
WORKDIR /home

RUN git clone https://gitee.com/zhuruijin/Squirrel.git && cd Squirrel 
WORKDIR /home/Squirrel/
RUN sh -c "sed -i 's/https:\/\/github.com\/AFLplusplus\/AFLplusplus.git/https:\/\/gitee.com\/shorpa\/AFLplusplus.git/g' .gitmodules"
RUN sh -c "sed -i 's/https:\/\/github.com\/abseil\/abseil-cpp.git/https:\/\/gitee.com\/jas0n1ee\/abseil-cpp/g' .gitmodules" 
RUN git submodule update --init 
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release 
RUN cmake --build build -j 
RUN cd AFLplusplus/ && LLVM_CONFIG=llvm-config-14 make -j20


RUN git clone --branch mariadb-10.11.9 --depth=1 https://gitee.com/anydev/maria-db.git mariadb 
WORKDIR /home/Squirrel/mariadb
RUN sed -i 's|https://github.com/MariaDB/mariadb-connector-c|https://gitee.com/mirrors/mariadb-connector-c|g;\
    s|https://github.com/facebook/rocksdb|https://gitee.com/mirrors/rocksdb|g;\
    s|https://github.com/codership/wsrep-lib|https://gitee.com/mirrors_mariadb-corporation/wsrep-lib|g;\
    s|https://github.com/wolfSSL/wolfssl|https://gitee.com/mirrors/wolfssl|g;\
    s|https://github.com/mariadb-corporation/libmarias3|https://gitee.com/mirrors_mariadb-corporation/libmarias3|g;\
    s|https://github.com/mariadb-corporation/mariadb-columnstore-engine|https://gitee.com/alwsgallop/mariadb-columnstore-engine|g' .gitmodules		
RUN git submodule update --init
RUN sed -i "s|https://github.com/mariadb-corporation/libmarias3|https://gitee.com/mirrors_mariadb-corporation/libmarias3|g" storage/columnstore/columnstore/.gitmodules
RUN sed -i "s|https://github.com/codership/wsrep-API|https://gitee.com/mirrors_mariadb-corporation/wsrep-API|g"  wsrep-lib/.gitmodules
RUN git submodule update --init --recursive

WORKDIR /home/Squirrel
RUN mkdir bld
RUN cd bld/ && CC=/home/Squirrel/AFLplusplus/afl-clang-fast CXX=/home/Squirrel/AFLplusplus/afl-clang-fast++ cmake ../mariadb/ 
RUN cd bld/ && make -j20 && sudo cmake --install . --prefix /usr/local/mysql/

RUN sudo chown dobigthing:dobigthing /usr/local/mysql/ -R && \
    cd /usr/local/mysql/ && \
    scripts/mysql_install_db --user=dobigthing

# Get map size and save it to /tmp/mapsize
RUN AFL_DEBUG=1 __AFL_SHM_ID=1234 /usr/local/mysql/bin/mariadbd 2>&1 | tail -n 1 | cut -d"," -f8 | cut -d" " -f 3 > /tmp/mapsize
WORKDIR /home/Squirrel/scripts/utils
# ENTRYPOINT AFL_MAP_SIZE=$(cat /tmp/mapsize) python3 run.py mariadb ../../data/fuzz_root/mysql_input/