FROM ubuntu:20.04
LABEL maintainer="OpenDBFuzz"
# common config
RUN sh -c "sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && apt-get update"
RUN mkdir -p ~/.m2 && printf '<?xml version="1.0" encoding="UTF-8"?>\n<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"\n    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n    xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">\n <mirrors>\n <mirror>\n    <id>nexus-aliyun</id>\n      <mirrorOf>central</mirrorOf>\n       <name>Nexus aliyun</name>\n       <url>http://maven.aliyun.com/nexus/content/groups/public</url>\n   </mirror>\n  </mirrors>\n</settings>' > ~/.m2/settings.xml

RUN apt-get update --yes && env DEBIAN_FRONTEND=noninteractive apt-get install openjdk-11-jdk maven git vim sudo  --yes --no-install-recommends

WORKDIR /home
RUN git clone https://gitee.com/qeeger/dqetool.git && \
    cd dqetool && git submodule update --init

WORKDIR /home/dqetool
RUN mvn package -DskipTests