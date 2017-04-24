#!/bin/bash

for ip in 10.151.151.{0..20}
do
    ping -c 1 -W 1 "$ip" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "$ip" >>host_list
    fi
done
