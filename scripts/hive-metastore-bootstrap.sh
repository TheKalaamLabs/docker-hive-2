#!/bin/bash

echo "Starting postgresql server..."
sudo -u postgres $POSTGRESQL_BIN --config-file=$POSTGRESQL_CONFIG_FILE &

sleep 10

# start hive metastore server
$HIVE_HOME/bin/hive --service metastore
