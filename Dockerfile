# GO Builder
###############
FROM golang:alpine AS goBuilder

RUN apk update && apk add --no-cache git make ca-certificates
WORKDIR /go/src/github.com/MontFerret/worker
COPY . .

RUN CGO_ENABLED=0 GOOS=linux make compile

# MITM Builder
###############
FROM pierrebrisorgueil/mitm:latest AS mitmBuilder

# Runner
###############
FROM montferret/chromium:99.0.4844.0 as runner
RUN apt-get update && apt-get install -y dumb-init

# mitm
RUN apt-get update && apt-get install --no-install-recommends -y python3.8 python3-pip python3.8-dev
RUN pip install mitmproxy bs4 pyyaml lxml ua-parser user-agents fake-useragent
RUN pip install pyyaml==5.4.1
COPY --from=mitmBuilder bundle.js /
COPY --from=mitmBuilder inject.py /
COPY --from=mitmBuilder addons/useragent-param.py addons/useragent-param.py

# worker
COPY --from=goBuilder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.c
COPY --from=goBuilder /go/src/github.com/MontFerret/worker/bin/worker .

# launch mitm & chrome & worker
EXPOSE 8080
ENTRYPOINT ["dumb-init", "--"]
#CMD ["/bin/sh", "-c", "mitmdump -p 8081 -s inject.py & CHROME_OPTS='--proxy-server=127.0.0.1:8081' ./entrypoint.sh & ./worker"]
#Uncomment the next line and comment the last if you want a randomuseragent for each requests
#CMD ["/bin/sh", "-c", "mitmdump -p 8081 -s inject.py -s addons/useragent-param.py --set randomuseragent true & CHROME_OPTS='--proxy-server=127.0.0.1:8081' ./entrypoint.sh & ./worker"]
CMD ["/bin/sh", "-c", "mitmdump -p 8081 -s inject.py -s addons/useragent-param.py & CHROME_OPTS='--lang=fr-FR --proxy-server=127.0.0.1:8081' ./entrypoint.sh & ./worker"]
