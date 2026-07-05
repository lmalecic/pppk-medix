FROM rust:1-bookworm AS mate-builder

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    liblua5.1-0-dev \
    luarocks \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN git clone --depth=1 https://github.com/carabalonepaulo/mate.git

WORKDIR /tmp/mate/term
RUN cargo build --release

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    git \
    luarocks \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY medix.rockspec ./
RUN luarocks make --only-deps medix.rockspec

RUN mkdir -p /app/dist

COPY --from=mate-builder /tmp/mate/dist/out.lua /app/dist/out.lua
COPY --from=mate-builder /tmp/mate/term/target/release/libterm.so /usr/local/lib/lua/5.1/term.so
RUN sed -i "/local function exit_with_err/,/end/c\\local function exit_with_err(err)\\n  deinit_term()\\n  io.stderr:write(tostring(err) .. '\\\\n')\\n  io.stderr:write(debug.traceback() .. '\\\\n')\\n  os.exit(1)\\nend" /app/dist/out.lua
COPY src ./src

ENV LUA_INIT="term = require 'term'; dofile('/app/dist/out.lua')"

CMD ["lua5.1", "src/entrypoint.lua"]
