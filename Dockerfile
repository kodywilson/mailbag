FROM oci-dco-release-docker-local.artifactory.oci.oraclecorp.com/oci-dco/detached:1.2020.11.18
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vendor="Oracle" \
    org.label-schema.url="https://oracle.com" \
    org.label-schema.name="DetachedETL"

WORKDIR /usr/app

COPY        validate.sh /
RUN         chmod +x /validate.sh && \
            chown odosvc:odosvc /validate.sh

ENTRYPOINT [ "supercronic" ]
CMD [ "/etc/crontab" ]
