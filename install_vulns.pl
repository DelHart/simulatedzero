#!/usr/bin/env perl

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;

use NetPacket::IP qw(IP_PROTO_UDP);
use NetPacket::UDP;
use Socket qw(AF_INET AF_INET6);
use IO::Socket::INET;

use Getopt::Long;

$| = 1;

my $conf_file = 'contest.xml';
my $target;
my $verbose = 0;

GetOptions (
    'verbose' => \$verbose,
    'target=s'  => \$target,
    'config=s' => \$conf_file,
    );


# read in config

my $config = XMLin ($conf_file) || die "could not open config file";

# print Dumper $config;

my @players = @{$config->{'player'}};

#print Dumper \@players if $verbose;

foreach my $p (@players) {

    my $ip = $p->{'ip'};
    next if (defined $target && $target ne $ip);
    
    print "contacting $ip\n" if $verbose;
    my $c = 0;
    foreach my $i (@{$p->{'installed'}}) {

	my $sock = IO::Socket::INET->new (PeerAddr => $ip,
					  PeerPort => 2050,
					  Proto => IP_PROTO_UDP);
	
	my $str = 'SIMZERO:ADD:';
	$str .= $i->{'flag'} . ':send:1:' . "\n\n";
	$sock->print($str);
	
	$sock->close();
	$c++;
    }
    print "sent $c\n" if $verbose;
    


}
