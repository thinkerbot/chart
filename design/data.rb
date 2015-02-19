## Summary

Many types of functions produce data amenable for charting in the xy dimensions.  These functions are defined as `f(x[n]) = y`.  To transform this function into an `f(x) = y` function, provide a projection that takes a set of `(x[n], y)` values and picks a single `(x,y)` pair.  In practice the set `(x[n], y)` values must be limited to fit within memory/runtime bounds... ergo for a given x there must be a limited number of x[n-1].

In summary a projection can produce xy data from x[n]y data provided:

* there is one value y for each (x[n])
* the number of x[n-1] is limited for a given x

Many types of data end up satisfying these conditions, in particular measurement data.  Measurement data can be modeled as ty.  If measurement data can be overridden then add a dimension to track when the data was recieved, ie tty.

Extending this basic model, projections can take the form `(x[n], y) => (X[n-m], Y)`.

## Definitions

* `x[n]`: the independent dimensions where n = [1,)
* `y`: the dependent dimension
* `c`: a count dimension
* `t`: a time dimension
* `f(x[n]) = y`: a function with independent dimensions x[n] yielding a single value y
* `(x[n], y) => (X[n-m], Y)`: a projection reducing the number of independent dimensions by m = [0,n] dimensions (note that the xy definitions may change)

## Example xy

The simplest case is just xy data.  Repeated inserts of y values for a given x overwrite.  No projection is needed.  There is a possible projection however, from xy to yc data (ie histogram data).

     x y                       y c
     1 1                       1 1
     2 2                       2 2
     3 3                       3 3
     4 4                       4 3
     5 5                       5 2
     6 4     
     7 3     
     8 2     
     9 3     
    10 4    
    11 5    

    y                          c           
    |     /\    /              |                                     
    |    /  \  /               |      | |                      
    |   /    \/                |    | | | |                      
    |  /                       |  | | | | |                   
    +____________________ x    +____________________ y 
                               (within a range of x)


## Example xty

This is xy data but where the time of insert is recorded, thereby preventing overwrites (or conversely allowing corrections).  All inserts are preserved provided the inserts happen at different times.  A projection is needed to pick xy data, typically by picking latest (ie greatest t) value for a given x: "group by x, pick greatest t".  A further projection is possible to histogram data.


     x t y                        x y                       y c
     1 1 1                        1 1                       1 1
     2 1 2                        2 2                       2 2
     3 1 3                        3 3                       3 3
     4 1 4                        4 4                       4 3
     5 1 3 (.)                    5 5                       5 2
     6 1 4                        6 4     
     7 1 3                        7 3     
     8 1 1 (.)                    8 2     
     9 1 3                        9 3     
    10 1 4                       10 4    
    11 1 5                       11 5    
     5 2 5 (*)
     8 2 2 (*)

    y      *                    y                          c           
    |     . .    .              |     /\    /              |                          
    |    . . .  .               |    /  \  /               |      | |                 
    |   .     *                 |   /    \/                |    | | | |               
    |  .      .                 |  /                       |  | | | | |               
    +____________________ x     +____________________ x    +____________________ y 
                                 (group x, greatest t)     (within a range of x)

    Note the values might need to be bucketized first.
    
## Example xiy

This is xy data where a set of xy data is measured multiple times.  Many projections are possible.


    y                i1 (.)     y                          c                
    |     *     +    i2 (*)     |     /\    /              |                           
    |    ..*  *+     i3 (+)     |    /  \  /               |      | |                  
    |   .   * +                 |   /    \/                |    | | | |            
    |  .     *                  |  /                       |  | | | | |            
    +___________________ x      +____________________ x    +____________________ y 
                                 (group x, greatest i)     (within a range of x)
    
    * average
    * sum
    * greatest
    * least

    Note the values might need to be bucketized first.