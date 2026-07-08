FROM qbittorrentofficial/qbittorrent-nox:5.2.3-1@sha256:9ebb534fe30bab98622cb84a8c3acecfd88319b2d540f52ecdec7b9f866374d7

RUN apk update && apk upgrade

# Install ssmtp and mailx
RUN apk add ssmtp mailx

# Install clamav
RUN apk add --no-cache clamav clamav-daemon

RUN addgroup qbtUser clamav

# Copy the scan_file script
COPY files/scan_file /scan_file
RUN chmod +x /scan_file
