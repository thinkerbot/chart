# Chart

Chart provides a way to create charts from xy data on a stream.

By default:

* Charts are made with d3 and are viewed in a browser via a javascript client
* The client polls for changes
* Pusher can be used to trigger a poll
* A rails app serves up the data
* Data is stored in a postgres database

The goal is to make a system where the following are possible:

* Different databases, in particular cassandra and sqlite
* Different push mechanisms

The data storage format and charting mechanism are the key technologies.  The goal is to make it possible to chart common variants of xy data, corresponding to different real-life collection strategies.  This includes:

* `t[y]`   (time, value(s)) - measurement
* `tr[y]`  (time, time of receipt, value(s)) - measurement with possibility of update
* `tpr[y]` (time, prediction time, time of receipt, value(s)) - prediction of measurements with possibility of update

In each case `time` could also be an arbitrary independent, unbounded dimension.

## Commands

* chart
* chart-console
* chart-import
* chart-export
* chart-server
* chart-pusher

Usage patterns:

  touch ~/.chartrc
  chart server &
  chart import < data.csv | chart pusher
  chart export < query

Expect any and all of these parts could be run on different servers.

## chart-console

Connect to back end storage in a consistent way.  Initialize classes for interactive use.

## chart-import

Store data.  Make reasonable guesses so it can be used easily, without options.

Input format:

    printf "%s,%s\n" x y        # create xry topic, guess types from first line
    printf "%s,%s,%s\n" id x y  # create xry topic id, if needed.

Output format

    N TOPIC_ID  # N rows inserted in last second, 0 on create

The input format is csv.  The topic can be inline or set for a run.  The inline version is designed for long running importers.

The output format designed as a notification to clients detailing which topics can be updated with a request, and the number of rows that may be fetched.  Topic ids should be used in the channel descriptions to make this happen via pusher.  Ideally one client makes the request and others fetch a cached version (ie there would be some kind of time offset for most clients).  In the case where the topic id is generated during the run the output format is used to communicate what was generated.

## chart-export

Query data and transform if needed.  Stream by line, or `-e` for a single run.

Input format:

    ID,URL

Output format:

    ??

Not sure who the consumer for export data should be.  Long running exporter?  More thought needed.  At very least a single query is needed in a simple fashion so you can get a csv.

## chart-server

Start the rails app.
