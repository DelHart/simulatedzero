#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use IO::Socket;
use Data::Dumper;

my $addr = '127.0.0.1';
my $port = 8000;
my $verbose = 0;
my $delay = 1;

my $total_tests = 0;

GetOptions (
    'verbose' => \$verbose,
    'addr=s' => \$addr,
    'delay=s' => \$delay,
    'port=s' => \$port
    );

while (1) {

    my $sock = IO::Socket::INET->new(
        PeerAddr => $addr,
        PeerPort => $port,
        Proto    => 'tcp'
    );

    my $num = int( rand() * 5 );
    print "getting $num fortunes\n" if ($verbose);

    print $sock "PASS:KNOCKKNOCK\n";
    print $sock "NUM:$num\n";

    #print $sock "ENCODE:H*:\n";
    print $sock "GET\n";

    my @response = ();
    @response = <$sock>;

    my $count = 0;

    for my $line (@response) {
        if ( $line =~ m/----------/ ) {
            $count++;
        }    # if
    }    # for

    $total_tests++;
    if ( $count == $num ) {
        print "$total_tests...ok\n";
    }
    else {
        print "$total_tests...not ok\n";
    }    # if

    my $wait = int( rand() * 10 ) + $delay;
    sleep $wait;
}
