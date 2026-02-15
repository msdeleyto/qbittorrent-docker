#!/bin/sh

downloadsPath="/downloads/complete"
incompleteDownloadsPath="/downloads/incomplete"
profilePath="/config"
qbtConfigFile="$profilePath/qBittorrent/config/qBittorrent.conf"
cerberus_logs_dir="/var/log/cerberus"

isRoot="0"
if [ "$(id -u)" = "0" ]; then
    isRoot="1"
fi

if [ "$isRoot" = "1" ]; then
    if [ -n "$PUID" ] && [ "$PUID" != "$(id -u qbtUser)" ]; then
        sed -i "s|^qbtUser:x:[0-9]*:|qbtUser:x:$PUID:|g" /etc/passwd
    fi

    if [ -n "$PGID" ] && [ "$PGID" != "$(id -g qbtUser)" ]; then
        sed -i "s|^\(qbtUser:x:[0-9]*\):[0-9]*:|\1:$PGID:|g" /etc/passwd
        sed -i "s|^qbtUser:x:[0-9]*:|qbtUser:x:$PGID:|g" /etc/group
    fi

    if [ -n "$PAGID" ]; then
        _origIFS="$IFS"
        IFS=','
        for AGID in $PAGID; do
            AGID=$(echo "$AGID" | tr -d '[:space:]"')
            addgroup -g "$AGID" "qbtGroup-$AGID"
            addgroup qbtUser "qbtGroup-$AGID"
        done
        IFS="$_origIFS"
    fi
fi

if [ ! -f "$qbtConfigFile" ]; then
    mkdir -p "$(dirname $qbtConfigFile)"
    cat << EOF > "$qbtConfigFile"
[BitTorrent]
Session\DefaultSavePath=$downloadsPath
Session\Port=6881
Session\TempPath=$incompleteDownloadsPath/temp
Session\TempPathEnabled=true

[AutoRun]
enabled=true
program=/scan_file %F

[Preferences]
WebUI\Password_PBKDF2="@ByteArray(${WEB_UI_PASSWORD})"
EOF
fi

confirmLegalNotice=""
_legalNotice=$(echo "$QBT_LEGAL_NOTICE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
if [ "$_legalNotice" = "confirm" ]; then
    confirmLegalNotice="--confirm-legal-notice"
else
    # for backward compatibility
    # TODO: remove in next major version release
    _eula=$(echo "$QBT_EULA" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    if [ "$_eula" = "accept" ]; then
        echo "QBT_EULA=accept is deprecated and will be removed soon. The replacement is QBT_LEGAL_NOTICE=confirm"
        confirmLegalNotice="--confirm-legal-notice"
    fi
fi

if [ -z "$QBT_WEBUI_PORT" ]; then
    QBT_WEBUI_PORT=8080
fi

mkdir -p "${downloadsPath}"
mkdir -p "${incompleteDownloadsPath}"
mkdir -p "${QUARANTINE_DIR}"
mkdir -p "${cerberus_logs_dir}"

if [ "$isRoot" = "1" ]; then
    # those are owned by root by default
    # don't change existing files owner in `$downloadsPath`
    if [ -d "$downloadsPath" ]; then
        chown qbtUser:qbtUser "$downloadsPath"
    fi
    if [ -d "$incompleteDownloadsPath" ]; then
        chown qbtUser:qbtUser "$incompleteDownloadsPath"
    fi
    if [ -d "$profilePath" ]; then
        chown qbtUser:qbtUser -R "$profilePath"
    fi
    if [ -d "$QUARANTINE_DIR" ]; then
        chown qbtUser:qbtUser -R "$QUARANTINE_DIR"
    fi
    if [ -d "$cerberus_logs_dir" ]; then
        chown qbtUser:qbtUser -R "$cerberus_logs_dir"
    fi
fi

echo "${DEST_EMAIL_ADDRESS}" > "/dest_email_address"
echo "${QUARANTINE_DIR}" > "/quarantine_dir"

chown qbtUser:qbtUser "/dest_email_address"
chown qbtUser:qbtUser "/quarantine_dir"

chown qbtUser:qbtUser "/scan_file"

# set umask just before starting qbt
if [ -n "$UMASK" ]; then
    umask "$UMASK"
fi

# Configure mailutils
cat > /etc/ssmtp/ssmtp.conf << EOF
root=postmaster
SERVER=${ORIGIN_EMAIL_AUTHUSER}

mailhub=smtp.gmail.com:587
AuthUser=${ORIGIN_EMAIL_AUTHUSER}
Authpass=${ORIGIN_EMAIL_AUTHPASS}
UseTLS=YES
UseSTARTTLS=YES

FromLineOverride=YES
EOF

# Refresh virus definitions
freshclam

if [ "$isRoot" = "1" ]; then
    exec \
        doas -u qbtUser \
            qbittorrent-nox \
                "$confirmLegalNotice" \
                --profile="$profilePath" \
                --webui-port="$QBT_WEBUI_PORT" \
                "$@"
else
    exec \
        qbittorrent-nox \
            "$confirmLegalNotice" \
            --profile="$profilePath" \
            --webui-port="$QBT_WEBUI_PORT" \
            "$@"
fi
