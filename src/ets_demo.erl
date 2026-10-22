-module(ets_demo).
-export([run/0]).

run() ->
    Table = ets:new(user_cache, [set, public, named_table]),

    ets:insert(Table, {1, <<"alice">>, admin}),
    ets:insert(Table, {2, <<"bob">>, member}),
    ets:insert(Table, {3, <<"charlie">>, member}),

    User1 = ets:lookup(Table, 1),
    io:format("Lookup Key 1: ~p~n", [User1]),

    Members = ets:match_object(Table, {'_', '_', member}),
    io:format("Members: ~p~n", [Members]),

    ets:delete(Table, 2),
    User2 = ets:lookup(Table, 2),
    io:format("Lookup Key 2 setelah dihapus: ~p~n", [User2]),

    ets:delete(Table),
    ok.