FROM     ubuntu:14.04
MAINTAINER Wang Qiang <wangqiang8511@gmail.com>

# Last Package Update & Install
RUN apt-get update && apt-get install -y curl wget net-tools iputils-ping vim

# JDK
ENV JDK_URL http://download.oracle.com/otn-pub/java/jdk
ENV JDK_VER 8u51-b16
ENV JDK_VER2 jdk-8u51
ENV JAVA_HOME /usr/local/jdk
ENV PATH $PATH:$JAVA_HOME/bin
RUN cd $SRC_DIR && curl -LO "$JDK_URL/$JDK_VER/$JDK_VER2-linux-x64.tar.gz" -H 'Cookie: oraclelicense=accept-securebackup-cookie' \
 && tar xzf $JDK_VER2-linux-x64.tar.gz && mv jdk1* $JAVA_HOME && rm -f $JDK_VER2-linux-x64.tar.gz \
 && echo '' >> /etc/profile \
 && echo '# JDK' >> /etc/profile \
 && echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile \
 && echo 'export PATH="$PATH:$JAVA_HOME/bin"' >> /etc/profile \
 && echo '' >> /etc/profile

# Apache Hadoop
ENV SRC_DIR /opt
ENV HADOOP_URL http://archive.apache.org/dist/hadoop/common
ENV HADOOP_VERSION hadoop-2.4.1
ENV HADOOP_VERSION_NUM 2.4.1
RUN cd $SRC_DIR && wget "$HADOOP_URL/$HADOOP_VERSION/$HADOOP_VERSION.tar.gz" \
 && tar xzf $HADOOP_VERSION.tar.gz ; rm -f $HADOOP_VERSION.tar.gz

# Hadoop ENV
ENV HADOOP_PREFIX $SRC_DIR/$HADOOP_VERSION
ENV PATH $PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin
ENV HADOOP_MAPRED_HOME $HADOOP_PREFIX
ENV HADOOP_COMMON_HOME $HADOOP_PREFIX
ENV HADOOP_HDFS_HOME $HADOOP_PREFIX
ENV YARN_HOME $HADOOP_PREFIX
RUN echo '# Hadoop' >> /etc/profile \
 && echo "export HADOOP_PREFIX=$HADOOP_PREFIX" >> /etc/profile \
 && echo 'export PATH=$PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin' >> /etc/profile \
 && echo 'export HADOOP_MAPRED_HOME=$HADOOP_PREFIX' >> /etc/profile \
 && echo 'export HADOOP_COMMON_HOME=$HADOOP_PREFIX' >> /etc/profile \
 && echo 'export HADOOP_HDFS_HOME=$HADOOP_PREFIX' >> /etc/profile \
 && echo 'export YARN_HOME=$HADOOP_PREFIX' >> /etc/profile

# Postgresql for hive metastore
RUN apt-get update && apt-get install -y postgresql-9.3 libpostgresql-jdbc-java

# create metastore db, hive user and assign privileges
USER postgres
RUN /etc/init.d/postgresql start \
 && psql --command "CREATE DATABASE metastore;" \
 && psql --command "CREATE USER hive WITH PASSWORD 'hive';" \
 && psql --command "ALTER USER hive WITH SUPERUSER;" \
 && psql --command "GRANT ALL PRIVILEGES ON DATABASE metastore TO hive;"

# Apache Hive
USER root
ENV SRC_DIR /opt
ENV HIVE_URL http://archive.apache.org/dist/hive
ENV HIVE_VERSION hive-1.2.0
ENV HIVE_PREFIX  $SRC_DIR/$HIVE_VERSION

RUN cd $SRC_DIR \
  && wget $HIVE_URL/$HIVE_VERSION/apache-${HIVE_VERSION}-bin.tar.gz \
  && tar zxf apache-${HIVE_VERSION}-bin.tar.gz \
  && rm -rf apache-${HIVE_VERSION}-bin.tar.gz

## dev tools to build
#RUN apt-get update && apt-get install -y git libprotobuf-dev protobuf-compiler
#
## install maven
#RUN curl -s http://mirror.olnevhost.net/pub/apache/maven/binaries/apache-maven-3.2.1-bin.tar.gz | tar -xz -C /usr/local/
#RUN cd /usr/local && ln -s apache-maven-3.2.1 maven
#ENV MAVEN_HOME /usr/local/maven
#ENV PATH $MAVEN_HOME/bin:$PATH
#
## compile hive
#RUN cd /usr/local \
#  && wget $HIVE_URL/$HIVE_VERSION/apache-${HIVE_VERSION}-src.tar.gz \
#  && tar zxf apache-${HIVE_VERSION}-src.tar.gz \
#  && rm -rf apache-${HIVE_VERSION}-src.tar.gz
#RUN cd /usr/local/apache-${HIVE_VERSION}-src && /usr/local/maven/bin/mvn clean install -DskipTests -Phadoop-2,dist
#RUN tar -xf /usr/local/apache-${HIVE_VERSION}-src/packaging/target/apache-${HIVE_VERSION}-bin.tar.gz -C $SRC_DIR

# set hive environment
ENV HIVE_HOME $SRC_DIR/apache-${HIVE_VERSION}-bin
ENV HIVE_CONF $HIVE_HOME/conf
ENV PATH $HIVE_HOME/bin:$PATH
ENV HADOOP_HOME $HADOOP_COMMON_HOME

# add postgresql jdbc jar to classpath
RUN ln -s /usr/share/java/postgresql-jdbc4.jar $HIVE_HOME/lib/postgresql-jdbc4.jar

# to avoid psql asking password, set PGPASSWORD
ENV PGPASSWORD hive

# initialize hive metastore db
RUN /etc/init.d/postgresql start \
 && cd $HIVE_HOME/scripts/metastore/upgrade/postgres/ \
 && psql -h localhost -U hive -d metastore -f hive-schema-1.2.0.postgres.sql

# To overcome the bug in AUFS that denies postgres permission to read /etc/ssl/private/ssl-cert-snakeoil.key file.
# https://github.com/Painted-Fox/docker-postgresql/issues/30
# https://github.com/docker/docker/issues/783
# To avoid this issue lets disable ssl in postgres.conf. If we really need ssl to encrypt postgres connections we have to fix permissions to /etc/ssl/private directory everytime until AUFS fixes the issue
ENV POSTGRESQL_MAIN /var/lib/postgresql/9.3/main/
ENV POSTGRESQL_CONFIG_FILE $POSTGRESQL_MAIN/postgresql.conf
ENV POSTGRESQL_BIN /usr/lib/postgresql/9.3/bin/postgres
ADD conf/postgresql.conf $POSTGRESQL_MAIN
RUN chown postgres:postgres $POSTGRESQL_CONFIG_FILE

# Add in the etc/hadoop directory
ADD conf/core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
ADD conf/hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml
ADD conf/yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml
ADD conf/mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD conf/hive-site.xml $HIVE_CONF/hive-site.xml
ADD conf/hive-log4j.properties $HIVE_CONF/hive-log4j.properties
RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/local/jdk:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

ADD scripts /scripts

# Dont confuse the version check
ENV HADOOP_VERSION $HADOOP_VERSION_NUM
# See here https://issues.apache.org/jira/browse/HIVE-8609
ENV HADOOP_USER_CLASSPATH_FIRST=true

ENTRYPOINT ["/scripts/setup.sh"]
