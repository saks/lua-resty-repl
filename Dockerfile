FROM saksmlz/openresty-docker:1.11.2.1-slim

RUN set -ex \
      && apt-get update \
      && apt-get install --yes perl \
      && apt-get install --yes build-essential git curl unzip libssl-dev \
      && luarocks install busted \
      && luarocks install luacheck \
      && echo "#!/usr/bin/env resty" > /usr/local/bin/resty-busted \
      && echo "require 'busted.runner'({ standalone = false })" >> /usr/local/bin/resty-busted \
      && chmod +x /usr/local/bin/resty-busted \
      && apt-get purge --yes --auto-remove build-essential git curl unzip libssl-dev \
      && rm -rf /var/lib/apt/lists/*
