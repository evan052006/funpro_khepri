-module(khepri_test_ets).
-export([init_khepri_test/0, fetch_default/0]).

init_khepri_test() ->
    khepri:start(),
    
    khepri:put([stock, wood, <<"lime tree">>], 150),
    
    ProjectionName = wood_stocks,
    ProjectionFun = fun([stock, wood, Kind], Stock) -> {Kind, Stock} end,
    Options = #{type => set, read_concurrency => true},
    Projection = khepri_projection:new(ProjectionName, ProjectionFun, Options),
    
    khepri:register_projection("/:stock/:wood/*", Projection).

fetch_default() ->
    ProjectionName = wood_stocks,
    khepri:put("/:stock/:wood/oak", 100),
    io:format("~p~n", [ets:lookup(ProjectionName, <<"oak">>)]),
    khepri:put("/:stock/:wood/oak", 80),
    io:format("~p~n", [ets:lookup(ProjectionName, <<"oak">>)]),
    khepri:delete("/:stock/:wood/oak"),
    io:format("~p~n", [ets:member(ProjectionName, <<"oak">>)]).
