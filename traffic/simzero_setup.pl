#!/usr/bin/perl -w


my @machines =  ();
push @machines, 7, 10;

foreach my $machine (@machines) {

	my $addr = "10.0.0.$machine";

	sleep 1;
	# keep going if we are the parent
	next if (fork ());

	#system '/usr/bin/ssh', "root@$addr", 'rm', '-rf', '/root/traffic';
	#system 'rsync', '-avz', '/tmp/traffic/', "$addr:/root/traffic/";
	system '/usr/bin/ssh', 'root@' . $addr, '/root/sz/traffic/run_traffic.pl', '--startservers' if (fork());
	sleep 30;
	print "ready to start servers for $addr\n";
	exec '/usr/bin/ssh', 'root@' . $addr, '/root/sz/traffic/run_traffic.pl', '--startclients';

}
