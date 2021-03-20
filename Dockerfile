FROM odo-docker-signed-local.artifactory.oci.oraclecorp.com/oci-oel7x-base:1.0.272
ARG BUILD_DATE
ARG VCS_REF
LABEL   maintainer="Kody Wilson <kody.wilson@oracle.com>"
LABEL   org.label-schema.build-date=$BUILD_DATE \
        org.label-schema.vcs-ref=$VCS_REF \
        org.label-schema.vendor="Oracle" \
        org.label-schema.url="https://oracle.com" \
        org.label-schema.name="DetachedETL"

# Install required yum packages
RUN mkdir -p /usr/app /usr/share/info/dir && \
    yum install -y gcc automake zlib-devel openssl-devel bison gdbm-devel libffi-devel \
    libyaml-devel ncurses-devel readline-devel xz libyaml gzip tar vim wget && \
    yum clean all

# Grab Ruby from Artifactory
RUN wget -O ruby272-03-19-2021-17.tar.gz https://artifactory.oci.oraclecorp.com:443/dcs_microservices-dev-generic-local/ruby/ruby272-03-19-2021-17.tar.gz && \
    tar -xzf ruby272-03-19-2021-17.tar.gz && \
    rm ruby272-03-19-2021-17.tar.gz

# Set timezone
RUN rm -rf /etc/localtime && \
    ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

COPY mailbag.rb /usr/app/
RUN  mkdir /usr/local/lib/mailbag && \
     chmod 0744 /usr/app/mailbag.rb && \
     chown -R odosvc:odosvc /usr/app /usr/local

# Use supercronic for cron
COPY detached-cron /etc/crontab
RUN setup-supercronic /etc/crontab

# Set up validate.sh script
COPY        validate.sh /
RUN         chmod +x /validate.sh && \
            chown odosvc:odosvc /validate.sh

USER odosvc
WORKDIR /usr/app

ENTRYPOINT [ "supercronic" ]
CMD [ "/etc/crontab" ]
