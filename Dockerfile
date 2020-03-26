FROM alpine:3.11.3
MAINTAINER Kody Wilson <kodywilson@gmail.com>

ENV BUILD_PACKAGES bash curl-dev ruby-dev build-base lsof
ENV RUBY_PACKAGES ruby ruby-io-console ruby-bundler

# Update and install all of the required packages.
# At the end, remove the apk cache
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add $RUBY_PACKAGES && \
    rm -rf /var/cache/apk/*

RUN mkdir /usr/app 
WORKDIR /usr/app

COPY Gemfile /usr/app/ 
COPY Gemfile.lock /usr/app/ 
RUN bundle install

COPY mailbag.rb /usr/app/
RUN  mkdir /usr/local/lib/mailbag

COPY        entrypoint.sh /
RUN         chmod +x /entrypoint.sh
ENTRYPOINT  ["/entrypoint.sh"]
