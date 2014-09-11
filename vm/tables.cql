drop table if exists charts;
create table charts (
  id      varchar,
  configs varchar,
  primary key (id)
);

drop table if exists chart_data;
create table chart_data (
  xp varchar,
  id varchar,
  n  varchar,
  x  varchar,
  z  varchar,
  y  varchar,
  primary key ((xp, id, n), x, z)
);
