# khepri_test

Demo app for 

## Dev tool installation

## Windows
1. Install Erlang from this link.

    https://github.com/erlang/otp/releases/download/OTP-29.1.2/otp_win64_29.1.2.exe

2. Follow Windows steps to install Rebar3 (its just a portable executable)

    https://rebar3.org/docs/getting-started/

## Ubuntu/Debian-based Linux distro
1. Install Erlang
```bash
sudo apt install erlang
```

2. Install Rebar3
```bash
sudo apt install rebar3
```

## Other OSes
Follow the guide on https://www.erlang.org/downloads and https://rebar3.org/docs/getting-started/ for your OS.

## Run Individual Script

1. Open Rebar3 shell
```bash
rebar3 shell
```

2. Run the file you would want to run. For example, to run [`src/ets_demo.erl`](src/ets_demo.erl):
```erlang
ets_demo:run().
```

## Build
``` bash
rebar3 compile
```