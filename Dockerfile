FROM hexpm/elixir:1.15.5-erlang-26.0.2-ubuntu-jammy-20230126

ARG REPOSITORY

RUN apt-get update && \
    apt-get install -yq bash openssl libssl-dev git

WORKDIR /root/graph_conn

COPY mix.* .

RUN mix local.rebar --force && \
    mix local.hex --force && \
    mix deps.get && \
    mix compile

CMD pwd && mix deps.get && iex --sname mock -S mix
