FROM fedora:28

RUN echo "deltarpm=0" >> /etc/dnf/dnf.conf \
	&& dnf -y install --refresh dnf-plugins-core \
	&& dnf -y copr enable semai/ReCodEx \
	&& dnf -y install --refresh isolate stress-ng

ADD . /recodex

WORKDIR /recodex

CMD /bin/bash
