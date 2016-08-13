#!/usr/bin/perl -w


my @machines =  ();
push @machines, 7, 10;

foreach my $machine (@machines) {

	my $addr = "10.0.0.$machine";

	sleep 1;
	# keep going if we are the parent
	next if (fork ());

	#system '/usr/bin/ssh', $addr, 'rm', '-rf', '/root/traffic';
	exec '/usr/bin/ssh', 'root@' . $addr, 'killall', '-9', 'perl';

}
