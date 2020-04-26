FROM docker:latest

WORKDIR /app

COPY LICENSE README.md ./

COPY entrypoint.sh timegroup.sh ./

COPY coq.json ./

ENTRYPOINT ["/app/entrypoint.sh"]
