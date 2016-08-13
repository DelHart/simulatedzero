#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use IO::Socket;
use Data::Dumper;
use Sys::Hostname;

my $addr    = inet_ntoa((gethostbyname(hostname))[4]);
my $port    = 8000;
my $verbose = 0;

GetOptions(
    'verbose' => \$verbose,
    'addr=s'  => \$addr,
    'port=s'  => \$port
);

my $sock = IO::Socket::INET->new(
    Listen    => 5,
    LocalAddr => $addr,
    LocalPort => $port,
    Reuse     => 1,
    Proto     => 'tcp'
);
print Dumper $sock if ($verbose);

while (1) {
    my $client = $sock->accept();
    my $pid    = 0; #fork();
    if ( $pid == 0 ) {
        print "got connection\n" if ($verbose);
        my $auth    = 0;
        my $num     = 1;
        my $notdone = 1;
        my $code    = '';

        while ($notdone) {
            my $req = <$client>;
	    next unless defined $req;
            if ( $req =~ m/NUM:(\d+)/ ) {
                $num = $1;
            }
            elsif ( $req =~ m/PASS:KNOCKKNOCK/ ) {
                $auth = 1;
            }
            elsif ( $req =~ m/ENCODE:(.*?):/ ) {
                $code = $1;
            }
            elsif ( $req =~ m/GET/ ) {
                if ($auth) {
                    for my $i ( 1 .. $num ) {
                        open my $fortune, "/usr/games/fortune|";
                        my @fortune_data = <$fortune>;
                        push @fortune_data, "-------------------\n";
                        close $fortune;
                        my $data = join( "\n", @fortune_data );
                        print $data if ($verbose);
                        if ( $code ne '' ) {
                            my $tmp = unpack( $code, $data );
                            $data = $tmp;
                        }
                        print $client $data;
                    }    # for
                }    #if
                $notdone = 0;
            }
        }
        shutdown( $client, 1 );
    }
}
