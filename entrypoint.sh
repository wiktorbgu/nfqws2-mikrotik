#!/bin/sh
set -e

# set default config
if [ ! -f /opt/zapret2/config ]; then
    cp /opt/zapret2/config.default /opt/zapret2/config
    sed -i 's/^NFQWS2_ENABLE=.*/NFQWS2_ENABLE=1/' /opt/zapret2/config
    sed -i 's/^[#]*FWTYPE=.*/FWTYPE=nftables/' /opt/zapret2/config
fi

nft add table ip nat
nft add chain ip nat postrouting { type nat hook postrouting priority 100 \; }
nft add rule ip nat postrouting masquerade

if [ $# -gt 0 ]; then
  exec "$@"
else
  /opt/zapret2/init.d/sysv/zapret2 start
  exec sleep infinity
fi
