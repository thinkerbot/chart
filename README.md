# Chart

Make charts from the command line.

## Development

Setup the vm:

    vagrant up

Setup config files:

    ln -s cassandra.yml.example config/cassandra.yml
    ln -s postgres.yml.example config/postgres.yml
    ln -s cassandra.yml config/database.yml

Migrate:

    chart-console -q -k - < db/cassandra/setup.cql  # one-time

    mkdir -p tmp/db/cassandra
    bundle exec ruby -rerb -e 'puts ERB.new(STDIN.read, nil, "<>").result' < db/cassandra/tables.cql.erb > tmp/db/cassandra/tables.cql
    chart-console -q < tmp/db/cassandra/tables.cql
    chart-console -q -e test < tmp/db/cassandra/tables.cql
