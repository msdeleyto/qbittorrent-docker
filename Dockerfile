FROM qbittorrentofficial/qbittorrent-nox:5.2.0-1

RUN apk update && apk upgrade

# Install ssmtp and mailx
RUN apk add ssmtp mailx

# Install clamav
RUN apk add --no-cache clamav clamav-daemon

RUN addgroup qbtUser clamav

# Copy the scan_file script
COPY files/scan_file /scan_file
RUN chmod +x /scan_file
