#!/bin/sh

# to be executed on laptop
# router is expected to have already the firmware flashed
# and ssh setup

# copy files
scp -r -o UserKnownHostsFile=/dev/null packages/*.ipk root@192.168.1.1:/root/
scp -r -o UserKnownHostsFile=/dev/null www/* root@192.168.1.1:/www/
scp -r -o UserKnownHostsFile=/dev/null setup_remote.sh root@192.168.1.1:/root/

# execute setup_remote.sh on router
ssh -o UserKnownHostsFile=/dev/null root@192.168.1.1 'chmod +x /root/setup_remote.sh; /root/setup_remote.sh'


