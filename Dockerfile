FROM docker:latest

WORKDIR /app

COPY LICENSE README.md ./

COPY entrypoint.sh timegroup.sh ./

ENTRYPOINT ["/app/entrypoint.sh"]
