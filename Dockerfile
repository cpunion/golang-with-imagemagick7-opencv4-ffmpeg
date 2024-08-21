FROM golang:1.22 as base

# Ignore APT warnings about not having a TTY
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
    && apt-get install -y \
        unzip curl \
        wget build-essential \
        pkg-config \
        --no-install-recommends \
    && apt-get -q -y install \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libgif-dev \
        libx11-dev \
        fontconfig fontconfig-config libfontconfig1-dev \
        ghostscript gsfonts gsfonts-x11 \
        libfreetype6-dev \
        --no-install-recommends
RUN apt-get install -y cmake

ARG IMAGEMAGICK_PROJECT=ImageMagick
ARG IMAGEMAGICK_VERSION=7.0.8-41
ENV IMAGEMAGICK_VERSION=$IMAGEMAGICK_VERSION

RUN cd && \
	wget https://github.com/ImageMagick/${IMAGEMAGICK_PROJECT}/archive/${IMAGEMAGICK_VERSION}.tar.gz && \
	tar xvzf ${IMAGEMAGICK_VERSION}.tar.gz && \
	cd ImageMagick* && \
	./configure \
	    --without-magick-plus-plus \
	    --without-perl \
	    --disable-openmp \
	    --with-gvc=no \
	    --with-fontconfig=yes \
	    --with-freetype=yes \
	    --with-gslib \
	    --disable-docs && \
	make -j$(nproc) && make install && \
	ldconfig /usr/local/lib

ARG OPENCV_VERSION="4.10.0"
ENV OPENCV_VERSION $OPENCV_VERSION

ARG OPENCV_FILE="https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip"
ENV OPENCV_FILE $OPENCV_FILE

ARG OPENCV_CONTRIB_FILE="https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip"
ENV OPENCV_CONTRIB_FILE $OPENCV_CONTRIB_FILE

RUN curl -Lo opencv.zip ${OPENCV_FILE} && \
      unzip -q opencv.zip && \
      curl -Lo opencv_contrib.zip ${OPENCV_CONTRIB_FILE} && \
      unzip -q opencv_contrib.zip && \
      rm opencv.zip opencv_contrib.zip && \
      cd opencv-${OPENCV_VERSION} && \
      mkdir build && cd build && \
      cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D WITH_IPP=OFF \
      -D WITH_OPENGL=OFF \
      -D WITH_QT=OFF \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${OPENCV_VERSION}/modules \
      -D OPENCV_ENABLE_NONFREE=ON \
      -D WITH_JASPER=OFF \
      -D WITH_TBB=ON \
      -D BUILD_JPEG=ON \
      -D WITH_SIMD=ON \
      -D ENABLE_LIBJPEG_TURBO_SIMD=ON \
      -D BUILD_DOCS=OFF \
      -D BUILD_EXAMPLES=OFF \
      -D BUILD_TESTS=OFF \
      -D BUILD_PERF_TESTS=ON \
      -D BUILD_opencv_java=NO \
      -D BUILD_opencv_python=NO \
      -D BUILD_opencv_python2=NO \
      -D BUILD_opencv_python3=NO \
      -D OPENCV_GENERATE_PKGCONFIG=ON .. && \
      make -j $(nproc --all) && \
      make preinstall && make install && ldconfig && \
      cd / && rm -rf opencv*
