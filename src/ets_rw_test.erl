-module(ets_rw_test).
-export([run/0, run/4]).

%% Default run with concurrency disabled
run() ->
    run(false, false, 100000, 10).

run(ReadCon, WriteCon, NumReaders, NumWriters) ->
    Options = [{read_concurrency, ReadCon}, {write_concurrency, WriteCon}],
    TableId = ets:new(my_cache, [named_table, public, set | Options]),
    
    ets:insert(TableId, {data_key, 0}),
    
    io:format("Starting ETS concurrency test...~n"),
    io:format("Read Concurrency: ~p | Write Concurrency: ~p~n", [ReadCon, WriteCon]),
    io:format("Readers: ~p | Writers: ~p~n", [NumReaders, NumWriters]),

    Parent = self(),

    %% Capture starting statistics
    %% statistics(runtime) measures CPU time. 
    %% statistics(wall_clock) measures actual elapsed real-world time.
    {StartRuntime, _} = statistics(runtime),
    {StartWallclock, _} = statistics(wall_clock),

    %% Spawn Reader processes
    ReaderPids = [
        spawn_link(fun() -> reader_loop(NumReaders, Parent) end)
        || _ <- lists:seq(1, NumReaders)
    ],

    %% Spawn Writer processes
    WriterPids = [
        spawn_link(fun() -> writer_loop(NumWriters, Parent) end)
        || _ <- lists:seq(1, NumWriters)
    ],

    %% Wait for all workers to finish
    AllPids = ReaderPids ++ WriterPids,
    wait_all(AllPids),

    %% Capture ending statistics
    {EndRuntime, _} = statistics(runtime),
    {EndWallclock, _} = statistics(wall_clock),

    Runtime = EndRuntime - StartRuntime,
    Wallclock = EndWallclock - StartWallclock,

    io:format("All reader/writer processes completed.~n"),
    io:format("Final data: ~p~n", [ets:lookup_element(TableId, data_key, 2)]),
    io:format("Total Runtime (CPU time): ~p ms~n", [Runtime]),
    io:format("Total Wallclock time: ~p ms~n", [Wallclock]),
    
    %% Clean up table
    ets:delete(TableId),
    ok.

%% Reader loop
reader_loop(0, Parent) ->
    Parent ! {done, self()};
reader_loop(Count, Parent) ->
    ets:lookup(my_cache, data_key),
    % timer:sleep(rand:uniform(50) + 50),
    reader_loop(Count - 1, Parent).

%% Writer loop
writer_loop(0, Parent) ->
    Parent ! {done, self()};
writer_loop(Count, Parent) ->
    ets:update_counter(my_cache, data_key, {2, 1}),
    % timer:sleep(rand:uniform(50) + 50),
    writer_loop(Count - 1, Parent).

%% Helper to wait for all processes to report back
wait_all([]) ->
    ok;
wait_all([Pid | Rest]) ->
    receive
        {done, Pid} -> wait_all(Rest)
    end.
