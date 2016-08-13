#!/usr/bin/perl

use strict;
use warnings;

use IO::File;
use IO::Socket::UNIX;
use IO::Socket::INET;

our $SOCK_PATH = '/tmp/simzero.sock';
unlink $SOCK_PATH;

    # Server:
    my $server = IO::Socket::UNIX->new(
        Type => SOCK_STREAM(),
        Local => $SOCK_PATH,
        Listen => 1,
    );

    my $count = 1;
    while (my $conn = $server->accept()) {
#        $conn->print("Hello " . ($count++) . "\n");
	print "got connection\n";
	while (!$conn->eof ()) {
	    my $data;
	    $data = $conn->getline ();
	    chomp $data;
	    print " received  --- $data --- \n";;

	    
	    # parse the data out and then act on it
	    my ($type, $ip, $port, $str, $file) = split (':', $data, 5);
	    my $proto = 'tcp';

	    if ($type eq '0') {
		$proto = 'udp';
	    }

	    my $fh = new IO::File $file, "r";
	    if ( defined $fh) {

		my $sock = IO::Socket::INET->new (PeerAddr => $ip,
						  PeerPort => $port,
						  Proto => $proto);
		
		while (<$fh>) {
		    if (!defined $sock) {
			print "socket undefined\n";
			last;
		    }
		    else {
			$sock->print ($_);
		    }
		}

		undef $fh;
		
	    }
	    else {
		print "could not open $file\n";
	    }
	    

	}
    }
