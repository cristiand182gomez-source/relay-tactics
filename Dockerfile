FROM node:24.19.0-bookworm-slim AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends unzip ca-certificates && rm -rf /var/lib/apt/lists/*
RUN npm install --global pnpm@11.25.0
COPY relay-tactics-source.zip /tmp/source.zip
RUN printf '%s  /tmp/source.zip\n' '140c9540add399dc72f3b98a8b472bbfeb40ecd3b4bd2c0717017a00da0b87f8' | sha256sum -c - && unzip -q /tmp/source.zip -d /app && rm /tmp/source.zip
RUN pnpm install --frozen-lockfile && pnpm run build:standalone

FROM node:24.19.0-bookworm-slim
ENV NODE_ENV=production PORT=10000 SQLITE_PATH=/app/data/rooms.sqlite
WORKDIR /app
COPY --from=build /app/node-dist/client ./node-dist/client
COPY --from=build /app/server ./server
COPY --from=build /app/lib ./lib
COPY --from=build /app/drizzle/0000_equal_bishop.sql ./drizzle/0000_equal_bishop.sql
RUN mkdir -p /app/data && chown -R node:node /app/data
USER node
EXPOSE 10000
CMD ["node", "server/main.mjs"]
