-- cqlsh 192.168.33.10 < vm/setup.cql
drop keyspace if exists chart_development;
create keyspace chart_development with replication = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };

drop keyspace if exists chart_test;
create keyspace chart_test with replication = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
