-- cqlsh 192.168.33.10 < vm/setup.cql

drop keyspace if exists chart_development;
create keyspace chart_development with replication = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
use chart_development;

drop table if exists charts;
create table charts (
  id    varchar,
  n     varchar,
  xpart varchar,
  x     varchar,
  z     varchar,
  y     varchar,
  primary key ((id, n, xpart), x, z)
);
