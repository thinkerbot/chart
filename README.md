# Chart

Make charts from the command line.

## Development

Setup the vm:

   vagrant up

Setup config files:

   ln -s database.yml.example config/database.yml

Migrate:

   bundle exec ruby -rerb -e 'puts ERB.new(STDIN.read, nil, "<>").result' < vm/tables.cql.erb > vm/tables.cql
   chart-console -q -k - < vm/setup.cql  # one-time
   chart-console -q < vm/tables.cql
   chart-console -q -e test < vm/tables.cql
