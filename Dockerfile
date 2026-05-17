FROM qbittorrentofficial/qbittorrent-nox:5.1.4-1@sha256:41888f4e05646ace98aeaff01a7bbec714e2e6082ab273fd4af0d1210352ea2c

RUN apk update && apk upgrade

# Install ssmtp and mailx
RUN apk add ssmtp mailx

# Install clamav
RUN apk add --no-cache clamav clamav-daemon

RUN addgroup qbtUser clamav

# Copy the scan_file script
COPY files/scan_file /scan_file
RUN chmod +x /scan_file
