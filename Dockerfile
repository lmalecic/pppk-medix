FROM rust:1-bookworm AS mate-builder

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    liblua5.1-0-dev \
    luarocks \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/mate
COPY mate/ ./

WORKDIR /tmp/mate/term
RUN cargo build --release

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    luarocks \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY medix-dev-1.rockspec ./
RUN luarocks make --only-deps medix-dev-1.rockspec

RUN mkdir -p /app/dist

COPY --from=mate-builder /tmp/mate/dist/out.lua /app/dist/out.lua
COPY --from=mate-builder /tmp/mate/term/target/release/libterm.so /usr/local/lib/lua/5.1/term.so
COPY src ./src

CMD ["lua5.1", "src/entrypoint.lua"]
