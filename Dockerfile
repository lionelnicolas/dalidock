FROM ubuntu:noble-20251013 AS base

# environment variables
ENV \
	LC_ALL=C.UTF-8 \
	LANG=C.UTF-8 \
	LANGUAGE=C.UTF-8 \
	DEBIAN_FRONTEND=noninteractive

# install packages
RUN \
	echo "deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse"           >/etc/apt/sources.list && \
	echo "deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse" >>/etc/apt/sources.list && \
	echo "deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse"  >>/etc/apt/sources.list && \
	rm -vf /etc/apt/sources.list.d/ubuntu.sources && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		bind9-host \
		ca-certificates \
		dirmngr \
		dnsmasq \
		dnsutils \
		ed \
		gpg \
		gpg-agent \
		haproxy \
		inotify-tools \
		iproute2 \
		libvirt0 \
		net-tools \
		python3 \
		python3-docker \
		python3-libvirt \
		runit \
		wget \
		&& \
	apt-get clean && \
	rm -rf /var/lib/apt/lists && \
	rm -vf /etc/ssh/ssh_host_* && \
	rm -vf /etc/service

# install tini
RUN \
	TINI_VERSION=v0.19.0 && \
	http_proxy='' gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0527A9B7 && \
	wget -O/usr/bin/tini     "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini" && \
	wget -O/usr/bin/tini.asc "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc" && \
	gpg --verify /usr/bin/tini.asc && \
	rm -f /usr/bin/tini.asc && \
	chmod a+x /usr/bin/tini

# add scripts
ADD entrypoint dalidock haproxy-start /usr/sbin/

# add configuration scripts
ADD etc /etc/

# set entrypoint
ENTRYPOINT ["/usr/sbin/entrypoint"]
