#!/usr/bin/env bash
set -ex

#######################################
# Runs as root
#######################################
cat > /etc/default/locale <<"DOC"
LANG="en_US.UTF-8"
LANGUAGE=
LC_CTYPE="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_PAPER="en_US.UTF-8"
LC_NAME="en_US.UTF-8"
LC_ADDRESS="en_US.UTF-8"
LC_TELEPHONE="en_US.UTF-8"
LC_MEASUREMENT="en_US.UTF-8"
LC_IDENTIFICATION="en_US.UTF-8"
LC_ALL=
DOC
source /etc/default/locale

#######################################
# Prerequisites
########################################

# add postgres packages
mkdir -p /etc/apt/sources.list.d
cat > /etc/apt/sources.list.d/pgdg.list <<DOC
deb http://apt.postgresql.org/pub/repos/apt/ squeeze-pgdg main
DOC
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

apt-get update

# Developer tools
apt-get -y install vim
apt-get -y install expect

#
# Install postgres
#

apt-get -y install postgresql-9.3

# Fix authentication method for database
sed -i.bak -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'    /" /etc/postgresql/9.3/main/postgresql.conf
sed -i.bak -f - /etc/postgresql/9.3/main/pg_hba.conf <<EOS
  /local \{1,\}all \{1,\}all/s/peer/trust/
  /host \{1,\}all \{1,\}all/s/md5/trust/
  /host \{1,\}all \{1,\}all/s/127.0.0.1\/32/0.0.0.0\/0/
EOS
service postgresql restart

# Create development database
sudo -u postgres createdb development
sudo -u postgres createuser --superuser development
sudo -u postgres expect -f - <<DOC
spawn psql -U development -d development
expect "development=#" { send "\\\\password development\r" }
expect "Enter new password:" { send "development\r" }
expect "Enter it again:" { send "development\r" }
DOC

# Create test database
sudo -u postgres createdb test
sudo -u postgres createuser --superuser test
sudo -u postgres expect -f - <<DOC
spawn psql -U test -d test
expect "test=#" { send "\\\\password test\r" }
expect "Enter new password:" { send "test\r" }
expect "Enter it again:" { send "test\r" }
DOC