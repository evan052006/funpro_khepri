-module(khepri_demo).
-export([run/0]).

run() ->
    io:format("=== 1. Starting Khepri ===~n"),
    {ok, _} = khepri:start(),

    io:format("~n=== 2. Create / Update (Put) ===~n"),
    ok = khepri:put([app, settings, theme], <<"dark">>),
    ok = khepri:put([app, settings, language], <<"indonesian">>),
    ok = khepri:put([users, <<"alice">>, email], <<"alice@example.com">>),
    ok = khepri:put([users, <<"bob">>, email], <<"bob@example.com">>),
    io:format("Data berhasil dimasukkan.~n"),

    io:format("~n=== 3. Read (Get) ===~n"),
    {ok, ThemeResult} = khepri:get([app, settings, theme]),
    io:format("Get theme: ~p~n", [ThemeResult]),

    {ok, AllEmails} = khepri:get([users, {if_name_matches, ".*"}, email]),
    io:format("Get semua email user (wildcard): ~p~n", [AllEmails]),

    {ok, SettingsTree} = khepri:get([app, settings, '**']),
    io:format("Get semua settings (rekursif): ~p~n", [SettingsTree]),

    io:format("~n=== 4. Atomic Transaction (khepri_tx) ===~n"),
    ok = khepri:put([accounts, <<"alice">>, balance], 1000),
    ok = khepri:put([accounts, <<"bob">>, balance], 500),

    TxResult = khepri:transaction(fun() ->
        {ok, BalA} = khepri_tx:get([accounts, <<"alice">>, balance]),
        {ok, BalB} = khepri_tx:get([accounts, <<"bob">>, balance]),
        
        ok = khepri_tx:put([accounts, <<"alice">>, balance], BalA - 200),
        ok = khepri_tx:put([accounts, <<"bob">>, balance], BalB + 200),
        {BalA - 200, BalB + 200}
    end),
    io:format("Hasil Transaksi (Transfer 200 dari Alice ke Bob): ~p~n", [TxResult]),

    io:format("~n=== 5. Delete ===~n"),
    ok = khepri:delete([app, settings, theme]),
    io:format("Menghapus [app, settings, theme].~n"),

    ok = khepri:delete([users, <<"bob">>]),
    io:format("Menghapus subtree [users, <<\"bob\">>].~n"),

    {ok, RemainingUsers} = khepri:get([users, '**']),
    io:format("Sisa data user: ~p~n", [RemainingUsers]),

    io:format("~n=== Demo Selesai ===~n"),
    ok.