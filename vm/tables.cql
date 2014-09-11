drop table if exists charts;
create table charts (
  id      varchar,
  configs varchar,
  primary key (id)
);

drop table if exists chart_data;
create table chart_data (
  xp varint,
  id varchar,
  n  varchar,
  x  varint,
  z  varint,
  y  varint,
  primary key ((xp, id, n), x, z)
)
with clustering order by (
  x desc,
  z desc
);
