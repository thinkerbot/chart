#!/bin/bash
set -ex

# https://www.digitalocean.com/community/tutorials/how-to-install-java-on-ubuntu-with-apt-get
apt-get update
apt-get install -y openjdk-7-jdk
printf "JAVA_HOME=/usr/lib/jvm/java-7-openjdk-i386/jre/bin/java" >> /etc/environment
source /etc/environment

# http://www.datastax.com/documentation/getting_started/doc/getting_started/gettingStartedDeb_t.html
apt-get install -y curl
echo "deb http://debian.datastax.com/community stable main" >> /etc/apt/sources.list.d/cassandra.sources.list
curl -L http://debian.datastax.com/debian/repo_key | apt-key add -
apt-get update
apt-get install -y dsc21

LOCAL_IP_ADDR=192.168.33.10
sed -i="" -e "
  s/listen_address:.*\$/listen_address: ${LOCAL_IP_ADDR}/g
  s/rpc_address:.*\$/rpc_address: ${LOCAL_IP_ADDR}/g
  s/seeds:.*\$/seeds: ${LOCAL_IP_ADDR}/g
  s/-Xss180k/-Xss280k/g
" /etc/cassandra/cassandra.yaml

service cassandra stop
service cassandra start
