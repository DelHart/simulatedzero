#!/usr/bin/perl

use warnings;
use strict;
use nfqueue;

#use regex 'debug';
sub VERBOSE { return 0; }

use NetPacket::IP qw(IP_PROTO_TCP IP_PROTO_UDP);
use NetPacket::TCP;
use NetPacket::UDP;
use Socket qw(AF_INET AF_INET6);
use IO::Socket::UNIX;
use Data::Dumper;

our $SOCK_PATH = '/tmp/simzero.sock';

our $QUEUE;
our @TCP_ACTIONS = ();
our @UDP_ACTIONS = ();
our $SEND_CONN;

# action
#    pattern
#    verdict
#    action

push @UDP_ACTIONS, { 'unpacked' => unpack ('H*', 'SIMZERO:PRINT:'),
		     'pattern'  => 'SIMZERO:PRINT',
		     'verdict' => $nfqueue::NF_DROP,
		     'action'  => 'print',
};

push @UDP_ACTIONS, { 'unpacked' => unpack ('H*', 'SIMZERO:ADD:'),
		     'pattern'  => 'SIMZERO:ADD',
		     'verdict' => $nfqueue::NF_DROP,
		     'action'  => 'add',
};

push @UDP_ACTIONS, { 'unpacked' => unpack ('H*', 'SIMZERO:SEND:'),
		     'pattern'  => 'SIMZERO:SEND',
		     'verdict' => $nfqueue::NF_DROP,
		     'action'  => 'send',
		     'options' => { 'safety' => 1 },
};

our $ACTIONS = { 'print' => \&print_listener_status, 
		 'add'   => \&add_handler,
		 'send'   => \&send_handler };

sub cleanup()
{
	VERBOSE () && print "unbind\n";
	$QUEUE->unbind(AF_INET);
	VERBOSE () && print "close\n";
	$QUEUE->close();
}

# look for commands to the simulatedzero system here
sub cb()
{
	my ($dummy,$payload) = @_;

	if ($payload) {

		my $ip_obj = NetPacket::IP->decode($payload->get_data());

		my $verdict = $nfqueue::NF_ACCEPT;
		if($ip_obj->{proto} == IP_PROTO_TCP) {
		    $verdict = process_tcp ($ip_obj);
		}
		elsif($ip_obj->{proto} == IP_PROTO_UDP) {
		    $verdict = process_udp ($ip_obj);
		}
		

		$payload->set_verdict($verdict);
		return;
	} else {
	    # not sure why there would be a packet without an ip payload
	    print "accepting empty packet\n";
	    $payload->set_verdict($nfqueue::NF_ACCEPT);
	}
}

# set up connection to sender.pl


$SEND_CONN = IO::Socket::UNIX->new(
    Type => SOCK_STREAM(),
    Peer => $SOCK_PATH,
    );
$SEND_CONN->autoflush(1);


$QUEUE = new nfqueue::queue();

VERBOSE () && print "open\n";
$QUEUE->open();
VERBOSE () && print "bind\n";
$QUEUE->bind(AF_INET);

$SIG{INT} = "cleanup";

VERBOSE () && print "setting callback\n";
$QUEUE->set_callback(\&cb);

VERBOSE () && print "creating queue\n";
$QUEUE->create_queue(0);

VERBOSE () && print "trying to run\n";
$QUEUE->try_run();


sub process_tcp {

    my $ip_obj = shift;
    # decode the TCP header
    my $tcp_obj = NetPacket::TCP->decode($ip_obj->{data});
    
    if ($tcp_obj->{flags} & NetPacket::TCP::PSH &&
	length($tcp_obj->{data})) {
	my $data = $tcp_obj->{'data'};
	#print $tcp_obj->{data};
	foreach my $ua (@TCP_ACTIONS) {
	    my $pattern = $ua->{'pattern'};
	    print "-----$pattern--- \n";
	    if ($data =~ m/\Q$pattern/) {
		
		&{$ACTIONS->{$ua->{'action'}}} ($tcp_obj, $data, $ua);
		
		return $ua->{'verdict'};
	    }
	}
    }
    
    return $nfqueue::NF_ACCEPT;
    
}

sub process_udp {
    my $ip_obj = shift;

    my $udp_obj = NetPacket::UDP->decode ($ip_obj->{data});
    my $data = $udp_obj->{data};
    my $hex = $data; # unpack ("H*", $data);

    print "hex: $hex\n";

    foreach my $ua (@UDP_ACTIONS) {
	my $pattern = $ua->{'pattern'};
	print "-----$pattern--- \n";
	if ($hex =~ m/$pattern/) {
	    
	    &{$ACTIONS->{$ua->{'action'}}} ($udp_obj, $hex, $ua);
	    
	    return $ua->{'verdict'};
	}
    }

    return $nfqueue::NF_ACCEPT;


} # process_udp

sub print_listener_status {

    print "$#TCP_ACTIONS TCP Actions\n";
    foreach my $t (@TCP_ACTIONS) {
	print Dumper $t;
    }

    print "$#UDP_ACTIONS UDP Actions\n";
    foreach my $u (@UDP_ACTIONS) {
	print Dumper $u;
    }

} # print_listener_status

sub add_handler {
    my $udp = shift;
    my $hex = shift;

    my @args = split (':', $hex);

    # the packing is because the flag is specified using ascii
    my $action = { 'unpacked' => $args[2],
		   'pattern' => pack ('H*', $args[2]),
		   'verdict' => $args[4], #pack ('H*', $args[4]),
		   'action'  => $args[3], #pack ('H*', $args[3]),
    };

    if ($args[5] eq '0') {
	push @UDP_ACTIONS, $action;
    }
    else {
	push @TCP_ACTIONS, $action;
    }



} # add_handler

sub send_handler {
    my $udp = shift;
    my $arg = shift;
    my $ua  = shift;

# connection type, ip address, port number, options, file
    #my $arg = pack ('H*', $hex);
    # strip off the header pattern
    $arg =~ s/\Q$ua->{'pattern'}://;
    chomp $arg;
    print "arg is $arg\n";
    
    my ($type, $ip, $port, $options, $file) = split (':', $arg, 5);
    my $opts = {};
    foreach my $opt (split ',', $options) {
	my ($k, $v) = split ('=', $opt);
	$opts->{$k} = $v;
    }
    print Dumper $opts;

    # if there are builtin options, override the ones passed in
    if (defined $ua->{'options'}) {
	foreach my $k (keys (%{$ua->{'options'}})) {
	    $opts->{$k} = $ua->{'options'}->{$k};
	}
    }

    my @strs = ();
    foreach my $k (keys %$opts) {
	push @strs, $k . '=' . $opts->{$k};
    }

    my $str = join ',', @strs;
    
    
    $SEND_CONN->print ("$type:$ip:$port:$str:$file\n");


} # send_handler
