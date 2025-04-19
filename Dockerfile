FROM debian:bookworm-slim

RUN set -ex \
    # Official Mopidy install for Debian/Ubuntu along with some extensions
    # (see https://docs.mopidy.com/en/latest/installation/debian/ )
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        wget \
        dumb-init \
        gnupg \
        gstreamer1.0-alsa \
        gstreamer1.0-plugins-bad \
        #python3-crypto \
        python3-distutils \
        python3-venv \
        python3-pip \
        pipx \
        gir1.2-gst-plugins-base-1.0 \
        gir1.2-gstreamer-1.0 \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-tools \
        libcairo2-dev \
        libgirepository1.0-dev \
        python3-gst-1.0 \

 #&& curl -L https://bootstrap.pypa.io/pip/3.7/get-pip.py | python3 - \
 #&& pip install pipenv --break-system-packages \
 && pipx install pipenv \
 && pipx ensurepath \
    # Clean-up
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

RUN set -ex \
 && mkdir -p /etc/apt/keyrings \
 && wget -q -O /etc/apt/keyrings/mopidy-archive-keyring.gpg \
       https://apt.mopidy.com/mopidy.gpg \
 && wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/bullseye.list \
 && curl -L https://apt.mopidy.com/mopidy.gpg | apt-key add - \
 && curl -L https://apt.mopidy.com/mopidy.list -o /etc/apt/sources.list.d/mopidy.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
 #       python3-pykka \
        mopidy \
        #mopidy-soundcloud \
        #mopidy-spotify \
    # Clean-up
 && apt-get purge --auto-remove -y \
        gcc \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

#COPY Pipfile Pipfile.lock /

#RUN set -ex \
# #&& pipx install --include-deps mopidy \
# && pipx install --include-deps youtube-dl \
# && pipx install --include-deps mopidy-iris \
# && pipx install --include-deps mopidy-moped \
# && pipx install --include-deps mopidy-gmusic \
# && pipx install --include-deps mopidy-pandora \
# && pipx install --include-deps Mopidy-Jellyfin \
# && pipx install --include-deps mopidy-soundcloud \
# && pipx install --include-deps mopidy-youtube \
# && pipx install --include-deps mopidy-local \
# && pipx install --include-deps mopidy-mpd \
# #&& pipx install Mopidy-Pandora \
# && pipx install --include-deps Mopidy-YTMusic \
# #&& pipx install --include-deps mopidy-spotify \
# && pipx ensurepath 

RUN set -ex \
 && pip install --break-system-packages youtube-dl \
 && pip install --break-system-packages mopidy-iris \
 && pip install --break-system-packages mopidy-moped \
 && pip install --break-system-packages mopidy-gmusic \
 && pip install --break-system-packages mopidy-pandora \
 && pip install --break-system-packages Mopidy-Jellyfin \
 && pip install --break-system-packages mopidy-youtube \
 && pip install --break-system-packages mopidy-local \
 && pip install --break-system-packages mopidy-mpd \
 && pip install --break-system-packages Mopidy-YTMusic \
 && pip install --break-system-packages mopidy-tunein 


RUN set -ex \
 && mkdir -p /var/lib/mopidy/.config \
 && ln -s /config /var/lib/mopidy/.config/mopidy

# Start helper script.
COPY entrypoint.sh /entrypoint.sh

# Default configuration.
COPY mopidy.conf /config/mopidy.conf

# Copy the pulse-client configuratrion.
COPY pulse-client.conf /etc/pulse/client.conf

# Allows any user to run mopidy, but runs by default as a randomly generated UID/GID.
ENV HOME=/var/lib/mopidy  
RUN set -ex \
 #&& useradd mopidy \
 && usermod -G audio,sudo mopidy \
 && chown mopidy:audio -R $HOME /entrypoint.sh \
 && chmod go+rwx -R $HOME /entrypoint.sh

# Runs as mopidy user by default.
USER mopidy

# Basic check,
#RUN /usr/bin/dumb-init "/entrypoint.sh"
RUN mopidy --version
#RUN pipx run mopidy --version

VOLUME ["/var/lib/mopidy/local", "/var/lib/mopidy/media"]

EXPOSE 6600 6680 5555/udp

#ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["/usr/bin/mopidy"]
#CMD ["pipx", "run",  "mopidy"]

HEALTHCHECK --interval=5s --timeout=2s --retries=20 \
    CMD curl --connect-timeout 5 --silent --show-error --fail http://localhost:6680/ || exit 1