# Chart

Make charts from the command line.

## Development

Setup the vm:

   vagrant up

Setup config files:

   ln -s database.yml.example config/database.yml

Migrate:

   chart-console -q -k - < vm/setup.cql
