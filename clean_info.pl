#!/usr/bin/env perl

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;

use Getopt::Long;

my $conf_file = 'contest.xml';
my $verbose = 0;

GetOptions (
    'verbose' => \$verbose,
    'config=s' => \$conf_file,
    );


# read in config

my $config = XMLin ($conf_file) || die "could not open config file";

# print Dumper $config;

my @players = @{$config->{'player'}};
my @assets = @{$config->{'assets'}->{'asset'}};

print Dumper \@players if $verbose;

# for each player, read their data, generate a file, copy it to the destination, then delete that file locally
# use sshfs to mount remote directories to send the data, assume that the ip address is the local name and remotely it is mounted on / and we are copying files to /tmp

foreach my $p (@players) {

    my $ip = $p->{'ip'};
    die "could not access directory for $ip" unless (-d "$ip/tmp");

    unlink "$ip/tmp/contest_info.xml";

    foreach my $a (@assets) {
	foreach my $i (1 .. $a->{'number'}) {
	    my $name = $a->{'level'} . "-" . $a->{'size'} . "-$i";
	    my $size = $a->{'size'};
	    unlink "$ip/tmp/$name";
	}
    }

    system '/bin/fusermount', '-u', $ip;

}
