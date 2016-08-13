#!/usr/bin/env perl

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;

use Getopt::Long;

my $conf_file = 'contest.xml';
my $verbose   = 0;
my $round     = 1;

GetOptions(
    'verbose'  => \$verbose,
    'config=s' => \$conf_file,
    'round=s'  => \$round,
);

# read in config

my $config = XMLin($conf_file) || die "could not open config file";

# print Dumper $config;

my @players = @{ $config->{'player'} };
my @assets  = @{ $config->{'assets'}->{'asset'} };

print Dumper \@players if $verbose;

# for each player, read their data, generate a file, copy it to the destination, then delete that file locally
# use sshfs to mount remote directories to send the data, assume that the ip address is the local name and remotely it is mounted on / and we are copying files to /tmp

foreach my $p (@players) {

    my $ip = $p->{'ip'};
    
    system '/bin/mkdir', $ip unless (-d $ip);
   # system '/usr/bin/sshfs', 'root@' . $ip . ':/', $ip . '/';


    die "could not access directory for $ip" unless (-d "$ip/tmp");

    my $pd = { 'exploits' => [] };
    my $knowns = $p->{'known'}->{'round'};
    foreach my $r (@$knowns) {
        next unless ( $r->{'num'} == $round );
	if (ref ($r->{'exploits'}) eq 'HASH') {
            my $e = {
                'type'          => $r->{'exploits'}->{'type'},
                'level'         => $r->{'exploits'}->{'level'},
                'flag'          => $r->{'exploits'}->{'flag'},
                'service_proto' => $r->{'exploits'}->{'service'}->{'proto'},
                'service_port'  => $r->{'exploits'}->{'service'}->{'port'},
            };

            push @{ $pd->{'exploits'} }, $e;
	}
	else {
	next unless (defined $r->{'exploits'});
        foreach my $k ( @{ $r->{'exploits'} } ) {
            my $e = {
                'type'          => $k->{'type'},
                'level'         => $k->{'level'},
                'flag'          => $k->{'flag'},
                'service_proto' => $k->{'service'}->{'proto'},
                'service_port'  => $k->{'service'}->{'port'},
            };
            push @{ $pd->{'exploits'} }, $e;
        }
	}
    }

    my $xml = XMLout($pd);

    open my $outfile, '>',
      "$ip/tmp/contest_info_round_$round.xml" || die "could not create info file for $ip";

    print $outfile $xml;

    close $outfile;

    # may need to use ssh to remotely execute this
    # create checksums to verify if the file was retrieved
    # now create the assets
    # only create the assets on the first round
    if ( $round == 1 ) {
        foreach my $a (@assets) {
            foreach my $i ( 1 .. $a->{'number'} ) {
                my $name = $a->{'level'} . "-" . $a->{'size'} . "-$i";
                my $size = $a->{'size'};
                system "dd if=/dev/urandom of=$ip/tmp/$name bs=1k count=$size";
            }
        }
    }

}
