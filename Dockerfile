FROM alpine:3.2
MAINTAINER Ross Fairbanks "ross@force12.io"

ENV FLEET_VERSION 0.11.5

ENV BUILD_PACKAGES bash curl-dev ruby-dev build-base wget
ENV RUBY_PACKAGES ruby

# Install Ruby
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add $RUBY_PACKAGES  && \
    rm -rf /var/cache/apk/*

# Install fleetctl static binary
RUN \
  wget -P /tmp https://github.com/coreos/fleet/releases/download/v${FLEET_VERSION}/fleet-v${FLEET_VERSION}-linux-amd64.tar.gz && \
  gunzip /tmp/fleet-v${FLEET_VERSION}-linux-amd64.tar.gz && \
  tar -xf /tmp/fleet-v${FLEET_VERSION}-linux-amd64.tar -C /tmp && \
  mv /tmp/fleet-v${FLEET_VERSION}-linux-amd64/fleetctl /bin/ && \
  rm -rf /tmp/fleet-v${FLEET_VERSION}-linux-amd64*

COPY units/* /opt/

ENTRYPOINT /opt/start_units.rb
