FROM ubuntu:18.04
MAINTAINER Patrick Brosi brosi@cs.uni-freiburg.de
ENV LANG C.UTF-8
RUN apt-get -y -q update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends apt-utils
RUN apt-get -y -q update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
    git \
	g++ \
	gcc \
	make \
	texlive-xetex \
	curl \
	libz-dev \
	python3 \
	python3-pip \
	python3-setuptools \
	python3-dev
ENV HOME /root
ENV PATH="${PATH}:/usr/local/bin:$HOME/.local/bin"
COPY Makefile $HOME
WORKDIR $HOME
RUN make install
ENTRYPOINT ["make"]
CMD ["help"]

# docker build -t statsimi-eval .
# docker run -v <folder>:/root/data statsimi-eval <CMD>
