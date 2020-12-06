FROM elixir:slim

WORKDIR /app

RUN apt-get update && \
  apt-get install -y make && \
  # mix hex.config mirror_url https://cdn.jsdelivr.net/hex && \
  mix local.hex --force && \
  mix local.rebar --force

CMD ["iex"]
