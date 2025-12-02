from ubuntu:22.04
LABEL maintainer="Squirrel"

# common config
RUN sh -c "sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && apt-get update"
RUN apt-get update
RUN apt-get -y install make cmake build-essential vim sudo git \
    clang libmysqlclient-dev ninja-build pkg-config clang-format \
    libpq-dev libyaml-cpp-dev lld llvm bison python3-fire

RUN mkdir -p /home && \
    groupadd dobigthing && \
    useradd -l -K UMASK=0000 -d /home -g dobigthing dobigthing && \
    chown dobigthing:dobigthing /home

RUN     echo "dobigthing:dobigthing" | chpasswd && usermod -a -G sudo dobigthing
RUN chmod +w /etc/sudoers && \
    echo "%dobigthing   ALL=(ALL:ALL)NOPASSWD:ALL" >> /etc/sudoers && \
    chmod -w /etc/sudoers

USER dobigthing
WORKDIR /home

RUN git clone https://gitee.com/zhuruijin/Squirrel.git && cd Squirrel 
WORKDIR /home/Squirrel/
RUN sh -c "sed -i 's/https:\/\/github.com\/AFLplusplus\/AFLplusplus.git/https:\/\/gitee.com\/shorpa\/AFLplusplus.git/g' .gitmodules"
RUN sh -c "sed -i 's/https:\/\/github.com\/abseil\/abseil-cpp.git/https:\/\/gitee.com\/jas0n1ee\/abseil-cpp/g' .gitmodules"
RUN git submodule update --init && \
    cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -Wno-dev -DMYSQL=ON && \
    cmake --build build -j && \
    cd AFLplusplus/ && LLVM_CONFIG=llvm-config-14 make -j20

# RUN sudo apt-get install -y wget
# RUN wget https://downloads.mysql.com/archives/get/p/23/file/mysql-boost-8.0.39.tar.gz -O mysql.tar.gz
# RUN tar -zxvf mysql.tar.gz && mv mysql-8.0.39 mysql
RUN git clone --branch mysql-8.0.39 --depth=1 https://gitee.com/mirrors/mysql-server mysql
RUN sudo apt-get -y install apt-transport-https curl software-properties-common gnutls-dev \
    libevent-dev libwrap0-dev libsasl2-dev liblz4-dev liblzma-dev \
    libsnappy-dev libbz2-dev liblz4-tool libboost-dev

RUN sudo apt install -y libboost-all-dev
# RUN git clone --branch boost-1.77.0 --depth=1 https://gitee.com/mirrors/boost/ /home/Squirrel/boost

# COPY /home/ccqiu/disk/opt/OpenDBFuzz/Fuzzer/Squirrel/boost_1_77_0.tar.bz2 /home/Squirrel/
# COPY /home/ccqiu/disk/opt/OpenDBFuzz/Fuzzer/Squirrel/boost_* .
RUN git clone https://gitee.com/alwsgallop/dbfuzzers && mv dbfuzzers/boost_1_77_0 ./boost && rm -rf dbfuzzers
# RUN pwd && ls && err
# RUN tar xvf `ls boost_*` && mv boost_1_77_0 boost

RUN mkdir bld && cd bld/ && \
    CC=/home/Squirrel/AFLplusplus/afl-clang-fast CXX=/home/Squirrel/AFLplusplus/afl-clang-fast++ \
    cmake ../mysql/ -DWITH_BOOST=/home/Squirrel/boost \
    -DWITH_DEBUG=1 -DCPACK_MONOLITHIC_INSTALL=1 -DWITH_UNIT_TESTS=OFF
    
RUN cd bld/ && make -j32 && sudo cmake --install . --prefix /usr/local/mysql/

RUN sudo usermod -aG root dobigthing
RUN cd /usr/local/mysql/ && mkdir mysql-files && chmod 750 mysql-files 
RUN cd /usr/local/mysql/ && AFL_IGNORE_PROBLEMS=1 bin/mysqld --initialize-insecure --user=dobigthing 
RUN cd /usr/local/mysql/ && bin/mysql_ssl_rsa_setup

#ENTRYPOINT bash
#ENTRYPOINT /usr/local/mysql/bin/mysqld --basedir=/usr/local/mysql \
#            --datadir=/usr/local/mysql/data --log-error=err_log.err \
#            --pid-file=server_pid.pid --max_statement_time=1
RUN AFL_DEBUG=1 __AFL_SHM_ID=1234 /usr/local/mysql/bin/mysqld 2>&1 | grep "__afl_map_size" | tail -n 1 | cut -d"," -f8 | cut -d" " -f 3 > /tmp/mapsize
WORKDIR /home/Squirrel/scripts/utils
# ENTRYPOINT AFL_IGNORE_PROBLEMS=1 AFL_MAP_SIZE=$(cat /tmp/mapsize) python3 run.py mysql ../../data/fuzz_root/mysql_input/