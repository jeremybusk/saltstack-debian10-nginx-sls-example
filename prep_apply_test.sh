#!/bin/bash
# Prep host for salt master/minion & apply minion nginx state.
# This uses limited complexity for demonstration purposes.
set -e

master_hostname=salt
minion_hostname=${HOSTNAME}
test_fqdn=www.example.com
tcp_port=3400
proxy_tcp_port=3200

echo "Modify /etc/hosts for resolution."
if grep -q ${test_fqdn} /etc/hosts; then
    echo "The test_fqdn ${test_fqdn} already exists in /etc/hosts."
else
    echo "Updating /etc/hosts with ${test_fqdn}"
    sudo sed  -i "/^127.0.0.1/s/$/\t${test_fqdn}/" /etc/hosts
fi

if grep -q ${master_hostname} /etc/hosts; then
    echo "The hostname ${master_hostname} already exists in /etc/hosts"
else
    echo "Updating /etc/hosts with ${master_hostname}"
    sudo sed  -i "/^127.0.0.1/s/$/\t${master_hostname}/" /etc/hosts
fi

echo "Install salt master/minion."
sudo apt-get update
sudo apt-get install -y salt-master salt-minion

sleep 10
echo "Accept salt key(s)."
salt-key -A -y

sleep 10
echo "Apply nginx sls state as matched in top.sls."
salt '*' state.apply

echo "Run simple tests."
salt '*' ps.pkill "python3 -u -m http.server 3400" full=true signal=9 || true

sudo mkdir -p /srv/www
salt '*' cmd.run 'echo "hello" > /srv/www/index.html'
salt '*' cmd.run 'cd /srv/www; python3 -u -m http.server 3400 >>http.log 2>&1 &'

ping -c 4 www.example.com

curl -s "http://${minion_hostname}:${tcp_port}" \
    | grep hello \
    || { echo "E: Incorrect output on python server http tcp/${tcp_port}." ; exit 1; }

curl -s "http://www.example.com:${proxy_tcp_port}" \
    | grep hello \
    || { echo "E: Incorrect output on http proxy tcp port tcp/${proxy_tcp_port}." ; exit 1; }

curl -s "http://${minion_hostname}:${proxy_tcp_port}" \
    | grep "404 Issue" \
    || { echo "E: Incorrect output for 404 custom return of http proxy on tcp/${proxy_tcp_port}." ; exit 1; }

echo "TESTS: PASS"
echo "COMPLETED SUCCESSFULLY!"
