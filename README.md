# Install and test basic saltstack nginx state for Debian based.

From repo base directory on Ubuntu/Debian system run.

```
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
