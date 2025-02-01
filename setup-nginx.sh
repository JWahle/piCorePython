#!/bin/sh -e

# Maybe steal from here: http://tinycorelinux.net/5.x/armv6/tcz/src/nginx/nginx.build

# Would be nice for this: https://github.com/mdsimon2/RPi-CamillaDSP#motu-ultralite-mk5

NGINX_VERSION=1.2.6

pcp-load -wil -t /tmp compiletc
pcp-load -wil -t /tmp pcre
wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
wget https://raw.githubusercontent.com/sihorton/tinycore-nginx/54467dc415ed76b68d1e741c7474b27eee9fb251/nginx.build64
chmod u+x nginx.build64
./nginx.build64