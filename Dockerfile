ARG JAVA_VERSION=21
FROM eclipse-temurin:$JAVA_VERSION-jdk-alpine AS photon-builder

WORKDIR /photon
COPY . .

# trigger a gradle download
RUN apk --no-cache add git
RUN ./gradlew --version
RUN ./gradlew build --info

RUN ls -sahlS target/photon-*.jar

FROM eclipse-temurin:$JAVA_VERSION-jre-alpine AS photon

RUN apk add pixz --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/ && \
    apk --no-cache add sudo bash pv coreutils outils-md5 && \
    rm -rf /var/cache/apk/*

RUN	adduser -D -s /bin/bash -h /photon photon && \
	echo 'photon ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

USER photon:photon
WORKDIR /photon

COPY --from=photon-builder /photon/target/photon-*.jar /photon/photon.jar
RUN sudo chown -R "$USER":root /photon

# Inspired by https://github.com/thomasnordquist/photon-docker
COPY --chown=photon:photon entrypoint.sh /photon/entrypoint.sh

RUN chmod +x /photon/entrypoint.sh

ENTRYPOINT ["/photon/entrypoint.sh"]
