FROM ubuntu:16.04

ADD build-image /tmp/builder/
RUN /tmp/builder/build-image

ADD entrypoint /usr/sbin/

ENTRYPOINT ["/usr/sbin/entrypoint"]
