-module(ets_rw_test).
-export([run/0, run/3]).

%% Default run with concurrency enabled
run() ->
    run([{read_concurrency, true}, {write_concurrency, true}], 10, 10).

%% Run with custom ETS concurrency flags
run(Options, NumReaders, NumWriters) ->
    %% 1. Create an ETS table with the specified concurrency options
    %% 'named_table' lets us reference it by atom name instead of passing TableId everywhere
    %% 'public' allows any process to read/write to it
    TableId = ets:new(my_cache, [named_table, public, set | Options]),
    
    %% Initialize data
    ets:insert(TableId, {data_key, 0}),
    
    io:format("Starting ETS concurrency test with options: ~p~n", [Options]),

    Parent = self(),

    %% Spawn Reader processes
    ReaderPids = [
        spawn_link(fun() -> reader_loop(I, 5, Parent) end)
        || I <- lists:seq(1, NumReaders)
    ],

    %% Spawn Writer processes
    WriterPids = [
        spawn_link(fun() -> writer_loop(I, 3, Parent) end)
        || I <- lists:seq(1, NumWriters)
    ],

    %% Wait for all workers to finish
    AllPids = ReaderPids ++ WriterPids,
    wait_all(AllPids),

    io:format("All reader/writer processes completed. Final data: ~p~n", 
              [ets:lookup_element(TableId, data_key, 2)]),
    
    %% Clean up table
    ets:delete(TableId),
    ok.

%% Reader loop
reader_loop(ReaderId, 0, Parent) ->
    Parent ! {done, self()};
reader_loop(ReaderId, Count, Parent) ->
    %% Read from ETS natively (thread-safe, concurrent)
    case ets:lookup(my_cache, data_key) of
        [{data_key, Val}] ->
            io:format("Reader ~p reads data: ~p~n", [ReaderId, Val]);
        [] ->
            io:format("Reader ~p: data not found~n", [ReaderId])
    end,
    %% Simulate read delay (50ms - 100ms)
    timer:sleep(rand:uniform(50) + 50),
    reader_loop(ReaderId, Count - 1, Parent).

%% Writer loop
writer_loop(WriterId, 0, Parent) ->
    Parent ! {done, self()};
writer_loop(WriterId, Count, Parent) ->
    io:format("Writer ~p is writing...~n", [WriterId]),
    
    %% Atomic update in ETS using update_counter/3
    %% This safely increments the value without explicit locks
    NewVal = ets:update_counter(my_cache, data_key, {2, 1}),
    
    io:format("Writer ~p finished writing. New data: ~p~n", [WriterId, NewVal]),
    
    %% Simulate write delay (50ms - 100ms)
    timer:sleep(rand:uniform(50) + 50),
    writer_loop(WriterId, Count - 1, Parent).

%% Helper to wait for all processes to report back
wait_all([]) ->
    ok;
wait_all([Pid | Rest]) ->
    receive
        {done, Pid} -> wait_all(Rest)
    end.
