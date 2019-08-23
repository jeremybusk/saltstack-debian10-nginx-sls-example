#!/bin/bash
set -e
## Prep salt master for nginx minion template
# This assumes you have two hosts test-minion & test-master.
# The host test-minion key has been accepted/added to salt master keystore.


## Create salt nginx minion init.sls
sudo mkdir -p /srv/salt/nginx
sudo cat <<'EOF' > /srv/salt/nginx/init.sls
nftables:
  pkg:
    - installed
  service.running:
    - enable: True
    - watch:
      - pkg: nftables
      - file: /etc/nftables.conf

/etc/nftables.conf:
  file.managed:
    - source: salt://nginx/files/etc/nftables.conf
    - user: root
    - group: root
    - mode: 640

nginx:
  pkg:
    - installed
  service.running:
    - enable: True
    - watch:
      - pkg: nginx
      - file: /etc/nginx/conf.d/www.example.com.conf
      - file: /etc/nginx/nginx.conf
      - file: /etc/nginx/sites-available/default
      - file: /var/www/html/error.html

/etc/nginx/conf.d/www.example.com.conf:
  file.managed:
    - source: salt://nginx/files/etc/nginx/conf.d/www.example.com.conf
    - user: root
    - group: root
    - mode: 640

/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://nginx/files/etc/nginx/nginx.conf
    - user: root
    - group: root
    - mode: 640

/etc/nginx/sites-available/default:
  file.managed:
    - source: salt://nginx/files/etc/nginx/sites-available/default
    - user: root
    - group: root
    - mode: 640

/etc/nginx/sites-enabled/default:
  file.symlink:
    - target: /etc/nginx/sites-available/default
    - require:
      - file: /etc/nginx/sites-available/default

/var/www/html/error.html:
  file.managed:
    - source: salt://nginx/files/var/www/html/error.html
    - user: www-data
    - group: www-data
    - mode: 440
EOF


## Create salt nginx minion init.sls
sudo mkdir -p /srv/salt/nginx/files/var/www/html
sudo cat <<'EOF' > /srv/salt/nginx/files/var/www/html/error.html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Acme Company</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!--# if expr="$status = 502" -->
      <meta http-equiv="refresh" content="2">
    <!--# endif -->
  </head>
<body>
  <!--# if expr="$status = 502" -->
    <h1>Site is down for maintenance!</h1>
    <p>This is usually brief and application conectivity should be restored shortly.</p>
  <!--# else -->
    <h1><!--# echo var="status" default="" --> <!--# echo var="status_text" default="Issue with connection. Please call ..." --></h1>
  <!--# endif -->
</body>
</html>
EOF


## Create nginx.conf with default template
sudo mkdir -p /srv/salt/nginx/files/etc/nginx
sudo cat <<'EOF' > /srv/salt/nginx/files/etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
        # multi_accept on;
}

http {

        ##
        # Basic Settings
        ##

        log_format   main '$remote_addr - $remote_user [$time_local]  $status '
            '"$request" $body_bytes_sent "$http_referer" '
            '"$http_user_agent" "$http_x_forwarded_for"';

        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;
        # server_tokens off;

        # server_names_hash_bucket_size 64;
        # server_name_in_redirect off;

        include /etc/nginx/mime.types;
        default_type application/octet-stream;

        ##
        # SSL Settings
        ##

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
        ssl_prefer_server_ciphers on;

        ##
        # Logging Settings
        ##

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        ##
        # Gzip Settings
        ##

        gzip on;

        # gzip_vary on;
        # gzip_proxied any;
        # gzip_comp_level 6;
        # gzip_buffers 16 8k;
        # gzip_http_version 1.1;
        # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

        ##
        # Virtual Host Configs
        ##

        include /etc/nginx/conf.d/*.conf;
        include /etc/nginx/sites-enabled/*;
}


#mail {
#       # See sample authentication script at:
#       # http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
#
#       # auth_http localhost/auth.php;
#       # pop3_capabilities "TOP" "USER";
#       # imap_capabilities "IMAP4rev1" "UIDPLUS";
#
#       server {
#               listen     localhost:110;
#               protocol   pop3;
#               proxy      on;
#       }
#
#       server {
#               listen     localhost:143;
#               protocol   imap;
#               proxy      on;
#       }
#}
EOF


## Create nginx default site config
sudo mkdir -p /srv/salt/nginx/files/etc/nginx/sites-available
sudo cat <<'EOF' > /srv/salt/nginx/files/etc/nginx/sites-available/default
# Default server configuration
#
server {
        listen 3200 default_server;
        listen [::]:3200 default_server;
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
        # index index.html index.htm index.nginx-debian.html;
        server_name _;

        error_page 400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 421 422 423 424 426 428 429 431 451 500 501 502 503 504 505 506 507 508 510 511 /error.html;

        location = / {
            return 404;
            ssi on;
            internal;
        }
        location = /error.html {
            ssi on;
            internal;
        }
}
EOF


## Add sites to conf.d instead of sites-available/ for ease of deploy.

### Create nginx www.example.com site config
sudo mkdir -p /srv/salt/nginx/files/etc/nginx/conf.d
sudo cat <<'EOF' > /srv/salt/nginx/files/etc/nginx/conf.d/www.example.com.conf
server {
    listen 3200;
    listen [::]:3200;

    server_name www.example.com;
    access_log /var/log/nginx/www.example.com.access.log  main;

    location / {
        proxy_pass http://localhost:3400;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF


## Firewall
sudo mkdir -p /srv/salt/nginx/files/etc
sudo cat <<'EOF' > /srv/salt/nginx/files/etc/nftables.conf
#!/usr/sbin/nft -f
# A simple firewall

flush ruleset

table inet filter {
        chain input {
                type filter hook input priority 0; policy drop;

                # established/related connections
                ct state established,related accept

                # invalid connections
                ct state invalid drop

                # loopback interface
                iif lo accept

                # ICMP & IGMP
                ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, mld-listener-query, mld-listener-report, mld-listener-reduction, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, ind-neighbor-solicit, ind-neighbor-advert, mld2-listener-report } accept
                ip protocol icmp icmp type { destination-unreachable, router-solicitation, router-advertisement, time-exceeded, parameter-problem } accept
                ip protocol igmp accept

                # SSH (port 22)
                tcp dport ssh accept

                # HTTP Service Ports
                tcp dport { http, https, 3200, 3400 } accept
        }

        chain forward {
                type filter hook forward priority 0; policy drop;
        }

        chain output {
                type filter hook output priority 0; policy accept;
        }

}
EOF


# Apply nginx sls state
salt 'test-minion' state.apply nginx


# Simple Test setup
tcp_port=3400
proxy_tcp_port=3200

echo "Kill python http.server process and restart"
salt '*' cmd.run "ps -eaf | grep '[^]]http.server 3400' | awk '{print \$2}'"
salt '*' cmd.run 'cd /srv/www; python3 -u -m http.server 3400 >>http.log 2>&1 &'

curl -s http://test-minion:${tcp_port} \
    | grep hello \
    || { echo "E: Incorrect output on python server http tcp/${tcp_port}." ; exit 1; }

curl -s http://www.example.com:${proxy_tcp_port} \
    | grep hello \
    || { echo "E: Incorrect output on http proxy tcp port tcp/${proxy_tcp_port}." ; exit 1; }

curl -s http://test-minion:${proxy_tcp_port} \
    | grep "404 Issue" \
    || { echo "E: Incorrect output for 404 custom return of http proxy on tcp/${proxy_tcp_port}." ; exit 1; }
