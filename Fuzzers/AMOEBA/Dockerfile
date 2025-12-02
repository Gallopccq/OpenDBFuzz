FROM icsesub2022/paper360:artifact1
LABEL maintainer="OpenDBFuzz"
WORKDIR  /workspace/calcite-fuzzing
RUN ./gradlew build -x core:checkstyleMain -x test -x core:checkstyleTest -x core:forbiddenApisTest -x core:autostyleJavaCheck
RUN mkdir -p /home/postgres/exps && chown postgres:postgres -R /home/postgres/exps