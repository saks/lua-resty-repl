FROM alpine:3.4

RUN set -ex \
      && sed -i -e 's/v3\.4/edge/g' /etc/apk/repositories \
      && apk update \
      && apk add lua5.1 luarocks \
      && apk add build-base lua5.1-dev \
      && luarocks-5.1 install busted \
      && apk del build-base lua5.1-dev
