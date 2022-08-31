FROM rust:slim-bullseye
ARG DATABASE_URL
ENV DATABASE_URL DATABASE_URL
WORKDIR /usr/src/migration
RUN cargo install sqlx-cli --no-default-features --features native-tls,postgres
COPY migration/ .
ENTRYPOINT ["sqlx migrate run"]