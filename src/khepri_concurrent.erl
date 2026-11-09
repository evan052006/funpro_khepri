-module(khepri_concurrent).

-export([run/3, run/5, writer_init/4, writer_loop/2, reader_init/2, reader_loop/2]).

%% ===================================================================
%% Entry Point (With Defaults)
%% ===================================================================

run(T, K, ReaderNum) ->
    InitProducts = [apple, banana, orange, milk, bread],
    AddProducts = [grape, mango, pineapple, coffee, cheese],
    
    io:format("Starting Khepri demo for ~p seconds.~n", [T]),
    io:format("Initial catalog: ~p items.~n", [length(InitProducts)]),
    io:format("Adding a new product every ~p seconds.~n", [K]),
    io:format("Spawning ~p concurrent ETS readers.~n", [ReaderNum]),
    
    run(T, K, InitProducts, AddProducts, ReaderNum).

run(T, K, InitProducts, AddProducts, ReaderNum) ->
    %% Ensure Khepri is running
    application:ensure_all_started(khepri),
    khepri:start(),

    ProjFun = fun
        (#{total_products := TotalTid, latest_product := LatestTid}, 
         [products, ProdName], OldProps, NewProps) ->
            
            IsInsert = maps:is_key(data, NewProps),
            IsDelete = maps:is_key(data, OldProps) andalso not maps:is_key(data, NewProps),
            
            if
                IsInsert ->
                    ets:update_counter(TotalTid, count, 1, {count, 0}),
                    ets:insert(LatestTid, {latest, ProdName});
                IsDelete ->
                    ets:update_counter(TotalTid, count, -1, {count, 0});
                true -> 
                    ok
            end
    end,

    ProjOpts = #{
        tables => #{
            total_products => #{read_concurrency => true}, 
            latest_product => #{read_concurrency => true}
        }
    },
    
    Projection = khepri_projection:new(product_stats, ProjFun, ProjOpts),
    
    khepri:register_projection([products, '*'], Projection),

    PrintFlags = [true | lists:duplicate(max(1, ReaderNum) - 1, false)],
    [spawn(?MODULE, reader_init, [T, Print]) || Print <- PrintFlags],

    spawn(?MODULE, writer_init, [T, K, InitProducts, AddProducts]),
    
    ok.

%% ===================================================================
%% Writer Thread
%% ===================================================================

writer_init(T, K, InitProducts, AddProducts) ->
    %% Write the initial batch
    lists:foreach(
        fun(Prod) -> khepri:put([products, Prod], Prod) end, 
        InitProducts
    ),
    io:format("[Writer] Initial products inserted.~n"),
    
    erlang:send_after(T * 1000, self(), stop),
    erlang:send_after(K * 1000, self(), tick_add),
    
    writer_loop(K, AddProducts).

writer_loop(K, AddProducts) ->
    receive
        tick_add ->
            case AddProducts of
                [NewProd | Rest] ->
                    khepri:put([products, NewProd], NewProd),
                    erlang:send_after(K * 1000, self(), tick_add),
                    writer_loop(K, Rest);
                [] ->
                    writer_loop(K, [])
            end;
            
        stop ->
            khepri:delete([products]),
            io:format("[Writer] ~p seconds elapsed. Deleted [products] tree. Shutting down.~n", [K]),
            ok
    end.

%% ===================================================================
%% Dashboard Reader Thread
%% ===================================================================

reader_init(T, PrintFlag) ->
    erlang:send_after(T * 1000, self(), stop),
    
    %% Start loop with Tick = 0
    reader_loop(PrintFlag, 0).

reader_loop(PrintFlag, Tick) ->
    receive
        stop ->
            if PrintFlag -> io:format("[Reader] Shutting down.~n"); true -> ok end,
            ok
    after 10 ->
        TotalCount = case catch ets:lookup(total_products, count) of
            [{count, C}] -> C;
            _ -> 0
        end,
        
        Latest = case catch ets:lookup(latest_product, latest) of
            [{latest, Prod}] -> Prod;
            _ -> none
        end,
        
        %% Throttle prints: Only print every 100 ticks (1 second) to prevent terminal locking
        if 
            PrintFlag andalso (Tick rem 100 == 0) -> 
                io:format("[Dashboard] Total Products: ~p | Latest Insert: ~p~n", [TotalCount, Latest]);
            true -> 
                ok 
        end,
        
        reader_loop(PrintFlag, Tick + 1)
    end.
