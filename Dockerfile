FROM debian:buster

ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901 \
    VNC_COL_DEPTH=32 \
    VNC_RESOLUTION=1920x1080

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    xvfb xauth dbus-x11 xfce4 xfce4-terminal \
    wget sudo curl gpg git bzip2 vim procps python x11-xserver-utils \
    libnss3 libnspr4 libasound2 libgbm1 ca-certificates fonts-liberation xdg-utils \
    tigervnc-standalone-server tigervnc-common firefox-esr; \
    curl http://ftp.us.debian.org/debian/pool/main/liba/libappindicator/libappindicator3-1_0.4.92-7_amd64.deb --output /opt/libappindicator3-1_0.4.92-7_amd64.deb && \
    curl http://ftp.us.debian.org/debian/pool/main/libi/libindicator/libindicator3-7_0.5.0-4_amd64.deb --output /opt/libindicator3-7_0.5.0-4_amd64.deb && \
    apt-get install -y /opt/libappindicator3-1_0.4.92-7_amd64.deb /opt/libindicator3-7_0.5.0-4_amd64.deb; \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg \
	hicolor-icon-theme \
	libcanberra-gtk* \
	libgl1-mesa-dri \
	libgl1-mesa-glx \
	libpangox-1.0-0 \
	libpulse0 \
	libv4l-0 \
	fonts-symbola \
	--no-install-recommends \
	&& curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
	&& echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
	&& apt-get update && apt-get install -y \
	google-chrome-stable \
	--no-install-recommends \
	&& apt-get purge --auto-remove -y curl \
	&& rm -rf /var/lib/apt/lists/* \
    rm -vf /opt/lib*.deb; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



ENV TERM xterm
# Install NOVNC.
RUN     git clone --branch v1.2.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC; \
        git clone --branch v0.9.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify; \
        ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# disable shared memory X11 affecting Chromium
ENV QT_X11_NO_MITSHM=1 \
    _X11_NO_MITSHM=1 \
    _MITSHM=0


# give every user read write access to the "/root" folder where the binary is cached
RUN ls -la /root
RUN chmod 777 /root && mkdir /src

RUN groupadd -g 61000 dockeruser; \
    useradd -g 61000 -l -m -s /bin/bash -u 61000 dockeruser

# chrome groupadd
RUN groupadd -r chrome && useradd -r -g chrome -G audio,video chrome \
    && mkdir -p /home/chrome/Downloads && chown -R chrome:chrome /home/chrome

COPY assets/config/ /home/dockeruser/.config

RUN chown -R dockeruser:dockeruser /home/dockeruser;\
    chmod -R 777 /home/dockeruser ;\
    adduser dockeruser sudo;\
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER dockeruser
# versions of local tools
RUN echo  "debian version:  $(cat /etc/debian_version) \n" \
          "user:            $(whoami) \n"

# Install Chrome
# original
# RUN apt-get update && apt-get install -y \
# RUN apt-get install -y \
# 	apt-transport-https \
# 	ca-certificates \
# 	curl \
# 	gnupg \
# 	hicolor-icon-theme \
# 	libcanberra-gtk* \
# 	libgl1-mesa-dri \
# 	libgl1-mesa-glx \
# 	libpangox-1.0-0 \
# 	libpulse0 \
# 	libv4l-0 \
# 	fonts-symbola \
# 	--no-install-recommends \
# 	&& curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
# 	&& echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
# 	&& apt-get update && apt-get install -y \
# 	google-chrome-stable \
# 	--no-install-recommends \
# 	&& apt-get purge --auto-remove -y curl \
# 	&& rm -rf /var/lib/apt/lists/*

# Add chrome user

COPY local.conf /etc/fonts/local.conf

# Run Chrome as non privileged user
# USER chrome

COPY scripts/entrypoint.sh /src
RUN sudo apt-get update \
    && sudo apt-get install libu2f-udev -y

RUN sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
RUN sudo apt install ./google-chrome-stable_current_amd64.deb -y

#Expose port 5901 to view display using VNC Viewer
EXPOSE 5901 6901
ENTRYPOINT ["/src/entrypoint.sh"]


