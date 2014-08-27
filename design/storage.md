# Storage

Many types of interesting chart data can be represented by [x,y] pairs,
especially if you allow arbitrary x/y types. For example:

* Lines (num,num) (time,num)
* Pie charts (varchar,num)
* Histograms (num,num)
* Graphs (varchar,varchar)

Adding a time dimension (generically 'z' but more easily represented as 't')
allows for chart data that progresses through time.  Example:

    t x y
    -----
    1 1 1
    1 2 2
    2 2 1
    2 3 2
    3 3 1
    3 4 2

## Cassandra Storage

This data can be stored in tables of this format, where xpart is a partition
key based on the x value for example `x.to_i/100` for a numeric x:

    create table xyt (
      xpart int,
      x     int,
      t     int,
      y     int,
      PRIMARY KEY (xpart, x, t)
    );

This format allows the data to be fetched based on an x value or range, which
is typically what you need in order to create a chart... "all data given a
particular range of the independent variable".

    select * from xyt where xpart = 0 and x = 2;
    select * from xyt where xpart = 0 and x >= 2 and x < 4;

Time is used in the primary key to distinguish new and old data, but is not
particularly useful in queries given that x must be specified with EQ in order
to make a direct query. This fact highlights the need for post processing of
the raw data into forms useful to a charting library (the processing cannot be
done in the query as is possible with, say, Postgres).

Note the storage format can be generalized by adding an id, thus allowing a
single table to hold multiple datasets. 

## Processing for Charts

Processing charts that progress in time means grouping and filtering to get
the a particular snapshot of the chart. All the interesting variations I can
think of a this time begin by grouping the data according to x, reflecting the
final presentation of some (x,y) data.

To get all data at a given point, group by x.

    x1:
      t1: y1
    x2:
      t1: y2
      t2: y1
    x3:
      t2: y2
      t3: y1
    x4:
      t3: y2

To get the most current data, select y at max t.

    x1: y1
    x2: y1
    x3: y1
    x4: y2

To calculate stats apply a function on all y at a given x.

    x1: avg(y1)
    x2: avg(y2,y1)
    x3: avg(y2,y1)
    x4: avg(y2)

To calculate the progression of the data (envision a time slider to
rewind/fast-forward the data) select y at each t <= tn.

    t1:
      x1: y1
      x2: y2

    t2:
      x1: y1
      x2: y1
      x3: y2

    ...

Note that if you change the x range, or allow time to progress, then you will
have to send patches to the data. In some cases it might be best to keep all
the data in the chart, and update it live.  This may be feasible with d3.

## Processing for Replay

To see all the changes for a particular x range, query on x and group by t.
The downside of this approach is that it MUST be limited by an x range --
there is no efficient way to limit it by t. Indeed if there is a need for this
type of query then it suggests that x and t should be swapped in the storage.
If both types of queries are needed then the data should be stored twice.

    t1:
      x1: y1
      x2: y2
    t2:
      x2: y1
      x3: y2
    t3:
      x3: y1
      x4: y2

## UUIDs

A uuid (or similar) can be added to the primary key if it is possible for
multiple entries at the same (x,y,t), for instance if a source reports
multiple times. The requirements of the uuid could be set by the application
-- for instance a time-server pair could work both as the uuid and a log of
receipt.

    t x y u
    -----
    1 1 1 1
    1 2 2 2
    2 2 1 3
    2 3 2 4
    3 3 1 5
    3 4 2 6
    1 1 0 7
    1 2 0 8

In that case data needs to be grouped by x then t. Some function needs to
exist to pick amongst the uuid keys (say greatest time of receipt and then
arbitrary server), at which point you're back to the situation above.

    x1:
      t1:
        u1: y1
        u7: y0
    x2:
      t1:
        u2: y2
        u8: y0
      t2:
        u3: y1
    x3:
      t2:
        u4: y2
      t3:
        u5: y1
    x4:
      t3:
        u6: y2
    
# Generic Form ND data with MD projection

Table allowing for multiple topics, and overwrite.

    create table xyz (
      topic varchar,
      xpart int,
      x     int,
      z     int,
      y     int,
      u     uuid,
      PRIMARY KEY ((topic, xpart), x, z, u)
    );

Generic algorithm:

* Group by cluster keys
* Query by independent axis (first N cluster keys)
* Resolve at remaining keys to get value
* Graphs designed to get {set: {N1: {N2:... {N: V}}}}

