# Chart

Make charts from the command line.

## Development

Setup the vm:

    vagrant up

Setup config files:

    ln -s cassandra.example config/development/cassandra
    ln -s postgres.example  config/development/postgres
    ln -s cassandra.example config/test/cassandra
    ln -s postgres.example  config/test/postgres
    ln -s config/development/cassandra .chartrc

Migrate:

    chart-console -q -k - < db/cassandra/setup.cql  # one-time

    mkdir -p tmp/db/cassandra
    bundle exec ruby -rerb -e 'puts ERB.new(STDIN.read, nil, "<>").result' < db/cassandra/tables.cql.erb > tmp/db/cassandra/tables.cql
    chart-console -q < tmp/db/cassandra/tables.cql
    chart-console -q -e test < tmp/db/cassandra/tables.cql
