#!/bin/bash

# general information about nfqueue
### https://home.regit.org/netfilter-en/using-nfqueue-and-libnetfilter_queue/

# link to the perl bindings
# https://packages.debian.org/squeeze/nfqueue-bindings-perl

# overview of using it with perl
# https://blog.localh0rst.de/linux/perl-nfqueue-tcp-packet-manipulation/

#iptables -A INPUT -p tcp -m tcp --sport 1337 -d 10.10.10.2 -j NFQUEUE
#iptables -A INPUT -p tcp -m tcp --dport 1337 -d 10.10.10.2 -j NFQUEUE
iptables -A INPUT -p udp -m udp --dport 2000:2100 -j NFQUEUE
iptables -A INPUT -p tcp -m tcp --dport 2000:2100 -j NFQUEUE
