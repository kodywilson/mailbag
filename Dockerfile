FROM odo-docker-signed-local.artifactory.oci.oraclecorp.com/oci-oel7x-base:1.0.251
LABEL maintainer="Kody Wilson <kodywilson@gmail.com"

ENV BUILD_PACKAGES autoconf automake bash bzip2 cronie gcc gcc-c++ gzip libcurl-devel lsof make openssl-devel patch tar wget zlib-devel

# Update and install all of the required packages.
RUN yum update -y && \
    yum install -y $BUILD_PACKAGES && \
    wget -O ruby-install-0.7.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.7.1.tar.gz && \
    tar -xzvf ruby-install-0.7.1.tar.gz && \
    cd ruby-install-0.7.1/ && \
    make install && \
    ruby-install --system ruby 2.7.1 && \
    cd .. && \
    yum clean all

# Set timezone
RUN rm -rf /etc/localtime
RUN ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

RUN mkdir /usr/app 
WORKDIR /usr/app

COPY Gemfile /usr/app/ 
COPY Gemfile.lock /usr/app/ 
RUN bundle install

COPY mailbag.rb /usr/app/
RUN  mkdir /usr/local/lib/mailbag && \
     chmod 0744 /usr/app/mailbag.rb

# Set up cron job
COPY detached-cron /etc/cron.d/detached-cron
RUN chmod 0644 /etc/cron.d/detached-cron && \
    chown root:root /etc/cron.d/detached-cron && \
    sed -i -e 's~^\(session.*pam_loginuid.so\)$~#\1~' /etc/pam.d/crond && \
    crontab /etc/cron.d/detached-cron

COPY        entrypoint.sh /
RUN         chmod +x /entrypoint.sh
ENTRYPOINT  ["/entrypoint.sh"]
