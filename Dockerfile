# Étape 1 : build
FROM elixir:1.18-slim AS build

RUN apt-get update -y && apt-get install -y build-essential git curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

RUN mkdir config
COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

RUN mix compile
RUN mix assets.setup
RUN mix assets.deploy
COPY config/runtime.exs config/
RUN mix release

# Étape 2 : même image de base que le build pour garantir la compatibilité GLIBC/OpenSSL
FROM elixir:1.18-slim

RUN apt-get update -y && \
    apt-get install -y locales ca-certificates curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

RUN chown nobody /app

ENV MIX_ENV="prod"
ENV PHX_SERVER=true

COPY --from=build --chown=nobody:root /app/_build/prod/rel/chatgpt ./

USER nobody

EXPOSE 4000

CMD ["/app/bin/chatgpt", "start"]
