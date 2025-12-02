FROM ubuntu:20.04
LABEL maintainer="OpenDBFuzz"
ENV TZ=America/New_York
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN sh -c "sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && apt-get update"
RUN apt-get update
RUN apt-get -y install wget ca-certificates sudo gnupg curl git lsb-release net-tools
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RUN sh -c 'echo "deb http://mirrors.zju.edu.cn/postgresql/repos/apt/ $(lsb_release -cs)-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
RUN apt-get update
RUN apt-get -y install postgresql-11 postgresql-9.6 postgresql-contrib

WORKDIR /home
RUN git clone   https://gitee.com/alwsgallop/apollo.git && \
   cd apollo && git submodule update --init
WORKDIR /home/apollo/
RUN sh -c "sed -i 's/sudo apt-get install /sudo apt-get install -y pip /g' install-deps.sh"
# RUN sh -c "sed -i 's/pip install/pip install --break-system-packages/g' install-deps.sh"
RUN bash install-deps.sh
RUN mkdir -p src/sqlmin
RUN bash compile-libs-20.sh