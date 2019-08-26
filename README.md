
# Saltstack Example 

Install and test basic saltstack nginx state for Debian based.

# Usage 

On Ubuntu 18.04/Debian 10 base system install run.

```
git clone git@github.com:jeremybusk/saltstack-nginx-sls-example.git
cd saltstack-nginx-sls-example
cp -r files/* /
./prep_apply_test.sh
```

# Using Python

You can always use python client if needed.

https://docs.saltstack.com/en/latest/ref/clients/

```
import salt.client

local = salt.client.LocalClient()
local.cmd('my-host', 'grains.items')['my-host']['os']
local.cmd('*', 'cmd.run', ['hostname'])
```

# Question

This is example in response required items below:

- Use Salt to install NGINX on a Debian based Linux distribution such as Ubuntu.
- Script should configure the host to allow traffic to NGINX.
- Config should persist on host restart.
- Write an NGINX configuration for the new virtual host described in step 1.
- Should listen to port 3200.
- Should proxy traffic from www.example.com and deliver it to a backend host named localhost on port 3400.
- Send all non www.example.com traffic to a custom 404 page.
- NGINX should start if the host is restarted.
- You must use git for source control and push your code to github.com. Please send me the link to your repository at least 1 day before the on-site interview.
