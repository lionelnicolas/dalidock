FROM ubuntu:16.04

ADD build-image /tmp/builder/
RUN /tmp/builder/build-image

ADD entrypoint dalidock /usr/sbin/
ADD etc /etc/

ENTRYPOINT ["/usr/sbin/entrypoint"]
