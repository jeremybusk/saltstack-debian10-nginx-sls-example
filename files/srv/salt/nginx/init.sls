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
