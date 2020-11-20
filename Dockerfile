FROM elixir:slim

WORKDIR /app

RUN apt-get update && apt-get install -y make

CMD ["iex"]
