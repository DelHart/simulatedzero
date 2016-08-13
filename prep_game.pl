#!/usr/bin/env perl

# this script takes a contest configuration and instantiates the specific exploits and distribution
# it writes out a contest.xml file that is used by other scripts to send the exploits and release the info

use strict;
use warnings;

use XML::Simple;
use Data::Dumper;

use Getopt::Long;

my $conf_file = 'simzero.xml';
my $output_file = 'contest.xml';
my $verbose = 0;

GetOptions (
    'verbose' => \$verbose,
    'config=s' => \$conf_file,
    'contest=s' => \$output_file,
    );


# read in config

my $config = XMLin ($conf_file) || die "could not open config file";

# print Dumper $config;

my @players = @{$config->{'players'}->{'player'}};
my @decoys = @{$config->{'decoys'}->{'decoy'}};
my @services = @{$config->{'services'}->{'service'}};
my @exploits = @{$config->{'exploits'}->{'exploit'}};

# generate all of the exploits
foreach my $ex (@exploits) {
    my $flag_len = 15;
    $ex->{'list'} = [];
    foreach my $exploit_num (1 .. $ex->{'num'}) {
	my $flag = '';
	foreach my $i (1 .. $flag_len) {
	    my $n = int (rand() * 256);
	    $flag .= sprintf ("%02x", $n); 
	}

	my $sn = int (rand() * ($#services + 1));
	my $service = $services[$sn];
	push @{$ex->{'list'}}, {'flag' => $flag, 'service' => $service, 'type' => $ex->{'type'}, 'level' => $ex->{'level'},};
    }
}

print Dumper @exploits if $verbose;

# install exploits on hosts
foreach my $player (@players) {

    $player->{'installed'} = [];
    $player->{'not_installed'} = [];
    $player->{'known'} = {};
    foreach my $ex (@exploits) {

	# copy the list of exploits, then split it into
	# ones installed and not installed
	push @{$player->{'not_installed'}}, @{$ex->{'list'}};

	foreach my $i (1 .. $ex->{'install'}) {
	    # choose a random one
	    my $index = int (rand () * ($#{$player->{'not_installed'}} + 1));
	    push @{$player->{'installed'}}, splice @{$player->{'not_installed'}}, $index, 1;
	}

        # reveal some exploits to each team
	reveal_exploits ($player, $ex);
	
    }

}

print Dumper \@players if $verbose;

my $xml = XMLout ({ 'player' => \@players, 'assets' => $config->{'assets'}});

open my $file, '>', $output_file || die "could not open contest file";

print $file $xml;
close $file;



sub reveal_exploits {

    my $player = shift;
    my $exploit = shift;

    # exploit reveals will be based on rounds

    # first do the overlap exploits, then non_overlap
    my $copies = {};
    $copies->{'overlap_reveal'} = [];
    push @{$copies->{'overlap_reveal'}}, @{$player->{'installed'}};
    $copies->{'nonoverlap_reveal'} = [];
    push @{$copies->{'nonoverlap_reveal'}}, @{$player->{'not_installed'}};

    # foreach round
    foreach my $r (1 .. $exploit->{'rounds'}) {
	foreach my $type (qw (overlap_reveal nonoverlap_reveal)) {
	    foreach my $ri (@{$exploit->{'round'}}) {
		# skip the rounds unless this is the correct one, not very efficient, but probably ok
		next unless ($ri->{'num'} == $r);
		my $rknown = {'num' => $r, 'exploits' => []};
		$player->{'known'}->{$r} = [] unless defined ($player->{'known'}->{$r});
		foreach my $i (1 .. $ri->{$type}) {
		    my $index = int (rand () * ($#{$copies->{$type}} + 1));
		    push @{$rknown->{'exploits'}}, splice @{$copies->{$type}}, $index, 1;
		}
		push @{$player->{'known'}->{'round'}}, $rknown;
	    } # iterate through round info
	}
    } # rounds

} # reveal_exploits

