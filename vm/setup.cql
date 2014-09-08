-- cqlsh 192.168.33.10 < vm/setup.cql

# drop keyspace if exists chart_development;
create keyspace chart_development with replication = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
use chart_development;

# drop table if exists charts;
create table charts (
  id      varchar,
  configs varchar,
  primary key (id)
);

# drop table if exists chart_data;
create table chart_data (
  id varchar,
  n  varchar,
  xp varchar,
  x  varchar,
  z  varchar,
  y  varchar,
  primary key ((id, n, xp), x, z)
);
