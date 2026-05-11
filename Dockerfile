FROM nimlang/nim:1.6.10 AS build
WORKDIR /since
COPY since.nimble ./
RUN nimble refresh -y && nimble install -y --depsOnly
COPY . .
RUN nimble build -d:release -y

FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates libssl3 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /since/bin/since /usr/local/bin/since
ENV BIND_ADDR=0.0.0.0 \
    PORT=8000
EXPOSE 8000
CMD ["/usr/local/bin/since"]
