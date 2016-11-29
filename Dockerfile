FROM debian:jessie
MAINTAINER philipp.holler93@googlemail.com

RUN wget 'http://downloads.rclone.org/rclone-current-linux-amd64.zip' \
 && unzip rclone-current-linux-amd64.zip \
 && cp /rclone-*-linux-amd64/rclone /usr/sbin/ \
 && rm -r rclone* \
 && chmod 755 /usr/sbin/rclone

ADD /volumebackup-rclone_entrypoint.sh /
RUN chmod +x /volumebackup-rclone_entrypoint.sh
ENTRYPOINT ["/volumebackup-rclone_entrypoint.sh"]
