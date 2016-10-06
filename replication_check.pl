#!/usr/bin/perl -w
=head1 NAME
replication_status.pl

=head1 DESCRIPTION
This script connects to a FreeNAS(R) server via SSH, it then runs a simple
one line command on the server, which returns information regarding the
currently running replication process.

The returned information is converted into a more readable format, which
is printed to the screen as well as being appended to a file for later
review and comparrison of progress.

=cut
##############################
##### MODULE "IMPORTING" #####
use strict;
use Net::OpenSSH;
use Math::Round;
use Term::ReadKey;
use Getopt::Std;
use Path::Class;
use autodie;
use POSIX qw(strftime);

#####################
##### VARIABLES #####
my $res1 = "";
my $res2 = "";
my $SSH_USR = "mrisser";

# Copy and change the following line as many times as needed to cover all
# of your FreeNAS(R) servers
my $tns1 = "192.168.1.28";
my $tns2 = "192.168.3.21";

# The following line is what gets run on the FreeNAS(R) server to show
# the progress of the replication.
my $PS = 'ps auxwwU root | grep "zfs:" | sed "s/\// /g"';

# The following lines allow you to enter your password without it being displayed...
print "Enter SSH password:\n";
ReadMode 2;
my $SSH_PASS = <>;
ReadMode 1;
chomp($SSH_PASS);

#####################
##### FUNCTIONS #####

# The following function is the 'heavy lifter' of the script; connecting
# to the designated FreeNAS(R) server, running the command and formatting
# the results.
sub get_rep_status {
	my ($tns, $USR, $PASS) = @_;
	
	# First we will connect to the FreeNAS box...
	print "Connecting to $tns...\n";
	my $ssh = Net::OpenSSH->new($USR.":".$PASS."@".$tns) or die("Can't SSH to $tns: " . Net::OpenSSH->error);
	
	# ...and get the output of ls on the replication directory
	print "Checking replication status...\n";
	my $stats = $ssh->capture($PS);
	my @stats = split(" ", $stats);
	my $snapshot = $stats[13];
	my $perc = $stats[14];
	my $sent = $stats[15];
	my $size = $stats[16];
	
	# Remove unwanted characters
	$perc =~ tr/(://d;
	$size =~ tr/)//d;
	
	# Get the size in GB
	$sent = round($sent / 1024 / 1024 / 1024);
	$size = round($size / 1024 / 1024 / 1024);
	$ssh->disconnect();
	
	my @mabbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my ($seconds, $minutes, $hour, $monthday, $month, $year, $wday, $yday, $isdst) = localtime(time);
	
	$year += 1900;
	
	if($seconds < 10) {
		$seconds = "0" . $seconds;
	}
	
	if($minutes < 10) {
		$minutes = "0" . $minutes;
	}
	
	if($hour < 10) {
		$hour = "0" . $hour;
	}
	
	if($month < 10) {
		$month = "0" . $month;
	}
	
	if($monthday < 10) {
		$monthday = "0" . $monthday;
	}
	
	my $status = "\tSnapshot: $snapshot\n\tComplete: $perc\n\tSent: $sent GB of $size GB\n\t$hour:$minutes:$seconds - $monthday $mabbr[$month] $year\n";
	
	return $status;
}

#########################
##### "MAIN" SCRIPT #####
# Connect to each server in turn
# Copy and change the following line as many times as needed to cover all
# of your FreeNAS(R) servers
$res1 = get_rep_status($tns1, $SSH_USR, $SSH_PASS);
$res2 = get_rep_status($tns2, $SSH_USR, $SSH_PASS);

# Print the results to the screen
print "\n$res1\n";
print "\n$res2\n";

# Write the results to a file for later comparisson
my $dir = dir("/tmp"); # /tmp

my $file = $dir->file("replication-report.txt"); # /tmp/file.txt

# Get a file_handle (IO::File object) you can write to
my $fh = $file->open('>>');
$fh->print("\n$res1\n\n$res2\n----------------------------------------\n");
$fh->close();
