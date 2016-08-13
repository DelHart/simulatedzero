#!/usr/bin/env perl

use strict;
use warnings;
use feature "state";

use Getopt::Long;

use Data::Dumper;

my $children = {};
$SIG{INT} = sub {
    foreach my $c ( keys %$children ) {
        print "reaping $c\n";
        system "kill", '-9', $c;
    }
    exit();
};

# look in the directories, and find the client and servers and attempt to run them
# the script assumes that the same directory structure will be replicated everywhere

my $verbose       = 0;
my $start_servers = 0;
my $start_clients = 0;
my $delay         = 1;

GetOptions(
    'verbose'      => \$verbose,
    'delay=s' => \$delay,
    'startservers' => \$start_servers,
    'startclients' => \$start_clients
);

my $servers = {};
my $clients = {};

# get the list of subdirectories

chdir ("/root/traffic/");
opendir my $cwd, ".";
my @dirs = readdir($cwd);
closedir $cwd;

foreach my $dir (@dirs) {

    next unless ( length $dir > 2 );
    next unless ( -d $dir );

    opendir my $subdir, "$dir";
    my @files = readdir $subdir;

    foreach my $file (@files) {
        next unless ( -f "$dir/$file" );
        if ( $file =~ m/client/i ) {
            $clients->{$dir} = $file;
        }
        elsif ( $file =~ m/server/i ) {
            $servers->{$dir} = $file;
        }

    }

}

#print Dumper $clients;
#print Dumper $servers;

# now that we have the clients and servers
# start what we need to

if ( $start_servers == 1 ) {
    foreach my $sd ( sort keys %$servers ) {

        my @ports = get_ports($sd);

        foreach my $p (@ports) {

            print "starting $sd/$servers->{$sd} on port $p\n" if $verbose;
            my $pid = fork();
            if ( $pid == 0 ) {
                exec "$sd/$servers->{$sd}", "--port=$p";
            }
            else {
                $children->{$pid} =
                  { 'server' => "$sd/$servers->{$sd}", 'port' => $p };
            }

        }
    }

    print "servers running\n";
    print Dumper $children;
    print "press control-c to exit\n";

    while (1) {
        my $pid = wait();
        if ( $pid > -1 ) {
            print "child $pid gone\n";
            delete $children->{$pid};
        }
        sleep 1;
    }

}    # start servers end
elsif ( $start_clients == 1 ) {

    # open up the hosts file
    open my $HFILE, "hosts.txt";
    my @hosts = <$HFILE>;
    close $HFILE;

    # strip off the line feeds
    map { chomp $_; } @hosts;

    # now go through each client and start hosts to talk to each machine
    foreach my $cd ( sort keys %$clients ) {

        my @ports = get_ports($cd);

        foreach my $p (@ports) {

            foreach my $h (@hosts) {

                print "starting $cd/$clients->{$cd} on port $p\n" if $verbose;
                my $pid = fork();
                if ( $pid == 0 ) {
                    exec "$cd/$clients->{$cd}", "--port=$p", "--addr=$h --delay=$delay";
                }
                else {
                    $children->{$pid} = {
                        'server' => "$cd/$clients->{$cd}",
                        'port'   => $p,
                        'addr'   => $h
                    };
                }
            }    # hosts

        }
    }

    print "clients running\n";
    print Dumper $children;
    print "press control-c to exit\n";

    while (1) {
        my $pid = wait();
        if ( $pid > -1 ) {
            print "child $pid gone\n";
            delete $children->{$pid};
        }
        sleep 1;
    }

}
else {
    print "nothing to do\n";
}

sub get_ports {
    state $port = 3000;
    my $dir = shift;

    my @ports = ();

 # let's try to open a properties file to find out how many ports to run this on
    if ( -r "$dir/properties.txt" ) {
        open my $PFILE, "$dir/properties.txt";
        my $pline = <$PFILE>;
        chomp $pline;
        @ports = split ',', $pline;
        close $PFILE;
    }
    else {
        push @ports, $port;
        $port += 100;
    }

    return @ports;

}    # get_ports
