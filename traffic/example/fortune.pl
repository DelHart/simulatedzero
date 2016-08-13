#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use IO::Socket;
use Data::Dumper;

my $addr = '127.0.0.1';
my $port = 8000;
my $verbose = 0;

GetOptions (
    'verbose' => \$verbose,
    'addr=s' => \$addr,
    'port=s' => \$port
    );

my $sock = IO::Socket::INET->new(
    PeerAddr => $addr,
    PeerPort => $port,
    Proto    => 'tcp'
) or die "socket: $!";

print Dumper $sock if $verbose;

my $num = int( rand() * 5 );
print "getting $num fortunes\n" if ($verbose);

print $sock "PASS:KNOCKKNOCK\n";
print $sock "NUM:$num\n";

#print $sock "ENCODE:H*:\n";
print $sock "GET\n";

while (<$sock>) {
    print $_;
}
