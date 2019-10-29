FROM ubuntu:bionic-20191010 as python-build

# environment variables
ENV \
	LC_ALL=C.UTF-8 \
	LANG=C.UTF-8 \
	LANGUAGE=C.UTF-8 \
	DEBIAN_FRONTEND=noninteractive

# install packages
RUN \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse"           >/etc/apt/sources.list && \
	echo "deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" >>/etc/apt/sources.list && \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse"  >>/etc/apt/sources.list && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		build-essential \
		python3 \
		python3-dev \
		python3-venv \
		python3-wheel \
		twine \
		virtualenv \
		wget \
		&& \
	apt-get clean && \
	rm -rf /var/lib/apt/lists

# install pip
RUN \
	cd /tmp && \
	wget http://bootstrap.pypa.io/get-pip.py && \
	python3 ./get-pip.py && \
	rm -rfv *

# install dependencies
COPY requirements.txt /tmp/requirements.txt
RUN \
	pip3 install \
		--requirement /tmp/requirements.txt \
		--ignore-installed \
		--target /tmp/packages

FROM ubuntu:bionic-20191010 as base

# environment variables
ENV \
	LC_ALL=C.UTF-8 \
	LANG=C.UTF-8 \
	LANGUAGE=C.UTF-8 \
	DEBIAN_FRONTEND=noninteractive

# install packages
RUN \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse"           >/etc/apt/sources.list && \
	echo "deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" >>/etc/apt/sources.list && \
	echo "deb http://archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse"  >>/etc/apt/sources.list && \
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
		inotify-tools \
		iproute2 \
		net-tools \
		python3 \
		python3-distutils \
		runit \
		wget \
		&& \
	echo "deb http://ppa.launchpad.net/vbernat/haproxy-1.9/ubuntu bionic main"  >>/etc/apt/sources.list.d/haproxy.list && \
	http_proxy='' apt-key adv --keyserver ipv4.pool.sks-keyservers.net --recv-keys CFFB779AADC995E4F350A060505D97A41C61B9CD && \
	apt-get update && \
	apt-get install -y --no-install-recommends haproxy && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists && \
	rm -vf /etc/ssh/ssh_host_*

# install tini
RUN \
	TINI_VERSION=v0.18.0 && \
	http_proxy='' gpg --keyserver ipv4.pool.sks-keyservers.net --recv-keys 0527A9B7 && \
	wget -O/usr/bin/tini     "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini" && \
	wget -O/usr/bin/tini.asc "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc" && \
	gpg --verify /usr/bin/tini.asc && \
	rm -f /usr/bin/tini.asc && \
	chmod a+x /usr/bin/tini

# add python packages
COPY --from=python-build /tmp/packages /usr/lib/python3/dist-packages

# add scripts
ADD entrypoint dalidock haproxy-start /usr/sbin/

# add configuration scripts
ADD etc /etc/

# set entrypoint
ENTRYPOINT ["/usr/sbin/entrypoint"]
