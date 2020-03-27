#!/bin/sh

for v in 'VPN_USER' 'VPN_PASS' 'VPN_DOMAIN' 'VPN_SERVER' 'VPN_RDPIP'; do
    if test -z $(eval "echo \$$v"); then
        echo "Missing env variable $v" >&2
        exit 1
    fi
done

iptables -F
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination  ${VPN_RDPIP}:22
iptables -t nat -A POSTROUTING -j MASQUERADE

# Setup masquerade, to allow using the container as a gateway
for iface in $(ip a | grep eth | grep inet | awk '{print $2}'); do
  iptables -t nat -A POSTROUTING -s "$iface" -j MASQUERADE
done

# Run the following script that will detect unwanted default routing
# on the VPN device. In case there will be any the script deletes it.
/gateway-fix.sh &

# Start VPN (in a loop).
while [ true ]; do
  echo "------------ VPN Starts ------------"
  /usr/bin/netextender
  echo "------------ VPN exited ------------"
  sleep 10
done

