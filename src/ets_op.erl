-module(ets_op).
-export([create_tuple_ets/0, create_string_ets/0]).

create_string_ets() ->
    Ord_set = ets:new(cont, [ordered_set]),
    ets:insert(Ord_set, {<<"/a/d/z">>, 1}),
    ets:insert(Ord_set, {<<"/a/b">>, 2}),
    ets:insert(Ord_set, {<<"/a/b/c">>, 3}),
    Ord_set.

create_tuple_ets() ->
    Ord_set = ets:new(cont, [ordered_set]),
    ets:insert(Ord_set, {{a, d, z}, 1}),
    ets:insert(Ord_set, {{a, b}, 2}),
    ets:insert(Ord_set, {{a, b, c}, 3}),
    Ord_set.


