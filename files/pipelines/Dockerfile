# Building the webrtc library
# Author: Yousif Khalid
# Date: 2021-01-12


FROM ubuntu:18.04 as dev-base

# Installing prerequisites
RUN apt-get update && \
	apt install -y git wget build-essential software-properties-common

# Installing cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.15.2/cmake-3.15.2.tar.gz && \
	tar -zxvf cmake-3.15.2.tar.gz && \
	cd cmake-3.15.2 && \
	./bootstrap && \
	make && \
	make install

# Installing python
RUN add-apt-repository ppa:deadsnakes/ppa && \ 
	apt update

RUN apt install -y python3.8 && \
	apt install -y python-minimal
	
# Sanity check
RUN python --version
RUN python3 --version

# Installing depot_tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

ENV PATH="$PWD/depot_tools:$PATH"

# Sanity check
RUN cmake --version
RUN git --version

# Cloning the webrtc repo and building it
RUN git clone https://github.com/Yousif-CS/WebRTC-build.git

RUN mkdir WebRTC-build/files/build && \
	cd WebRTC-build/files/build && \
	cmake -DCMAKE_BUILD_TYPE=Debug .. && \
	make && \
	make install
