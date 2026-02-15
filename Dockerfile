FROM qbittorrentofficial/qbittorrent-nox:5.1.4-1

ENV XDG_CONFIG_HOME="/config"

RUN apk update && apk upgrade

# Install ssmtp and mailx
RUN apk add ssmtp mailx

# Install clamav
RUN apk add --no-cache clamav clamav-daemon

RUN addgroup qbtUser clamav

# Copy the scan_file script
COPY files/scan_file /scan_file
RUN chmod +x /scan_file

# Copy the entrypoint script
COPY files/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
