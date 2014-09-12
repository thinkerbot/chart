drop table if exists topics;
create table topics (
  id     varchar,
  config varchar,
  primary key (id)
);

drop table if exists iii_data;
create table iii_data (
  xp varint,
  id varchar,
  x  varint,
  z  varint,
  y  varint,
  primary key ((xp, id), x, z)
)
with clustering order by (
  x desc,
  z desc
);
