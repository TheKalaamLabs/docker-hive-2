CREATE DATABASE IF NOT EXISTS test;
USE test;
CREATE EXTERNAL TABLE simpletest (key STRING, value INT)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION 'hdfs:///tmp/test';