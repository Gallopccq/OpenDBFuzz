FROM ubuntu:20.04
LABEL maintainer="OpenDBFuzz"
# common config
RUN sh -c "sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && apt-get update"
RUN apt-get update --yes && env DEBIAN_FRONTEND=noninteractive apt-get install openjdk-11-jdk maven git vim sudo postgresql-client-12  --yes --no-install-recommends

ENV MAVEN_MIRROR_URL="https://maven.aliyun.com/repository/public"
# ENV MAVEN_OPTS="-Dmaven.repo.local=/app/.m2/repository"


WORKDIR /home
RUN git clone https://gitee.com/mirrors_sqlancer/sqlancer.git && \
    cd sqlancer && git submodule update --init

WORKDIR /home/sqlancer
RUN mvn package -DskipTests

