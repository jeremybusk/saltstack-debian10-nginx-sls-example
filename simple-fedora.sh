#!/bin/bash
# Simple example of using salt commands to install, enable and deploy changes to pkgs.
set -ex

########################################################################
# Using some functions to do some simple grouping of commands.

pkg_install_enable() {
    hostname=$1
    pkg_name=$2
    salt ${hostname} pkg.install ${pkg_name}
    salt ${hostname} cmd.run "systemctl enable ${pkg_name}"
}


pkg_install_enable fedora29 nginx
pkg_install_enable fedora29 firewalld

firewalld_push_new_cfg() {
    hostname=$1

    salt 'fedora29' grains.item os
    mkdir -p /srv/files/firewalld

    sudo cat <<'EOF' > /srv/files/firewalld/public.xml
<?xml version="1.0" encoding="utf-8"?>
<zone target="DROP">
  <short>Public</short>
  <description>For use in public areas. You do not trust the other computers on networks to not harm your computer. Only selected incoming connections are accepted.</description>
  <service name="ssh"/>
  <service name="mdns"/>
  <service name="dhcpv6-client"/>
  <port port="3200" protocol="tcp"/>
  <port port="3400" protocol="tcp"/>
</zone>
EOF

    salt-cp ${hostname} /srv/files/firewalld/public.xml /etc/firewalld/zones/
    salt ${hostname} cmd.run 'systemctl restart firewalld'
}

firewalld_push_new_cfg fedora29

echo "COMPLETED"
