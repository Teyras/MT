FROM fedora:27

RUN echo "deltarpm=0" >> /etc/dnf/dnf.conf \
	&& dnf -y install --refresh dnf-plugins-core \
	&& dnf -y copr enable semai/ReCodEx \
	&& dnf -y install isolate \
	&& dnf -y install stress-ng \
	&& dnf -y install python36 \
	&& dnf -y install jre \
	&& dnf -y install sudo perf

ADD . /recodex

WORKDIR /recodex

CMD /bin/bash
