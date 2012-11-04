#!/usr/bin/perl
#
# Script to calculate the average end-to-end delay for NS-2 new trace file format with multiple
# transmitting sources
#
# Author: Ricardo J. Ulisses Filho
# Universidade de Pernambuco - Recife - Brazil
# Departamento de Sistemas e Computacao
#

use strict;
$| = 1;

# required parameters
my $simulation_time = $ARGV[0] || &usage;
my $agent_sources   = $ARGV[1] || &usage;
my $flow_file 	    = $ARGV[2] || &usage;

# global variables
my $DEBUG  = 0;
#my $flow_file = "delay.dat";
my $flow_delay_time;
my @flow_conn;
my %flow_delay;
my %flow_time;
my %flow_delay_count;
my $count = 0;
my $time_int_prev = 0;
my @traffic_sources = ();
my $simulation_start;
my $delay_average_sum = 0;
sub print_debug($);

# initialize flow_tp and traffic_sources for each simulation second
for (my $i = 0; $i <= $simulation_time; $i++) {
        $flow_conn[$i]  = 0; # how many traffic sources we have per time period
}

# parsing and delay flow accounting
while (my $line = <STDIN>) {
        $count++;
        # considers only agent trace
        if ($line =~ /AGT/) {
                if ($line =~ /^(s|r)\s+-t\s+(\S+)/) {
                        my $event = $1;
			my $time  = $2;                                                        
                        my $time_int = int $time;
                        if ($time_int != $time_int_prev) { # verifies if we are in a new time period of simulation time
                                @traffic_sources = (); # clear array of traffic sources per time period
                        }

                        $time_int_prev = $time_int;

                        if ($line =~ /-Is\s+(\S+)\s+-Id\s+(\S+).*?-Ii\s+(\S+)/) {
                                my $flow_id = "$1:$2"; # our flow id is made by both sender and destination ip.port
                                my $unique_id = $3;
                                $flow_time{$flow_id}{$unique_id}{$event} = $time * 1000; # let's give results in millisecond

                                # when the packet is being received the actual delay calculation occurs
                                if ($event eq 'r') {
                                        if ( scalar(grep(/^$flow_id$/, @traffic_sources)) == 0) {
                                                push @traffic_sources, $flow_id;
                                                $flow_conn[$time_int]++;
                                        }

                                        print_debug "flow_delay_time = $flow_time{$flow_id}{$unique_id}{'r'} - $flow_time{$flow_id}{$unique_id}{'s'};\n";

                                        $flow_delay_time = $flow_time{$flow_id}{$unique_id}{'r'} -$flow_time{$flow_id}{$unique_id}{'s'};
                                        $flow_delay_time = sprintf("%.1f", $flow_delay_time);
                                        $flow_delay{$time_int}{$flow_id} += $flow_delay_time;

                                        # how many packets were delivered within $time_int?
                                        if (!$flow_delay_count{$time_int}{$flow_id}) {
                                                $flow_delay_count{$time_int}{$flow_id} = 1;
                                        } else {
                                                $flow_delay_count{$time_int}{$flow_id} = $flow_delay_count{$time_int}{$flow_id} + 1;

                                        }

                                        print_debug "flow_delay_count{$time_int}{$flow_id} => $flow_delay_count{$time_int}{$flow_id}\n";
                                        print_debug "flow_delay_time => [$flow_delay_time]\n";
                                        print_debug "flow_id => [$flow_id] time_int => [$time_int] flow_conn => [$flow_conn[$time_int]]\n";
                                }
                        }
                }
        } else {
                print_debug "skipping meaningless line: $count\n";
        }

}

# generating plot file
print_debug "generating plot file...\n";
open(PLOTFILE, ">$flow_file") or die("could not open $flow_file: $!");
for (my $i = 0; $i <= $simulation_time; $i++) {
        if ($flow_conn[$i] == 0) {
                print PLOTFILE "$i " . 0 . "\n";
                next;
        }

        if (!defined($simulation_start)) {
                $simulation_start = $i;
        }
        my %delay_sum_per_source;

        # average on the number of packets per source (local avg)
        for my $flow_id (keys %{ $flow_delay{$i} }) {
                $delay_sum_per_source{$flow_id} = $flow_delay{$i}{$flow_id} / $flow_delay_count{$i}{$flow_id};

        }

        # average on the value of avg_delay per number of sources in time (global avg)
        my $delay_sum_per_sec = 0;
        for my $flow_id (keys %{ $flow_delay{$i} }) {
                $delay_sum_per_sec += $delay_sum_per_source{$flow_id};
        }

        $delay_sum_per_sec /= $flow_conn[$i]; # divided by the number of sources
        $delay_sum_per_sec  = sprintf("%.1f", $delay_sum_per_sec);
        print PLOTFILE "$i " . $delay_sum_per_sec . "\n";
        $delay_average_sum  += $delay_sum_per_sec;

}

close(PLOTFILE) or die("could not write file $flow_file: $!");
my $simulation_range = $simulation_time - $simulation_start;
my $delay_avg_total = $delay_average_sum / $simulation_time;
$delay_avg_total = sprintf("%.1f", $delay_avg_total);
print_debug "result: average delay in time equals to " . $delay_avg_total . "ms\n";
print "$delay_avg_total\n";
exit 0;

# Subroutines

sub usage {
	print "cat file.tr | ./delay_calc_avg-ng.pl simulation_time_in_seconds agent_sources\n";
        exit 1;
}

sub print_debug($) {
        if ($DEBUG) {
                print @_;
        }
}
