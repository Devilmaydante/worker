# Étape 1 : Construire le binaire Go
FROM golang:1.19 AS goBuilder

RUN apt-get update && apt-get install -y --no-install-recommends git make ca-certificates
WORKDIR /go/src/github.com/MontFerret/worker
COPY . .

RUN CGO_ENABLED=0 GOOS=linux make compile



# Étape 2 : Import a headful chromium image
FROM devilmaydante/chromium:latest

ENV DEBIAN_FRONTEND=noninteractive
# Installez les dépendances nécessaires pour le rendu graphique avec Chrome headful
RUN apt-get update && apt-get install -y xvfb dumb-init \
    xserver-xorg \
    x11-xserver-utils \
    xinit \
    x11-utils \
    dbus-x11 \
    pulseaudio \
    fonts-noto-color-emoji \
    libxtst6 \
    libnss3 \
    libasound2 \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxi6 \
    libxtst6 \
    libxrandr2 \
    libxss1 \
    libxtst6 \
    libgbm-dev \
    libpangocairo-1.0-0


# Définir les variables d'environnement pour le rendu X11
ENV DISPLAY=:99

# Copiez le binaire Go depuis l'étape précédente
COPY --from=goBuilder /go/src/github.com/MontFerret/worker/bin/worker .

# worker
COPY --from=goBuilder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.c
COPY --from=goBuilder /go/src/github.com/MontFerret/worker/bin/worker .

# launch mitm & chrome & worker
EXPOSE 8080
ENTRYPOINT ["dumb-init", "--"]
# CMD ["/bin/sh", "-c", "xvfb-run --server-args='-screen 0 1024x768x24' mitmdump -p 8081 -s inject.py & CHROME_OPTS='--proxy-server=127.0.0.1:8081' ./entrypoint.sh & ./worker"]
# CMD ["/bin/sh", "-c", "mitmdump -p 8081 -s inject.py -s addons/useragent-param.py & CHROME_OPTS='--proxy-server=127.0.0.1:8081' ./entrypoint.sh & ./worker"]
CMD ["/bin/sh", "-c", "xvfb-run --server-args='-screen 0 1024x768x24' ./entrypoint.sh & ./worker"]
# CMD ["xvfb-run", "--server-args='-screen 0 1024x768x24'", "./worker"]

