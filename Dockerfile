#syntax=docker/dockerfile:1.10-labs
ARG OS=debian
ARG VER=bookworm
FROM ${OS}:${VER} AS osbase

LABEL version="v1.0"

ARG TZ="UTC"
ARG LANG_WHICH=en
ARG LANG_WHERE=US
ARG ENCODING=UTF-8
ARG LANGUAGE=${LANG_WHICH}_${LANG_WHERE}.${ENCODING}
ARG CUGID=9002
ARG CUID=9001
ARG CUSER=cuser
ARG CUSHELL=/bin/bash
ARG CUHOME=/home/${CUSER}
ARG CUPASS=pass
ARG HOME=${CUHOME}
ARG SCREEN_WIDTH=1920
ARG SCREEN_HEIGHT=1080
ARG SCREEN_DEPTH=24 
ARG SCREEN=0
ARG GEOMETRY=${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH} 

USER root

SHELL ["/bin/bash", "-c"]

ENV HOME=${HOME} \
  SCREEN_WIDTH=${SCREEN_WIDTH} \
  SCREEN_HEIGHT=${SCREEN_HEIGHT}} \
  SCREEN_DEPTH=${SCREEN_DEPTH}} \
  GEOMETRY=${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH} \
  SCREEN_DPI=96 \
  NO_VNC_PORT=7900 \
  VNC_PORT=5900 \
  DISPLAY=:1 \
  SCREEN=${SCREEN}  \
  DISPLAY_NUM=99.0 \
  DBUS_SESSION_BUS_ADDRESS=/dev/null \
  CUGID=${CUGID} \
  CUID=${CUID} \ 
  CUSER=${CUSER} \
  CUGROUP=${CUSER} \ 
  CUSHELL=${CUSHELL} \
  CUHOME=${CUHOME} \
  DEBIAN_FRONTEND=noninteractive \
  DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get update -qqy && \
  apt-get upgrade -yq && \
  apt-get -qqy --no-install-recommends install \
  acl \
  bzip2 \
  python3-pip \
  python3-setuptools \
  ca-certificates \
  tzdata \
  sudo \
  unzip \
  wget \
  jq \
  curl \
  gnupg2 \
  libnss3-tools \
  chromium \
  curl \ 
  firefox-esr \
  git \
  xvfb \
  libxcb1 \
  xauth \
  pulseaudio \
  x11vnc \
  x11-utils \
  fluxbox \ 
  eterm \
  runit-run \
  socklog \
  ucspi-unix \
  hsetroot \
  feh \
  locales \
  locales-all \
  libfontconfig \
  libfreetype6 \
  xfonts-scalable \
  fonts-liberation \
  fonts-ipafont-gothic \
  fonts-wqy-zenhei \
  fonts-tlwg-loma-otf \
  fonts-noto-color-emoji \
  wget \
  zip && \
  locale-gen ${LANGUAGE}

ENV LANGUAGE=${LANGUAGE} \
  LANG=${LANGUAGE} \
  LC_ALL=${LANGUAGE} \
  TZ=${TZ} 

RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata && \
  cat /etc/timezone && \
  groupadd ${CUGROUP} \
  --gid ${CUGID} && \
  useradd ${CUSER} \
  --create-home \
  --gid ${CUGID} \
  --shell ${CUSHELL}  \
  --uid ${CUID} && \
  usermod -a -G sudo ${CUSER} && \ 
  echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers && \  
  echo "${CUSER}:${CUPASS}" | chpasswd && \
  apt-get -qyy autoremove && \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/* && \
  apt-get -qyy clean && \
  mkdir -p /opt/bin && \
  chmod +x /dev/shm && \
  mkdir -p /tmp/.X11-unix && \
  mkdir -p ${CUHOME}/.vnc && \
  x11vnc -storepasswd ${CUPASS} ${CUHOME}/.vnc/passwd && \
  chown -R "${CUID}:${CUGID}" ${CUHOME}/.vnc && \
  chmod -R 777 ${CUHOME} /tmp/.X11-unix && \
  chmod -R g=u ${CUHOME} /tmp/.X11-unix && \
  chown -R ${CUID}:${CUGID} ${CUHOME}

ADD --chown=${CUID}:${CUGID} --keep-git-dir=false https://github.com/novnc/noVNC.git#v1.5.0 /opt/bin/noVNC 

ADD --exclude=docker \
  --exclude=docs \
  --exclude=tests \
  --exclude=Windows \
  --chown=${CUID}:${CUGID} \
  --keep-git-dir=false \
  https://github.com/novnc/websockify.git#v0.12.0 /opt/bin/websockify 

RUN cp /opt/bin/noVNC/vnc.html /opt/bin/noVNC/index.html
WORKDIR /opt/bin/websockify
RUN python3 setup.py install 

WORKDIR ${CUHOME}
COPY --chown=${CUID}:${CUGID} xdg ${CUHOME}/.local

RUN openssl req -batch -newkey rsa:4096 -x509 -days 365 -nodes -out ${CUHOME}/.local/config/novpn/self.pem -keyout ${CUHOME}/.local/config/novpn/self.pem && \
  chmod -R +x ${CUHOME}/.local/bin && \
  echo "export PATH=${CUHOME}/.local/bin:$PATH" >> .bashrc && \
  source .bashrc

ADD --chown=${CUID}:${CUGID} https://get.sdkman.io sdkman.sh
RUN chmod +x sdkman.sh && \
  ./sdkman.sh && \
  source .bashrc && \
  source .sdkman/bin/sdkman-init.sh && \
  sdk install java 11.0.24-zulu && \
  sdk install gradle 6.8 && \
  sdk install maven && \
  sdk install groovy &&  \
  rm sdkman.sh

FROM osbase AS srcgen

ADD --chown=${CUID}:${CUGID} src src
ADD --chown=${CUID}:${CUGID} build.gradle build.gradle
RUN chown -R ${CUID}:${CUGID} ${CUHOME}
USER ${CUID}:${CUGID}

EXPOSE ${NO_VNC_PORT}:${NO_VNC_PORT}

CMD /bin/runsvdir -P $HOME/.local/sv
