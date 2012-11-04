
<!-- saved from url=(0065)http://www.monarch.cs.rice.edu/ftp/monarch/wireless-sim/ad-hockey -->
<html><head><meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">#!/usr/local/bin/perl

require 5.005;

use strict subs, vars;

#NOTE:  this version of ad-hockey WILL NOT work with Perl/Tk400.200
# provide a path to perl/Tk if it's not installed in the default places
use lib '/usr/ns/Tk800.015';
use lib '/usr/ns/Tk800.015/blib/arch';
use lib '/usr/ns/Tk800.015/blib/lib';

use English;
use Tk;
use Tk::Dialog;
use lib;
use FileHandle;
use IPC::Open2;
use Socket;
use Tk qw/:eventtypes/;		# Event Types used by DoOneEvent()

require 'dumpvar.pl';

### Major State variables
my @WP;            # array of waypoint display windows
my @EDIT;          # array of waypoint entry edit windows
my @NUM_TIMES;     # N_T[x] is number of entries in node x's move
my @MOVE;          # descr of each node's trajectory
  my $SPEED = 1;
  my $TIME = 2;    # TIME used below as well !!!!! DON'T CHANGE !!!!
  my $TOX = 3;
  my $TOY = 4;
  my $PT = 5;

my @SAVED_MOVE;    # the clipboard (kill ring) for saved waypoint trajectories
my @NODE_ATTR;     # list of node attributes (list of refs to hashes)

my $rad_pitt_lon = 6398938.9083136;
my $rad_pitt_lat = 4861687.95522115;

my $PI = 3.14159;
my $NW_CORNER_LAT = 40.4347880048;
my $NW_CORNER_LON = -79.9708580832;
my $BASE_TIME = -1.0;

### state variables
my $running = 0;
my $delay = 0;
my $base_real_time;
my $base_sim_time;
my $reset_time = 1;
my $time_scale = 2.0;
my $behind_marker = 0;
my $skip = 0;
my $show_feasible_connections = 1;
my $trace_loaded = 0;
my $autorewind = 0;
my $show_range_circles = 0;
my $show_cobwebs = 0;

my $pctd_file = 0;   # is trace file in pctd format?
my $addrmap_file = "pctd-addrmap";
my @pctd_header;
my %ADDRMAP;
my %PCTD_DATA;

my $trace_on = 0;
my $show_agt = 0;
my $show_rtr = 0;
my $show_pkt_lines = 0;
my $show_originations = 0;

# should we wait for sync message from macfilter server before actually
#  starting to run the scenario?
my $wait_for_macfilter_server = 0;  
# are we slaved to an ns emulation server, such that we should look for 
#  time sync messages from it, and obey them when they arrive?
my $slave_to_ns = 0;
my $slave_to_ns_port = 3636;
my $NS_SLAVE_MSG_FORMAT = "N";
my $NS_SLAVE_MSG_LEN = 4;

### declarations
sub toggle_display;
sub set_speed;
sub set_filepos;
sub do_id_colors;
sub change_time;		# update all time vars to new time
sub DisplayPositions;      #show positions of all nodes
sub DisplayEvent;
sub add_node;
sub display_waypoints;      #popup the waypoint display for this node
sub reposition_waypoint;    #allow user to move waypoint with mouse

sub show_connections;	    # deprecated.  shows spiderweb of reachability
			    # see make-usrc-rts for building connection file

sub CheckNSSlave;		# check for orders from ns we're slaved to

sub ReadScenario;
sub SaveScenario;
sub PrintMovements;

sub PeekNextEventTime;
sub GetNextEvent;
sub OpenTraceFile;
sub SetNextEventTime;

### configuration variables
my $MAXX = 1000;
my $MAXY = 1000;
my $RANGE = 250.0;     # nominal xmission range of xmitters
my $LINK_BW = 2.0e+6;# nominal link bandwidth

my $SCALE;           # screen pixels per meter
my $NN = 0;          # number of nodes
my $MAX_TIME = 900;  # end of time in simulator

my $CUR_TIME = 0.0;   # current time
my $EP = 1.0e-5;   # epsilon for distance and time computations

my $MAC_PORT = 3636;
my $MAC_MSG_LEN = 516;
my $MAC_MSG_FORMAT = "A512 N";

### GUI variables
my $FONT = '-*-Helvetica-Medium-R-Normal--*-140-*-*-*-*-*-*';

# the size of the main canvas in pixels, assuming a background 
# image isn't loaded.  In that case, the size of the image is used.
my $SCREENX = 750;
my $SCREENY = 400;
#my $SCREENX = 1200;
#my $SCREENY = 600;

#my $DOT_SIZE = 4;                      # radius of the plotting dots (pixels)
#my $WP_DOT_SIZE = $DOT_SIZE + 5;
my $DOT_SIZE = 9;                      # radius of the plotting dots (pixels)
my $WP_DOT_SIZE = $DOT_SIZE - 4;       # waypoint dot size

my $EVENT_PER_SEC = 10;
my $TRACED_EVENT_PER_SEC = 2;  # was 2 before 12/10/98 -dam

# default filnames and strings (updated as the user changes things)
my $default_scenario = "";
my $default_trace = "";
my $default_commpattern = "";
my $default_comment = "";
my $default_slowdown = -1;

# info about file loaded as background of movement canvas
my $bitmap_file = "";
my $bitmap_xdim = 0;
my $bitmap_ydim = 0;

# high contrast colors I've found
# deepskyblue1, PaleTurquoise1, turquoise1,green2,khaki1, gold1
# IndianRed1, sienna1, firebrick1, DeepPink1

my $normal_canvas_bkgnd = 'lightblue';
my $behind_canvas_bkgnd = 'khaki2';
my $node_color = 'black';
my $node_highlight = 'yellow';
my $range_circle_color = 'yellow';
my $cobweb_color = 'yellow';
my %rtr_colors = ('s' =&gt; 'red', 'f' =&gt; 'darkorange1', 'r' =&gt; 'green');
my %agt_colors = ('s' =&gt; 'IndianRed1', 'f' =&gt; 'black', 'r' =&gt; 'paleturquoise1');
my $waypoint_color = 'gray50';
my $waypoint_highlight_color = 'yellow';
my $conn_color = 'SlateGray';

my $obst_color = 'grey30';
my $obst_width = 3;
my $default_permeability = 13;   # db of attenuation

########### UI elements
my $MW;				# the Main window
my $CANVAS;			# the main canvas
my $info_display;		# bottom line text widget on figure
my ($speed_scale, $speed_display); # speed slider and text widget
my $start_but;			# start button
my ($scale_text, $comment_text);
my $timepos_scale;		# slider scale showing current time
my ($idscale, $idcolor1_id, $idcolor2_id, $idcolor3_id, $idcolor4_id);

###########################################################################
###########################################################################
# Read or write the movement array from a scenario file
###########################################################################
#NOTE:  This code makes all sorts of wild assumptions about what a 
# scenario file looks like.  In particular, 
# 1) the initial postions for a node must appear as set Z, set Y, set X.
# 2) it used to assume the times of setdest's must count down through the file
#    but this restriction is relaxed now.  We continue to output files in 
#    this format so they are read faster by ns.

sub FindInsertIndex {
    my ($node, $time) = @ARG;
    my ($i,$j);

#    print "starting\n";
#    dumpValue(\$MOVE[$node]);
#    print "doing\n";

    for ($i = 0; $i &lt; $NUM_TIMES[$node]; $i ++) {
	if ($time &lt;= $MOVE[$node]-&gt;[$i]-&gt;[$TIME] 
	    &amp;&amp; !$MOVE[$node]-&gt;[$i]-&gt;[0]) {
	    for ($j = $NUM_TIMES[$node]; $j &gt; $i; $j--) {
		$MOVE[$node]-&gt;[$j] = @MOVE[$node]-&gt;[$j-1];
	    }
	    last;
	}
    }
    $MOVE[$node]-&gt;[$i] = [];

#    dumpValue(\$MOVE[$node]);
#    print "done\n\n";	    

    return $i;
};

sub ReadScenario {
    my ($SCEN) = @ARG;
    my ($time, $node, $tox, $toy, $speed, $index);
    my ($initx, $inity, $nxy) = (-1, -1, -1); # node nxy starting x,y loc 

    if (!open(SCEN,"&lt;$SCEN")) {
	Msg("Can't read scenario file $SCEN\n");
	return -1;
    }
    
    $bitmap_file = "";
    $bitmap_xdim = 0;
    $bitmap_ydim = 0;

    while(&lt;SCEN&gt;) {

	if (/at (\d+\.\d+|\d+) .*node_\((\d+)\) setdest (\d+.\d+) (\d+.\d+) (\d+.\d+)/) {
# movement set lines like
#$ns_ at 825.29 "$node_(4) setdest 318.756 257.1639283 1.000000000000"
	    $time = $1;
	    $node = $2;
	    $tox = $3;
	    $toy = $4;
	    $speed = $5;

	    $index = FindInsertIndex($node,$time);
	    $MOVE[$node]-&gt;[$index]-&gt;[$TIME] = $time;
	    $MOVE[$node]-&gt;[$index]-&gt;[$TOX] = $tox;
	    $MOVE[$node]-&gt;[$index]-&gt;[$TOY] = $toy;
	    $MOVE[$node]-&gt;[$index]-&gt;[$SPEED] = $speed;
	    $NUM_TIMES[$node]++;

	} elsif (/nodes: (\d+), max time: (\d+.\d+), max x: (\d+.\d+), max y: (\d+.\d+)/) {
# new style lines	    
## nodes: 50, max time: 900.00, max x: 1500.00, max y: 300.00
	    
	    $NN = $1;
	    $MAX_TIME = $2;
	    $MAXX = $3;
	    $MAXY = $4;
	    
	} elsif (/nodes: (\d+),.*max x = (\d+.\d+), max y: (\d+.\d+)/) {
# old style lines
## nodes: 50, pause: 30.00, max speed: 1.00  max x = 1500.00, max y: 300.00
	    
	    $NN = $1;
	    $MAXX = $2;
	    $MAXY = $3;
	    # use whatever we have now as the MAX_TIME for old format scenario files

	} elsif (/nominal range: (\d+.\d+) link bw: (\d+.\d+)/) {
## nominal range: 250.0 link bw: 2000000.00
	    $RANGE = $1;
	    $LINK_BW = $2;

	} elsif (/comm pattern: ([---\w_\#\.]+)/) {
## comm pattern: comm-123
	    if ($default_commpattern eq "") {
		$default_commpattern = $1;
	    }

	} elsif (/background bitmap: ([---\w_\#\.]+) (\d+) (\d+)/) {
## background bitmap: site.xbm 430 540
	    $bitmap_file = $1;
	    $bitmap_xdim = $2;
	    $bitmap_ydim = $3;

	} elsif (/^\# attribute: node (\d+) (.*)$/) {	    
## attribute: node 1 color: red text: 'cmmdr'
	    my %attr;
	    $attr{'node'} = $1;
	    my $attribs = $2;
	    if ($attribs =~ /color: (\w+)/) { $attr{'color'} = $1; }
	    if ($attribs =~ /after: ([\d\.]+)/) { $attr{'after'} = $1; }
	    if ($attribs =~ /text: '(.*)'/) { $attr{'text'} = $1; }
	    @NODE_ATTR = (@NODE_ATTR, \%attr);

	} elsif (/^.node_\((\d+)\) set Y. (\d+)/) {
#$node_(7) set Y_ 0.000000000000
	    
	    $node = $1;
	    $toy = $2;

	    if (-1 == $nxy) {
		$nxy = $node;
		$inity = $toy;
	    } elsif ($nxy != $node) {
		die "Badly formatted scenario file: no X addr for node $nxy ?\n";
	    } else {
		$inity = $toy;
	    }
	    
	} elsif (/^.node_\((\d+)\) set X. (\d+)/) {
#$node_(7) set X_ 0.000000000000
	    
	    $node = $1;
	    $tox = $2;

	    if (-1 == $nxy) {
		$nxy = $node;
		$initx = $tox;
	    } elsif ($nxy != $node) {
		die "Badly formatted scenario file: no Y addr for node $nxy ?\n";
	    } else {
		$initx = $tox;
	    }

	} elsif (/(^\#)|(\n)|(\$node_\(\d+\) set Z_ 0.0)/) {
	    # do nothing
	} else {
	    print "Ignoring line in scenario file:'$_'\n";
	}

	if (-1 != $initx &amp;&amp; -1 != $inity) {
	    $index = FindInsertIndex($nxy,0.0);
	    if ($index != 0) {die "DFU: inserting start point for node $nxy"}
	    
	    # magic value to indicate this entry must be first
	    $MOVE[$nxy]-&gt;[$index]-&gt;[0] = 1;  
	    $MOVE[$nxy]-&gt;[$index]-&gt;[$TOX] = $initx;
	    $MOVE[$nxy]-&gt;[$index]-&gt;[$TOY] = $inity;
	    $MOVE[$nxy]-&gt;[$index]-&gt;[$TIME] = 0.0;
	    $MOVE[$nxy]-&gt;[$index]-&gt;[$SPEED] = 0.0;
	    $NUM_TIMES[$nxy]++;
	    ($initx, $inity, $nxy) = (-1, -1, -1);  # reset state vars
	}

    }
    close(SCEN);

#    PrintMovements();

# - Now as a postprocessing step, find the moves with 0.0 speed and convert
# them into pause time entries on the following record
# - if the last record has a speed 0, just leave it, since it should still
# work properly (cause no motion from then on)
    my ($i, $j);
    for ($i = 1; $i &lt;= $NN; $i++) {
	for ($j = 1; $j &lt; $NUM_TIMES[$i] - 1; $j++) {
	    if ($MOVE[$i]-&gt;[$j]-&gt;[$SPEED] == 0.0) {
		# remove this record and make it a pause time entry on the next 1
		$MOVE[$i]-&gt;[$j+1]-&gt;[$PT] = 
		    $MOVE[$i]-&gt;[$j+1]-&gt;[$TIME] - $MOVE[$i]-&gt;[$j]-&gt;[$TIME];
		$MOVE[$i]-&gt;[$j+1]-&gt;[$TIME]  = $MOVE[$i]-&gt;[$j]-&gt;[$TIME];
		
		# move all the records down one position
		my $k;
		for ($k = $j ; $k &lt; $NUM_TIMES[$i]; $k++) {
		    $MOVE[$i]-&gt;[$k] = @MOVE[$i]-&gt;[$k+1];
		}
		$NUM_TIMES[$i]--;
	    }
	}  
    }


    ConfigureUI(); # unfortunately has to be done before Read Obstacles can
                   # draw things

    ReadObstacles($SCEN);

    return 1;
}



##
## print all the movement records
##
sub PrintMovements {
    my ($i, $j);
    print "num nodes $NN    X $MAXX     Y $MAXY \n";
    for ($i = 1; $i &lt;= $NN; $i++) {
	for ($j = 0; $j &lt; $NUM_TIMES[$i]; $j++) {
	    printf("%d: node $i time %f speed %f pt %f tox %f toy %f\n",
		   $j,
		   $MOVE[$i]-&gt;[$j]-&gt;[$TIME],
		   $MOVE[$i]-&gt;[$j]-&gt;[$SPEED],
		   $MOVE[$i]-&gt;[$j]-&gt;[$PT],
		   $MOVE[$i]-&gt;[$j]-&gt;[$TOX],
		   $MOVE[$i]-&gt;[$j]-&gt;[$TOY]);
	}    
	print "\n";
    }
}

sub SaveScenario {
    my ($SCEN) = @ARG;

    if (! open(SCEN, "&gt;$SCEN")) {
	Msg("Can't write $SCEN");
	return;
    }

# write out comments like:
#
# nodes: 50, max time 900.00, max x: 1500.00, max y: 300.00
# nominal range: 250.0 link bw: 2000000.00
# comm pattern: comm123
#
    printf(SCEN "#\n");
    printf(SCEN "# nodes: %d, max time: %f, max x: %f, max y: %f\n",
	   $NN, $MAX_TIME, $MAXX, $MAXY);
    printf(SCEN "# nominal range: %f link bw: %f\n",$RANGE,$LINK_BW);
    printf(SCEN "# comm pattern: $default_commpattern \n");
    printf(SCEN "# background bitmap: $bitmap_file $bitmap_xdim $bitmap_ydim\n");
    printf(SCEN "#\n");


    my ($rattr);
    foreach $rattr (@NODE_ATTR) {
	my (%attr) = (%$rattr);

	printf(SCEN "# attribute: node $attr{'node'} ");
	delete $attr{'node'};
	if (exists $attr{'text'}) {
	    printf(SCEN "text: '$attr{'text'}' ");
	    delete $attr{'text'};
	}
	my $i;
	foreach $i (keys %attr) {
	    printf(SCEN "$i: $attr{$i} ");	    
	    delete $attr{$i};
	}
	printf(SCEN "\n");
    }

    my ($node, $wp);
    for ($node = 1; $node &lt;= $NN; $node ++) {
	for ($wp = $NUM_TIMES[$node] - 1; $wp &gt; 0; $wp--) {
	    printf(SCEN '$ns_ at %.9f "$node_(%d) setdest %.9f %.9f %.9f"%s',
		  $MOVE[$node]-&gt;[$wp]-&gt;[$TIME] + $MOVE[$node]-&gt;[$wp]-&gt;[$PT],
		  $node, 
		  $MOVE[$node]-&gt;[$wp]-&gt;[$TOX], 
		  $MOVE[$node]-&gt;[$wp]-&gt;[$TOY],
		  $MOVE[$node]-&gt;[$wp]-&gt;[$SPEED],"\n");
	    if ($MOVE[$node]-&gt;[$wp]-&gt;[$PT] != 0) {
		printf(SCEN '$ns_ at %.9f "$node_(%d) setdest %.9f %.9f %.9f"%s',
			$MOVE[$node]-&gt;[$wp]-&gt;[$TIME],
			$node, 
			$MOVE[$node]-&gt;[$wp-1]-&gt;[$TOX], 
			$MOVE[$node]-&gt;[$wp-1]-&gt;[$TOY],
			0.0,"\n");
	    }
	}
	printf(SCEN '$node_(%d) set Z_ 0.0%s',$node,"\n");
	printf(SCEN '$node_(%d) set Y_ %.9f%s',
		$node, $MOVE[$node]-&gt;[0]-&gt;[$TOY],"\n");
	printf(SCEN '$node_(%d) set X_ %.9f%s',
		$node, $MOVE[$node]-&gt;[0]-&gt;[$TOX],"\n");
    }
    close(SCEN);
    SaveObstacles($SCEN,'append');
    Msg("Saved scenario to $SCEN");
};

###########################################################################
sub MakeMenus {
    my ($MW) = @ARG;

    my $mf = $MW-&gt;Frame(-relief =&gt; 'raised', -borderwidth =&gt; 2);
    $mf-&gt;pack(-fill =&gt; 'x');
    
    my $file = $mf-&gt;Menubutton(-text =&gt; 'File', -underline =&gt; 0);
    $file-&gt;command(-label =&gt; 'Load/Save Files ...', -command =&gt; \&amp;FileMenu);
    $file-&gt;command(-label =&gt; 'Print', -command =&gt; \&amp;print_it);
    $file-&gt;checkbutton(-label =&gt; 'Autorewind', 
			-variable =&gt; \$autorewind);
    $file-&gt;command(-label =&gt; 'Clear All', -command =&gt; \&amp;ClearAll );
    $file-&gt;separator;
    
    $file-&gt;cascade(-label =&gt; 'Remote Operation', -underline =&gt; 0);
    my $file_menuwin = $file-&gt;cget(-menu);
    my $remote_ops = $file_menuwin-&gt;Menu();
    $file-&gt;entryconfigure('Remote Operation', -menu =&gt; $remote_ops );
    $remote_ops-&gt;checkbutton(-label =&gt; 'Slave to ns emulation server',
			     -variable =&gt; \$slave_to_ns);
    $remote_ops-&gt;separator;
    $remote_ops-&gt;separator;
    $remote_ops-&gt;checkbutton(-label =&gt; 'Wait for Macfilter server',
			     -variable =&gt; \$wait_for_macfilter_server);


    $file-&gt;separator;
    $file-&gt;command(-label =&gt; 'Exit', -command =&gt; sub{exit;} );
    $file-&gt;pack(-side=&gt;'left', -padx =&gt; 3);



    my $trace = $mf-&gt;Menubutton(-text =&gt; 'Trace', -underline =&gt; 0);
    $trace-&gt;checkbutton(-label =&gt; 'Show Originations', 
			-variable =&gt; \$show_originations);
    $trace-&gt;checkbutton(-label =&gt; 'Show AGT events', -variable =&gt; \$show_agt);
    $trace-&gt;checkbutton(-label =&gt; 'Show RTR events', -variable =&gt; \$show_rtr);
    $trace-&gt;checkbutton(-label =&gt; 'Trace Packets', 
			-variable =&gt; \$show_pkt_lines);
    $trace-&gt;separator;
    
    sub ToggleRangeCircles {
	if ($show_range_circles) {
	    $trace-&gt;entryconfigure('Turn OFF range circles', 
				   -label =&gt; 'Turn ON range circles');
	    $show_range_circles = 0;
	} else {
	    $trace-&gt;entryconfigure('Turn ON range circles', 
				   -label =&gt; 'Turn OFF range circles');
	    $show_range_circles = 1;
	}
	$CANVAS-&gt;delete('node');     # delete all nodes
	DisplayPositions($CUR_TIME); # show them again
	DoNodeAttributes();	     # make them look right
    }

    if ($show_range_circles) {	
	$trace-&gt;command(-label =&gt; 'Turn OFF range circles', 
		    -command =&gt; \&amp;ToggleRangeCircles );
    } else {
	$trace-&gt;command(-label =&gt; 'Turn ON range circles', 
		    -command =&gt; \&amp;ToggleRangeCircles );
    }

    sub ToggleCobwebs {
	if ($show_cobwebs) {
	    $trace-&gt;entryconfigure('Turn OFF cobwebs', 
				   -label =&gt; 'Turn ON cobwebs');
	    $show_cobwebs = 0;
	    $CANVAS-&gt;delete('cobweb');
	} else {
	    $trace-&gt;entryconfigure('Turn ON cobwebs', 
				   -label =&gt; 'Turn OFF cobwebs');
	    $show_cobwebs = 1;
	}
	$CANVAS-&gt;delete('node');     # delete all nodes
	DisplayPositions($CUR_TIME); # show them again
	DoNodeAttributes();	     # make them look right
    }

    if ($show_cobwebs) {	
	$trace-&gt;command(-label =&gt; 'Turn OFF cobwebs', 
		    -command =&gt; \&amp;ToggleCobwebs );
    } else {
	$trace-&gt;command(-label =&gt; 'Turn ON cobwebs', 
		    -command =&gt; \&amp;ToggleCobwebs );
    }

    $trace-&gt;separator;
    $trace-&gt;command(-label =&gt; 'Color key:', -command =&gt; sub {;});
    $trace-&gt;command(-label =&gt; '   Application send', -background =&gt; $agt_colors{s},
		    -command =&gt; sub {;});
    $trace-&gt;command(-label =&gt; '   Application recv', -background =&gt; $agt_colors{r},
		    -command =&gt; sub {;});
    $trace-&gt;command(-label =&gt; '   Router send', -background =&gt; $rtr_colors{s},
		    -command =&gt; sub {;});
    $trace-&gt;command(-label =&gt; '   Router forw', -background =&gt; $rtr_colors{f},
		    -command =&gt; sub {;});
    $trace-&gt;command(-label =&gt; '   Router recv', -background =&gt; $rtr_colors{r},
		    -command =&gt; sub {;});
    $trace-&gt;pack(-side=&gt;'left', -padx =&gt; 3);



    my $build = $mf-&gt;Menubutton(-text =&gt; 'Construction-Tools', 
				-underline =&gt; 0);
    $build-&gt;command(-label =&gt; 'Configuration ...', 
		    -command =&gt; \&amp;Configuration );
    $build-&gt;command(-label =&gt; 'Schedule Packets ...',
		    -command =&gt; \&amp;ScheduleOriginations);
    $build-&gt;separator;
    $build-&gt;command(-label =&gt; 'Add Node', -command =&gt; \&amp;add_node );    
    $build-&gt;separator;
    $build-&gt;command(-label =&gt; 'Create Obstacles:', -command =&gt; sub {;} );    
    $build-&gt;command(-label =&gt; '   Add Box', -command =&gt; \&amp;AddBox );    
    $build-&gt;command(-label =&gt; '   Add Line', -command =&gt; \&amp;AddLine );    
    $build-&gt;command(-label =&gt; '   Delete Obst', -command =&gt; \&amp;DeleteObst );    
    $build-&gt;pack(-side=&gt;'left', -padx =&gt; 3);
}

sub MakeControls {

    my ($controls) = @ARG;
    $start_but = $controls-&gt;Button(
				      -text =&gt; "Start",
				      -width =&gt; 15,
				      -command =&gt; \&amp;toggle_display,
				      );
    my $skip_but = $controls-&gt;Button(
				     -text =&gt; "Skip",
				     -width =&gt; 15,
				     -command =&gt; sub {$skip = 1;},
				     );

    $start_but-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');
    $skip_but-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');
    $controls-&gt;pack(qw(-side bottom -fill x -pady 2m));
}  #end of MakeControls

###########################################################################
# top line of controls

###########################################################################
# speed control

sub MakeSpeedControl {
    my ($speed_id_frame) = @ARG;
    my $slf = $speed_id_frame-&gt;Frame(-relief =&gt; 'groove', -borderwidth =&gt; 2);
    my $sllf = $slf-&gt;Frame();
    $sllf-&gt;Label(-text =&gt; 'Time scale:', 
		-font =&gt; $FONT,)-&gt;pack(-side =&gt;'left');
    $speed_display = $sllf-&gt;Text(
				-font =&gt; $FONT,
				-relief =&gt; 'flat',
				-height =&gt; 1,
				-width =&gt; 34,
#				   -background =&gt; 'darkgray',
				borderwidth =&gt; 1,
				);
    $speed_display-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');
    $sllf-&gt;pack(-side =&gt; 'top');

    my $speed_scale = $slf-&gt;Scale(
       -font =&gt; $FONT,
       -orient =&gt; 'horizontal',
       -showvalue =&gt; 0,
       -from =&gt; 1,
       -to =&gt; 200.0,
       -length =&gt; '10c',
       -command =&gt; \&amp;set_speed,
       );
    $speed_scale-&gt;pack(-side =&gt; 'bottom', -expand =&gt; 'yes', -anchor =&gt; 'w');
    $slf-&gt;pack(-side =&gt; 'left');
    return $speed_scale;
};

sub set_speed {
    my $s = $speed_scale-&gt;get()/10;
    if ($s &gt; 10 ) {
	$time_scale = 10 + ($s - 10) * ($s - 10) * ($s - 10);
    } else {
	$time_scale = $s;
    }
    $reset_time = 1;
    my $scale_info = "$time_scale real sec = 1 simulation sec"; 
    $speed_display-&gt;delete('1.0','end');
    $speed_display-&gt;insert('1.0', $scale_info);
}

###########################################################################
# color id controls

sub MakeColorControls {
    my ($parent) = @ARG;

    my $id_frame = $parent-&gt;Frame(
       -relief =&gt; 'groove',
       -borderwidth =&gt; 3,
       );
    my $idscale = $id_frame-&gt;Scale(       
       -label =&gt; "White",
       -font =&gt; $FONT,
       -showvalue =&gt; 'yes',
       -orient =&gt; 'horizontal',
       -from =&gt; 0,
       -to =&gt; $NN,
       -length =&gt; '7c',
       -command =&gt; sub {
	   my $i;
	   for ($i = 1; $i &lt;= $NN ; $i++) {
	       $CANVAS-&gt;itemconfigure(node_marker_name($i), 
				      -fill =&gt; $node_color);
	   }
	   do_id_colors(); 
       },
       );
    $idscale-&gt;pack(-side =&gt; 'bottom', -anchor =&gt; 'w');

    my $idcolor1_id = $id_frame-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 3,			       
       );
    my $idcolor1_label = $id_frame-&gt;Label(-text =&gt; 'Cyan');
    $idcolor1_label-&gt;pack(-side =&gt; 'left');
    $idcolor1_id-&gt;pack(-side =&gt; 'left');

    my $idcolor2_id = $id_frame-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 3,			       
       );
    my $idcolor2_label = $id_frame-&gt;Label(-text =&gt; 'Magenta');
    $idcolor2_label-&gt;pack(-side =&gt; 'left');
    $idcolor2_id-&gt;pack(-side =&gt; 'left',);

    my $idcolor3_id = $id_frame-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 3,			       
				       );
    my $idcolor3_label = $id_frame-&gt;Label(-text =&gt; 'Orange');
    $idcolor3_label-&gt;pack(-side =&gt; 'left');
    $idcolor3_id-&gt;pack(-side =&gt; 'left',);

    my $idcolor4_id = $id_frame-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 3,			       
       );
    my $idcolor4_label = $id_frame-&gt;Label(-text =&gt; 'Pink');
    $idcolor4_label-&gt;pack(-side =&gt; 'left');
    $idcolor4_id-&gt;pack(-side =&gt; 'left',);

    $id_frame-&gt;pack(-side =&gt; 'left', -padx =&gt; '2c');
    return ($idscale, $idcolor1_id, $idcolor2_id, $idcolor3_id, $idcolor4_id);
}

###########################################################################
# scale info

sub MakeScaleLabelInfo {
    my ($parent) = @ARG;
    my $box = $parent-&gt;Frame(); 
    my $l1 = $box-&gt;Frame();
    $l1-&gt;Label(-text =&gt; 'Scale:', 
	       -font =&gt; $FONT)-&gt;pack(-side =&gt; 'left');
    my $scale_text = $l1-&gt;Text(
			    -font =&gt; $FONT,
			    -relief =&gt; 'sunken',
			    -height =&gt; 1,
			    -background =&gt; 'darkgray',
			    -borderwidth =&gt; 2,
			    );
    $scale_text-&gt;pack(-side =&gt; 'left');
    $l1-&gt;pack(-anchor =&gt; 'c');
    my $comment_text = $box-&gt;Text(
			       -font =&gt; '-*-Helvetica-bold-R-Normal--*-180-*-*-*-*-*-*',
			       -relief =&gt; 'flat',
			       -height =&gt; 1,
			       -width =&gt; 1,
#			       -background =&gt; 'darkgray',
			       -borderwidth =&gt; 2,
			       );
    $comment_text-&gt;pack(-side =&gt; 'bottom', -anchor =&gt; 'c', -pady =&gt; 15);
    $box-&gt;pack(-side =&gt; 'left');
    return ($scale_text, $comment_text);
}

###########################################################################
###########################################################################
sub MakeTimePosition {
    my ($pos_frame) = @ARG;
    my $timepos_label = $pos_frame-&gt;Label(-text =&gt; 'Time:', 
	       -font =&gt; $FONT)-&gt;pack(-side =&gt; 'left');
    my $timepos_scale = $pos_frame-&gt;Scale(
       -font =&gt; $FONT,
       -showvalue =&gt; 'yes',
       -orient =&gt; 'horizontal',
       -from =&gt; 0,
       -to =&gt; $MAX_TIME,
       -length =&gt; '15c',
       );
    $timepos_scale-&gt;set(0);
    $timepos_scale-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');

    my $back_ten = $pos_frame-&gt;Button(
        -text =&gt; "&lt;",
#       -width =&gt; 10,
        -command =&gt; sub{change_time($CUR_TIME - 0.1);},
);
    my $back_hundred = $pos_frame-&gt;Button(
        -text =&gt; "&lt;&lt;",
#       -width =&gt; 10,
        -command =&gt; sub{change_time($CUR_TIME - 1);},
);
    my $back_thousand = $pos_frame-&gt;Button(
        -text =&gt; "&lt;&lt;&lt;",
#       -width =&gt; 10,
        -command =&gt; sub{change_time($CUR_TIME - 10)},
);
    $back_ten-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -anchor =&gt; 'sw');
    $back_hundred-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -anchor =&gt; 'sw');
    $back_thousand-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -anchor =&gt; 'sw');

    return ($timepos_scale);
}

###########################################################################
###########################################################################
# Construct the UI
###########################################################################
sub BuildUIWithOneWindow {
    $MW = MainWindow-&gt;new;
    $MW-&gt;title('Ad Hockey');

    MakeMenus($MW);

    $CANVAS = $MW-&gt;Canvas(
			  -width =&gt; '15c',
			  -height =&gt; '15c',
			  -background =&gt; $normal_canvas_bkgnd,
			  );
    $CANVAS-&gt;pack;

    my $speed_id_frame = $MW-&gt;Frame(-borderwidth =&gt; 2,);
    my $timepos_frame = $MW-&gt;Frame(borderwidth =&gt; 2,);
    my $msg_frame =  $MW-&gt;Frame(borderwidth =&gt; 2,);
    my $controls_frame = $MW-&gt;Frame(-borderwidth =&gt; 0,);

    MakeControls($controls_frame);

    $info_display = $msg_frame-&gt;Text(
				     -font =&gt; $FONT,
				     -relief =&gt; 'sunken',
				     -height =&gt; 1,
				     -background =&gt; 'darkgray',
				     -borderwidth =&gt; 2,
				     );
    $info_display-&gt;pack();
    $msg_frame-&gt;pack($info_display, -side =&gt; 'bottom', -fill =&gt; 'x', -expand =&gt; 1);



    $speed_scale = MakeSpeedControl($speed_id_frame);
    $speed_scale-&gt;set(10);		# set default speed

    ($idscale, $idcolor1_id, $idcolor2_id, $idcolor3_id, $idcolor4_id) = 
	MakeColorControls($speed_id_frame);

    ($scale_text, $comment_text) = MakeScaleLabelInfo($speed_id_frame);

    $speed_id_frame-&gt;pack(-side =&gt; 'top');

    ($timepos_scale) = MakeTimePosition($timepos_frame);
    $timepos_frame-&gt;pack(-side=&gt; 'bottom');
}

sub BuildUIWithTwoWindows {
    $MW = MainWindow-&gt;new;
    $MW-&gt;title('Ad Hockey');

    $CANVAS = $MW-&gt;Canvas(
			  -width =&gt; '15c',
			  -height =&gt; '15c',
			  -background =&gt; $normal_canvas_bkgnd,
			  );
    $CANVAS-&gt;pack;
    my $msg_frame =  $MW-&gt;Frame(borderwidth =&gt; 2,);
    $info_display = $msg_frame-&gt;Text(
				     -font =&gt; $FONT,
				     -relief =&gt; 'sunken',
				     -height =&gt; 1,
				     -background =&gt; 'darkgray',
				     -borderwidth =&gt; 2,
				     );
    $info_display-&gt;pack();
    $msg_frame-&gt;pack($info_display, -side =&gt; 'bottom', -fill =&gt; 'x', 
		     -expand =&gt; 1);

    my $MW2 = MainWindow-&gt;new;
    $MW2-&gt;title('Ad Hockey Controls');
    MakeMenus($MW2);

    my $speed_id_frame = $MW2-&gt;Frame(-borderwidth =&gt; 2,);
    my $controls_frame = $MW2-&gt;Frame(-borderwidth =&gt; 0,);
    my $timepos_frame = $MW2-&gt;Frame(borderwidth =&gt; 2,);

    ($timepos_scale) = MakeTimePosition($timepos_frame);
    $timepos_frame-&gt;pack(-side=&gt; 'bottom');

    MakeControls($controls_frame);



    $speed_scale = MakeSpeedControl($speed_id_frame);
    $speed_scale-&gt;set(10);		# set default speed

    ($idscale, $idcolor1_id, $idcolor2_id, $idcolor3_id, $idcolor4_id) = 
	MakeColorControls($speed_id_frame);

    ($scale_text, $comment_text) = MakeScaleLabelInfo($speed_id_frame);

    $speed_id_frame-&gt;pack(-side =&gt; 'top');

}



###########################################################################
###########################################################################
# Mouse Callbacks and bindings
###########################################################################
sub mouse_enter_node { 
    my ($x, $y);
    my @tags = $CANVAS-&gt;gettags('current');
    my $tag_string = join(' ',@tags);
    if ( $tag_string =~ /\bmark-n(\d+)\b/o) {
	$CANVAS-&gt;itemconfigure(node_marker_name($1), 
			       -fill =&gt; $node_highlight);    
	Msg("Node: ".$1);

	my @coords = $CANVAS-&gt;coords('current');
	($x, $y) = @coords;
	$CANVAS-&gt;create('oval', 
			$x - scale_dist($RANGE) + $DOT_SIZE,
			$y - scale_dist($RANGE) + $DOT_SIZE,
			$x + scale_dist($RANGE) + $DOT_SIZE, 
			$y + scale_dist($RANGE) + $DOT_SIZE,
			-outline =&gt; $node_highlight, -tag =&gt; 'in-range');
    }
}

sub mouse_leave_node {
    my @tags = $CANVAS-&gt;gettags('current');
    my $tag_string = join(' ',@tags);
    if ( $tag_string =~ /\bmark-n(\d+)\b/o) {
	$CANVAS-&gt;delete('in-range');
	$CANVAS-&gt;itemconfigure('current', -fill =&gt; $node_color);    
	do_id_colors();
    }
}

sub msg_loc {
    my($w) = @ARG;
    my $e = $w-&gt;XEvent;
    my($x, $y) = ($e-&gt;x, $e-&gt;y);

    $x = unscale_dist($x);
    $y = unscale_dist($y);
    Msg("mouse at: $x,$y");
}

sub show_waypoints {
    my $node = shift;
    my @tags = $CANVAS-&gt;gettags('current');
    if (join(' ',@tags) =~ /\bn(\d+)\b/o) {
	display_waypoints($1);
    }
};

sub GetNode {
    # force the user to single click on a node.
    # rtns the number of the node the user clicked or -1 if they
    # clicked something else
    my $done = 0;
    my $node = -1;

    my $check_node = sub {
	my ($w, $d, $n) = @ARG;
	my @tags = $CANVAS-&gt;gettags('current');
	if (join(' ',@tags) =~ /\bn(\d+)\b/o) {
	    $$n = $1;	    
	}
	$$d = 1;
    };

    $MW-&gt;Tk::bind('&lt;Button-1&gt;' =&gt; [$check_node,\$done,\$node] );
    my ($opt,$name,$class,$default,$save_cursor) = $MW-&gt;configure('-cursor');
    $MW-&gt;configure(-cursor =&gt; 'crosshair');
    
    while (!$done) {
	DoOneEvent(DONT_WAIT | ALL_EVENTS);
    }
    $MW-&gt;Tk::bind('&lt;Button-1&gt;' =&gt; sub{;} );
    $MW-&gt;configure(-cursor =&gt; $save_cursor);

    return $node;
};

###########################################################################
###########################################################################
# color code tracked nodes
###########################################################################

my @node_color;

sub CalculateNodeColors {
    my ($i);
    @node_color = ();
    for ($i = 1; $i &lt;= $NN; $i++) {
	$node_color[$i] = $node_color;
    }
    $node_color[$idcolor1_id-&gt;get()] = 'cyan';
    $node_color[$idcolor2_id-&gt;get()] = 'magenta';
    $node_color[$idcolor3_id-&gt;get()] = 'orange';
    $node_color[$idcolor4_id-&gt;get()] = 'pink';
    $node_color[$idscale-&gt;get()] = 'white';
}

sub ResetNodeColor {
    my ($node) = @ARG;
    $CANVAS-&gt;itemconfigure(node_marker_name($node), 
			   -fill =&gt; $node_color[$node]);    
};

sub do_id_colors {

    $CANVAS-&gt;itemconfigure(node_marker_name($idcolor1_id-&gt;get()), 
			   -fill =&gt; 'cyan');    

    $CANVAS-&gt;itemconfigure(node_marker_name($idcolor2_id-&gt;get()), 
			   -fill =&gt; 'magenta');    

    $CANVAS-&gt;itemconfigure(node_marker_name($idcolor3_id-&gt;get()), 
			   -fill =&gt; 'orange');    

    $CANVAS-&gt;itemconfigure(node_marker_name($idcolor4_id-&gt;get()), 
			   -fill =&gt; 'pink');    

    $CANVAS-&gt;itemconfigure(node_marker_name($idscale-&gt;get()), 
			    -fill =&gt; 'white');    

    DoNodeAttributes();
}

sub DoNodeAttributes {
    my $rattr;

    foreach $rattr (@NODE_ATTR) {
	if (exists $$rattr{'after'} &amp;&amp; $$rattr{'after'} &gt; $CUR_TIME) {
	    next;
	}
	my $n = $$rattr{'node'};
	if (exists $$rattr{'text'}) {
	    my ($x, $y) = where_node($n,$CUR_TIME);
	    $CANVAS-&gt;delete("text-n$n");
	    my $item = $CANVAS-&gt;create('text', 
			    scale_dist($x) + $DOT_SIZE + 4, 
			    scale_dist($y),
			    -text =&gt; $$rattr{'text'},
			    -anchor =&gt; 'w',
			    -fill =&gt; 'black', -tag =&gt; "text-n$n");
	    $CANVAS-&gt;addtag('node','withtag',$item);
	    $CANVAS-&gt;addtag(node_name($n),'withtag',$item);
	}
	if (exists $$rattr{'color'}) {
	    $CANVAS-&gt;itemconfigure(node_marker_name($n), 
				   -fill =&gt; $$rattr{'color'}); 
	    $node_color[$n] = $$rattr{'color'};
	}
    }

};

###########################################################################
###########################################################################
# set up the UI given the current global state
###########################################################################
sub ConfigureUI {
    $timepos_scale-&gt;configure(-to =&gt; $MAX_TIME);
    $idscale-&gt;configure(-to =&gt; $NN);

    $CANVAS-&gt;delete('bkgndbitmap');
    if ($bitmap_file =~ /.+\.xbm/) {
	$CANVAS-&gt;create(qw(bitmap 0 0), -anchor =&gt; 'nw',
			-bitmap =&gt; '@'.$bitmap_file,
			-tags=&gt;'bkgndbitmap');
	$SCREENY = $bitmap_ydim;
	$SCREENX = $bitmap_xdim;
	$CANVAS-&gt;lower('bkgndbitmap');
    } elsif ($bitmap_file =~ /.+\.gif/) {
	my $img = 
	    $CANVAS-&gt;Photo( 'IMG', 
			   -file =&gt; $bitmap_file );

	$CANVAS-&gt;create( 'image',0,0, 
			'-anchor' =&gt; 'nw', 
			'-image'  =&gt; $img,
			-tags =&gt; 'bkgndbitmap');
	$SCREENY = $bitmap_ydim;
	$SCREENX = $bitmap_xdim;
	$CANVAS-&gt;lower('bkgndbitmap');
    }

    my $yscale = $SCREENY / $MAXY;
    my $xscale = $SCREENX / $MAXX;
    if ($yscale &lt; $xscale) { $SCALE = $yscale;} else { $SCALE = $xscale;}
    $CANVAS-&gt;configure(-width =&gt; $MAXX * $SCALE,
		       -height =&gt; $MAXY * $SCALE);
    $scale_text-&gt;delete('1.0','end');
    my $buf = sprintf("%dm by %dm",$MAXX, $MAXY);
    $scale_text-&gt;configure(-width =&gt; length($buf));
    $scale_text-&gt;insert('1.0',$buf);

    $comment_text-&gt;delete('1.0','end');
    $comment_text-&gt;insert('1.0',$default_comment);
    $comment_text-&gt;configure('width' =&gt; length($default_comment));

    if ($default_slowdown &gt; 0) {
	$speed_scale-&gt;set($default_slowdown * 10);	
    }

    $CANVAS-&gt;delete('node');
    DisplayPositions($CUR_TIME);
    do_id_colors();    
}


sub dist {
    my ($x1, $y1, $x2, $y2) = @ARG;

    return (sqrt( (($x1 - $x2) * ($x1 - $x2)) + ($y1 - $y2) * ($y1 - $y2)));
}

sub scale_dist {
    my ($dist) = @ARG;
    return $dist * $SCALE;
}

sub unscale_dist {
    my ($pixels) = @ARG;
    return $pixels / $SCALE;
}

sub scale_lon {
    my ($lon) = @ARG;
    return $rad_pitt_lat * ($lon - $NW_CORNER_LON) * $PI / 180.0;
}

sub scale_lat {
    my ($lat) = @ARG;
    return $rad_pitt_lon * -1.0 * ($lat - $NW_CORNER_LAT) * $PI / 180.0;
}

###########################################################################
###########################################################################
# Random ouput functions
###########################################################################
sub print_it {
    $CANVAS-&gt;postscript(-file =&gt; "out.ps",);
}

sub Msg {
    $info_display-&gt;delete('1.0','end');
    $info_display-&gt;insert('1.0', @ARG);
    DoOneEvent(DONT_WAIT | ALL_EVENTS);
}

###########################################################################
sub node_name {
    my ($n) = @ARG;
    return "n$n";
}

sub node_marker_name {
    my ($n) = @ARG;
    return "mark-n$n";
}

sub plot_node {
    my ($n, $x, $y, $color) = @ARG;
    $x = scale_dist($x); $y = scale_dist($y);
    my $item = $CANVAS-&gt;create('oval', $x - $DOT_SIZE, $y - $DOT_SIZE, 
			       $x + $DOT_SIZE, $y + $DOT_SIZE,
			       -outline =&gt; 'black', -fill =&gt; $node_color, 
			       -tag =&gt; node_marker_name($n) );
    $CANVAS-&gt;addtag(node_name($n),'withtag',$item);
    $CANVAS-&gt;addtag('node','withtag',$item);

    if ($show_range_circles) {
	$item = $CANVAS-&gt;create('oval', 
				$x - scale_dist($RANGE),
				$y - scale_dist($RANGE),
				$x + scale_dist($RANGE), 
				$y + scale_dist($RANGE),
				-outline =&gt; $range_circle_color, 
				-tag =&gt; node_name($n));
	$CANVAS-&gt;addtag('node','withtag',$item);
    }
}

sub move_node {
    my ($n, $x, $y) = @_;
    my @coords = $CANVAS-&gt;coords(node_marker_name($n));
    if (@coords == '') {
	plot_node($n,$x,$y);
    } else {
	my ($x1,$y1) = @coords;
	$x = scale_dist($x); $y = scale_dist($y);
	$CANVAS-&gt;move(node_name($n), 
		      $x - $x1 - $DOT_SIZE, $y - $y1 - $DOT_SIZE);
    }
}

###########################################################################
###########################################################################
# Calculations and display code for node positions
###########################################################################
sub where_node {
    my ($node, $time) = @ARG;
    my ($dx, $dy, $dt, $x, $y, $d, $i);

#    printf("looking for $node at $time\n");

    for ($i = $NUM_TIMES[$node] - 1; $i &gt;= 0  ; $i--) {
	if ($MOVE[$node]-&gt;[$i]-&gt;[$TIME] &lt; $time) {last;}
    }

    if ($i == $NUM_TIMES[$node]) {
	printf("DFU: time not found???\n");
	exit -1;
    }

    if ($i &lt;= 0) {
	$i = 0;
	$x = $MOVE[$node]-&gt;[$i]-&gt;[$TOX];
	$y = $MOVE[$node]-&gt;[$i]-&gt;[$TOY];
	return ($x, $y);
    }

    $dx = $MOVE[$node]-&gt;[$i]-&gt;[$TOX] - $MOVE[$node]-&gt;[$i-1]-&gt;[$TOX];
    $dy = $MOVE[$node]-&gt;[$i]-&gt;[$TOY] - $MOVE[$node]-&gt;[$i-1]-&gt;[$TOY];
    $d = sqrt($dx * $dx + $dy * $dy);
    $dt = $time - $MOVE[$node]-&gt;[$i]-&gt;[$TIME] - $MOVE[$node]-&gt;[$i]-&gt;[$PT];

    if ($d == 0 || $dt &lt; 0) {
	$x = $MOVE[$node]-&gt;[$i-1]-&gt;[$TOX];
	$y = $MOVE[$node]-&gt;[$i-1]-&gt;[$TOY];
	return ($x, $y);
    }

    $x =  $MOVE[$node]-&gt;[$i-1]-&gt;[$TOX] + 
	($dt * $MOVE[$node]-&gt;[$i]-&gt;[$SPEED] * $dx / $d);
    $y =  $MOVE[$node]-&gt;[$i-1]-&gt;[$TOY] + 
	($dt * $MOVE[$node]-&gt;[$i]-&gt;[$SPEED] * $dy / $d);

    # fix overshoot
    if (($dx &gt; 0 &amp;&amp; $x &gt; $MOVE[$node]-&gt;[$i]-&gt;[$TOX])
	|| ($dx &lt; 0 &amp;&amp; $x &lt; $MOVE[$node]-&gt;[$i]-&gt;[$TOX])) {
	$x = $MOVE[$node]-&gt;[$i]-&gt;[$TOX];
    }
    if (($dy &gt; 0 &amp;&amp; $y &gt; $MOVE[$node]-&gt;[$i]-&gt;[$TOY])
	|| ($dy &lt; 0 &amp;&amp; $y &lt; $MOVE[$node]-&gt;[$i]-&gt;[$TOY])) {
	$y = $MOVE[$node]-&gt;[$i]-&gt;[$TOY];
    }

    return ($x, $y);
}

sub DisplayPositions {
    my ($time) = @ARG;
    my ($x, $y, $i, $j);

    my @current_position;


    if ($show_cobwebs) {
	$CANVAS-&gt;delete('cobweb');
    }

    for ($i = 1; $i &lt;= $NN ; $i++) {

	($x, $y) = where_node($i, $time);
	move_node($i, $x, $y);

#	printf("t %f n %d x %f y %f\n",$time, $i, $x, $y);

	if ($show_cobwebs) {
	    # draw a line between us and any earlier nodes we're in range of
	    $current_position[$i][0] = $x;
	    $current_position[$i][1] = $y;	    
	    for ($j = 1; $j &lt; $i ; $j++) {
		if (dist($x,$y,
			 $current_position[$j][0],  
			 $current_position[$j][1]) &lt;= $RANGE) {
		    $CANVAS-&gt;create('line',
				    scale_dist($x),scale_dist($y),
				    scale_dist($current_position[$j][0]),  
				    scale_dist($current_position[$j][1]),
				    -fill =&gt; $cobweb_color,
				    -width =&gt; 2,
				    -tag =&gt; 'cobweb',
				    );
		}
	    }
	} # end of if show cobwebs

    }

}

###########################################################################
##########################################################################
# Change program state or position
############################################################################

sub change_time {
    my ($new_time) = @ARG;
    $CUR_TIME = $new_time;
    if ($CUR_TIME &lt; 0) {$CUR_TIME = 0;}
    if ($CUR_TIME &gt; $MAX_TIME) {$CUR_TIME = $MAX_TIME;}
    $reset_time = 1;
    $timepos_scale-&gt;set($CUR_TIME);
    SetNextEventTime($CUR_TIME);
    SetNextOrigination($CUR_TIME);
}

###########################################################################
sub toggle_display {

    if( ! $running) {

	if ($wait_for_macfilter_server) {
	    Msg("Blocking wait for macfilter (kill ad-hockey to abort).");
	    DoOneEvent(DONT_WAIT | ALL_EVENTS);
	    MacfilterServer();
	}

	$start_but-&gt;configure(-text =&gt; "Stop");

	# avoid annoying habit of time reseting to an integer when you
	# stop and restart the sim
	if (int($CUR_TIME) == $timepos_scale-&gt;get()) {
	    change_time($CUR_TIME);
	} else {
	    change_time($timepos_scale-&gt;get());
	}

	$running = 1;
	$CANVAS-&gt;delete('connections');
	UndisplayEventsTill(10 * $MAX_TIME); # a wild hack to clear the events

	# Reset node colors
#	$CANVAS-&gt;itemconfigure('node', -fill =&gt; $node_color);	    
	do_id_colors();
    } else {
	$start_but-&gt;configure(-text =&gt; "Start");
	$running = 0;
    }
}

###########################################################################
##########################################################################
# Display events from simulation trace file
############################################################################

# First hack up a data structure to keep track of remove events.
# It's possible I should make this a real data struct kept in
# sorted order and used in the main loop parallel to the event
# stream from the trace file.  That would allow this to be used
# for general internal events.  If I find another set of internal
# events, I'll generalize this... -dam 7/24/98
# Well, I did find another set of internal events: scheduling pkt
# sends when constructing a scenario, but for now I'll continue the
# hacks -dam 7/25/98
# GACK...  a third class of internal timed events: attributes like
#  node color changing.... I really need to implement a queue of internal
#  event for these things, but I have no time now. -dam 5/21/99

my @event_ends; # references to records for tracking when an undisplay event 
                # should happen
my $num_ends = 0;

my $OBJECT = 0;
my $DATA = 1;
#my $TIME = 2; TIME already defined above !!!!! DON'T CHANGE !!!!
my $TYPE = 3;
my   $PKT_LINE = 1;
my   $NODE_COLOR = 2;

sub AddEndEvent {
    my ($time, $object, $type, $data) = @ARG;

    my $where;
    if ($type != $NODE_COLOR) {
	$where = $num_ends;
	$num_ends++;
    } else {
	my $i;
	for ($i = 0; $i &lt; $num_ends ;  $i++) {
	    if ($event_ends[$i]-&gt;[$OBJECT] == $object 
		&amp;&amp; $event_ends[$i]-&gt;[$TYPE] == $NODE_COLOR) {
		$where = $i;
		goto DONE;
	    }	    
	}
	# if not found
	$where = $num_ends;
	$num_ends++;
    }

  DONE:
    $event_ends[$where] = [$object, $data, $time, $type];
#print "Adds at $where/$num_ends : $object, $data, $time, $type\n";
    return;
}

sub UndisplayEventsTill {
    my ($end_time) = @ARG;

    CalculateNodeColors();
    my ($i);
    for ($i = 0; $i &lt; $num_ends; $i++) {
	if ($event_ends[$i]-&gt;[$TIME] &lt;= $end_time) {

	    if ($event_ends[$i]-&gt;[$TYPE] == $NODE_COLOR) {

		ResetNodeColor($event_ends[$i]-&gt;[$OBJECT]);

	    } elsif ($event_ends[$i]-&gt;[$TYPE] == $PKT_LINE) {

#print "pkt line $event_ends[$i]-&gt;[$DATA] $event_ends[$i]-&gt;[$TIME]\n";
		$CANVAS-&gt;delete($event_ends[$i]-&gt;[$DATA]);
	    }
	    
#print "undisplay $i/$num_ends $event_ends[$i]-&gt;[$OBJECT] type $event_ends[$i]-&gt;[$TYPE] at $event_ends[$i]-&gt;[$TIME]\n";
	    # remove event from queue
	    $event_ends[$i] = $event_ends[$num_ends - 1];
	    $num_ends--;
	    $i--;  
            # yes, I'm frobbing the iteration variable to stutter on this
	    # value of i so that the record we just moved from the end is
	    # checked. Your notions of proper coding style mean nothing to me 
	    # -dam
	}
    }
};

sub DisplayPktEvent {    
    my ($time, $node, $type, $level, $len, $mac_src, $ip_src) = @ARG;
    # note: $mac_src only has meaning for 'r' events (right???)

    if ($show_agt &amp;&amp; $node == $ip_src &amp;&amp; $level eq 'RTR') {
	return;
    }

    if ($show_rtr &amp;&amp; $level eq 'RTR') {

	$CANVAS-&gt;itemconfigure('n'.$node, -fill =&gt; $rtr_colors{$type});

	if ($show_pkt_lines &amp;&amp; $type eq 'r' &amp;&amp; $mac_src != 0) {
	    my ($x1, $y1) = $CANVAS-&gt;coords('n'.$node);
	    my ($x2, $y2) = $CANVAS-&gt;coords('n'.$mac_src);
	    my $tag = $node.'-'.$mac_src;
	    $CANVAS-&gt;create('line', 
			    $x1 + $DOT_SIZE, $y1 + $DOT_SIZE,
			    $x2 + $DOT_SIZE, $y2 + $DOT_SIZE,
			    -fill =&gt; $conn_color, -tag =&gt; $tag);
	    AddEndEvent($time + 5 * ($len * 8)/$LINK_BW, 
			$node, $PKT_LINE, $tag);
	}

    } elsif ($show_agt &amp;&amp; $level eq 'AGT') {

	$CANVAS-&gt;itemconfigure('n'.$node, -fill =&gt; $agt_colors{$type});

    }

    # the end time calc will be slightly wrong, because on sends
    # events the length doesn't include the mac header, but it does
    # on receives
#print "display $node at $time\n";
    AddEndEvent($time + ($len * 8)/$LINK_BW, $node, $NODE_COLOR, 1);
#printf("  -- delay %f\n", ($len * 8)/$LINK_BW);

};

sub DisplayPCTDEvent {
    my $lon = $PCTD_DATA{gps_longitude};
    my $lat = $PCTD_DATA{gps_latitude};
    my $node = $PCTD_DATA{node};
    
    my ($x, $y) = (scale_lon($lon), scale_lat($lat));
    
#    print "t $PCTD_DATA{time} node $node from $lon,$lat to $x,$y\n";
    move_node("n".$node, $x, $y);
};

sub DisplayEventsTill {
    my ($end_time) = @ARG;

    my ($t, $e);
    $t = PeekNextEventTime();
	
    for ($t = PeekNextEventTime(); $t &gt; 0 &amp;&amp; $t &lt; $end_time; 
	 $t = PeekNextEventTime()) {

	($t,$e)= GetNextEvent();
	
	if ($e =~ /^([rsf]).*?_(\d+)_ (\w+) .*? (\w+) (\d+) \[\w+ \w+ \w+ (\w+).*?\[(\w+)/) {
	    # $1 is type
	    # $2 is node
	    # $3 is trace level
	    # $4 is the pkt type
	    # $5 is length
	    # $6 is mac source of pkt (hex)
	    # $7 is ip src of pkt
# print "$t $2 $1 $3 $4\n";

	    # ignore ARP event ($7 is REQUEST or REPLY)
	    # it would actually work to call DisplayPkt, since
	    # the ip_src is just used for coloring
	    if ($4 eq 'ARP') {next;}

	    DisplayPktEvent($t,$2,$1,$3,$5,hex($6),$7);

	} elsif ($e =~ /^C \d+.\d+ (.*)$/) {
	    $comment_text-&gt;delete('1.0','end');
	    $comment_text-&gt;insert('1.0',$1);
	    $comment_text-&gt;configure('width' =&gt; length($1));
	} elsif ($e eq 'pctd-data') {
	    DisplayPCTDEvent();
	} else {
	    print "DFU: unknown event:\n$e\n";
	    die;
	}
    }
};

###########################################################################
###########################################################################
# Main
###########################################################################
###########################################################################

# stolen from bouncing ball simulation demo widget -dam
# This runs the Tk mainloop. Note that the simulation itself has a main
# loop which must be processed. DoSingleStep runs a bit of the simulation
# during every iteration. Also note  that, with a flag of 0,
# Tk::DoOneEvent will suspend the  process until an X-event arrives, 
# effectively blocking the  while loop. 

##########################################################################
### arg processing

my $controls_on_main_window = 1;
my $geometry = '';
my $autostart = 0;

sub usage {
    print "usage: ad-hockey [-slowdown %d | -sl %d] [-geometry ...] \n";
    print "                 [-autostart] [-autorewind]\n";
    print "                 [-comment 'mumble mumble']\n";
    print "                 [-show-range | -sr] [-no-controls | -nc]\n";
    print "                 [&lt;scenario file&gt;] [&lt;trace file&gt;] \n";
    exit;
}

while ($#ARGV &gt;= 0) {
    if ($ARGV[0] eq '-sl' || $ARGV[0] eq '-slowdown') {
	# assume simple slowdown model 
	$default_slowdown = $ARGV[1];
	shift; shift;
    } elsif  ($ARGV[0] eq '-geometry') {
	$geometry = $ARGV[1];
	shift; shift;
    } elsif  ($ARGV[0] eq '-comment') {
	$default_comment = $ARGV[1];
	shift; shift;
    } elsif  ($ARGV[0] eq '-autostart') {
	$autostart = 1;
	shift;
    } elsif  ($ARGV[0] eq '-autorewind') {
	$autorewind = 1;
	shift;
    } elsif  ($ARGV[0] eq '-pctd') {
	$pctd_file = 1;
	shift;
    } elsif ($ARGV[0] eq '-help' || $ARGV[0] eq '-h') {
	usage();
	shift;
    } elsif ($ARGV[0] eq '-no-controls' || $ARGV[0] eq '-nc') {
	$controls_on_main_window = 0;
	shift;
    } elsif ($ARGV[0] eq '-show-range' || $ARGV[0] eq '-sr') {
	$show_range_circles = 1;
	shift;
    } else {
	last;
    }
}

if ($#ARGV &gt; 1){
    usage();
}

if ($#ARGV &gt;= 0) {
    $default_scenario = $ARGV[0];
}

if ($#ARGV &gt;= 1) {
    $default_trace = $ARGV[1];
}

##########################################################################
### build the UI
if ($controls_on_main_window) {
    BuildUIWithOneWindow();
} else {
    BuildUIWithTwoWindows();
}

##########################################################################
##### Create basic mouse and key bindings
$CANVAS-&gt;Tk::bind('&lt;B2-Motion&gt;' =&gt; [sub {msg_loc(@ARG)}]);

$CANVAS-&gt;bind('node', '&lt;Any-Enter&gt;' =&gt; sub{mouse_enter_node;});
$CANVAS-&gt;bind('node', '&lt;Any-Leave&gt;' =&gt; sub{mouse_leave_node;});
$CANVAS-&gt;bind('node', '&lt;Double-1&gt;' =&gt;  sub{show_waypoints;});

$CANVAS-&gt;bind('waypoint', '&lt;B1-Motion&gt;' =&gt; sub{reposition_waypoint(@ARG);});

$MW-&gt;Tk::bind('&lt;Button-3&gt;' =&gt; sub{toggle_display;});

##########################################################################
##### Read in Scenario files provided to the command line
if ($default_trace) {
    if (OpenTraceFile($default_trace) &gt;= 0) {
	$trace_on = 1;
	$show_agt = 1;
	$show_rtr = 1;
	$show_pkt_lines = 1;
    }
}
if ($default_scenario) {
    ReadScenario($default_scenario);
    if ($default_commpattern ne "") {
	ReadCommunicationPattern($default_commpattern);
    }
}

##########################################################################
### setup the time source
open2( \*ReadTime, \*WriteTime, "what-time") or die;
WriteTime-&gt;autoflush();

##########################################################################
### begin running things
ConfigureUI();

if ($geometry ne '') {
    $MW-&gt;wm('geometry', $geometry);
}

if ($autostart &amp;&amp; !$running) {
    toggle_display();
}

# redo the node attributes roughly once per simulation second
# when speeded up, we'll do them each time through the main loop
my $last_attrib_time = 0;	# when did we last check node attributes?

MAIN_LOOP: while(1) {
    my ($line, $next_time, $now, $scheduled_time);

    DoOneEvent($running ? (DONT_WAIT | ALL_EVENTS) : ALL_EVENTS);

    if ($running) {
	# get next line

	$trace_on = $trace_loaded 
	    &amp;&amp; ($show_rtr || $show_agt || $show_pkt_lines);
	if ($trace_on || $show_cobwebs) {
	    $next_time = $CUR_TIME + 1/($TRACED_EVENT_PER_SEC * $time_scale);
	} else {
	    $next_time = $CUR_TIME + 1/($EVENT_PER_SEC * $time_scale);
	}
	
#	printf("next t $next_time\n");
 
	# get current time 
	print WriteTime "\n";
	$now = &lt;ReadTime&gt;;

	if ($reset_time) {
	    $base_real_time = $now;
	    $base_sim_time = $next_time;
	    $reset_time = 0;
	}

	$scheduled_time = ($next_time - $base_sim_time) * $time_scale 
	                  + $base_real_time;
	
#	printf("delay %f time %f\n",$scheduled_time, 
#	       $scheduled_time - $now, $CUR_TIME);  

	if ($scheduled_time &lt;= $now) {

	    DisplayPositions($next_time);		

	    if ($trace_on) {
		UndisplayEventsTill($CUR_TIME);
		DisplayEventsTill($next_time);
	    }
	    if ($show_originations) {
		DisplayOriginations($CUR_TIME, $next_time);
	    }

	    # advance time, since we've done all the events up to next_time
	    $CUR_TIME = $next_time;
	    $timepos_scale-&gt;set($CUR_TIME);
	    
	    if ($slave_to_ns) {
		CheckNSSlave();
	    }
	    if (int($CUR_TIME) != $last_attrib_time) {
		$last_attrib_time = $CUR_TIME;
		DoNodeAttributes();
	    }

            DoOneEvent(DONT_WAIT | ALL_EVENTS);


	    if ($now - $scheduled_time &gt; 1.0) { 
		$b = sprintf("%f   behind %f secs", $CUR_TIME, 
			     $now - $scheduled_time);
		Msg($b);
# changing the background when we get behind is too visually distracting
#		$CANVAS-&gt;configure(-background =&gt; $behind_canvas_bkgnd);
		$speed_scale-&gt;set($speed_scale-&gt;get() + 1);
	    } else {
		Msg("Time: $CUR_TIME");
# changing the background when we get behind is too distracting
#		$CANVAS-&gt;configure(-background =&gt; $normal_canvas_bkgnd);
	    }
	} else {

	    if ($skip &amp;&amp; $trace_on) {
		$CUR_TIME = PeekNextEventTime();
		$skip = 0;
		$reset_time = 1;
	    }

	    # sleep for a bit, calling doonevent periodically if needed

	    # I'm disabling the sleep loop by setting $again to 0
	    # to avoid the annoying problem of the display freezing when
	    # you move the mouse while the nodes are running b/c the stupid
	    # perlTK has to loop through here until all the mouse events
	    # are drained from the queue and the draw events can happen.
	    # -dam 6/17/98

	    my $again = 0;
	  PAUSE_LOOP: while ($again &amp;&amp; ! $skip &amp;&amp; ! $reset_time) {
	      my $t = $scheduled_time - $now;
	      if ($t &gt; 0.05) {
		  $t = 0.05; 
		  $again = 1;
	      } else { $again = 0; }

	      select(undef, undef, undef, $t);
	      if (! $again ) { last PAUSE_LOOP; }

	      DoOneEvent(DONT_WAIT | ALL_EVENTS);
#	      print WriteTime "\n";
#	      $now = &lt;ReadTime&gt;;
	      $now = $now + $t;
	  }
	}

	
    }

    if ($CUR_TIME &gt;= $MAX_TIME ) {
	if ($autorewind) { 
	    toggle_display; 
	    change_time(0);
	    toggle_display; 
	} elsif ($running) { 
	    toggle_display;
	}
    }
}

exit;

###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################
sub MacfilterServer {
    my ($msg_recv_time, $now);
    my $msg;

    ClearAllNoAsk();

    my $paddr = sockaddr_in($MAC_PORT, INADDR_ANY);
    socket(S,PF_INET,SOCK_DGRAM,0) 
	or Msg("Can't get MAC server socket: $!") and return;
    bind(S,$paddr) or die "bind: $!";

    # should make this a spin wait on a select checking to see if
    # user unsets the wait_for_macfilter_server
    recv(S,$msg,$MAC_MSG_LEN,0) or die "recv $!";

    # get current time 
    print WriteTime "\n";
    $msg_recv_time = &lt;ReadTime&gt;;

    my ($scen_name, $wait_time) = unpack($MAC_MSG_FORMAT, $msg);
    
    $default_scenario = $scen_name;
    $default_trace = "";
    $default_commpattern = "";
    ReadScenario($default_scenario);
    change_time(0);
    $speed_scale-&gt;set(10);
    ConfigureUI();

    $msg_recv_time += ($wait_time / 1000.0);

    print WriteTime "\n";
    $now = &lt;ReadTime&gt;;

    if ($now &lt; $msg_recv_time ) {
	select(undef, undef, undef, $msg_recv_time - $now);
    }
};

###########################################################################
###########################################################################
###########################################################################
###########################################################################
###########################################################################

sub add_node {

    # node numbers are 1 based, so we inc first, then setup
    $NN++;

    my $index = $NUM_TIMES[$NN];
    $MOVE[$NN]-&gt;[$index]-&gt;[$TIME] = 0.0;
    $MOVE[$NN]-&gt;[$index]-&gt;[$TOY] = 10.0;
    $MOVE[$NN]-&gt;[$index]-&gt;[$TOX] = 10.0;
    $MOVE[$NN]-&gt;[$index]-&gt;[$SPEED] = 0.0;
    $NUM_TIMES[$NN]++;    

    display_waypoints($NN);
    $idscale-&gt;configure(-to =&gt; $NN);
};

###########################################################################
###########################################################################
###########################################################################
sub edit_entry;
sub build_entries;
sub add_waypoint;
sub ToggleWaypointHighlight;
sub ExtendWaypointHighlight;
sub SaveRange;
sub PasteSavedRange;

sub trace_name {
    my ($n) = @ARG;
    return "trace-$n";
  
}

sub undisplay_waypoints {
    my ($node) = @ARG;

    $CANVAS-&gt;delete(trace_name($node));
    if ($WP[$node]-&gt;{MW} ne "") {
	$WP[$node]-&gt;{MW}-&gt;destroy();
	$WP[$node]-&gt;{MW} = "";
    }
    if ($EDIT[$node]-&gt;{MW} != '') {
	$EDIT[$node]-&gt;{MW}-&gt;destroy();
	$EDIT[$node]-&gt;{MW} = '';
    }
};

sub display_waypoints {
    my ($node) = @ARG;

    $CANVAS-&gt;raise(trace_name($node));

    if ($WP[$node]-&gt;{MW} ne "") {
	Msg("Waypoints already displayed for node $node");
	return;
    }

    $WP[$node]-&gt;{highlight_start} = -1;

    $WP[$node]-&gt;{MW} = MainWindow-&gt;new;
    $WP[$node]-&gt;{MW}-&gt;title("Node $node");

    ## make the waypoint listbox
    $WP[$node]-&gt;{wplistframe} = $WP[$node]-&gt;{MW}-&gt;Frame(
               -borderwidth =&gt; 2,
               -width =&gt; '15c',
               );
    $WP[$node]-&gt;{wplistframe}-&gt;pack(-side =&gt; 'top', -expand =&gt; 'yes', -fill =&gt; 'y');
    $WP[$node]-&gt;{wplistscroll} =  $WP[$node]-&gt;{wplistframe}-&gt;Scrollbar;
    $WP[$node]-&gt;{wplistscroll}-&gt;pack(-side =&gt; 'right', -fill =&gt; 'y');
    $WP[$node]-&gt;{wplist} = $WP[$node]-&gt;{wplistframe}-&gt;Listbox(
        -yscrollcommand =&gt; [$WP[$node]-&gt;{wplistscroll} =&gt; 'set'],
        -setgrid        =&gt; 1,
        -height         =&gt; 15,
        -width          =&gt; 60,
	-selectbackground =&gt; $waypoint_highlight_color,
    );
    $WP[$node]-&gt;{wplistscroll}-&gt;configure(-command =&gt; [$WP[$node]-&gt;{wplist} =&gt; 'yview']);
    $WP[$node]-&gt;{wplist}-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -fill =&gt; 'both');

    ## make the controls
    $WP[$node]-&gt;{cntframe1} = $WP[$node]-&gt;{MW}-&gt;Frame(-borderwidth =&gt; 2,);
    $WP[$node]-&gt;{cntframe1}-&gt;{addwp} =  $WP[$node]-&gt;{cntframe1}-&gt;Button(
			       -text =&gt; "Add Waypoint",
#			       -width =&gt; 10,
			       -command =&gt; sub {add_waypoint($node)},
			       );
    $WP[$node]-&gt;{cntframe1}-&gt;{addwp}-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');

    $WP[$node]-&gt;{cntframe1}-&gt;{edit} =  $WP[$node]-&gt;{cntframe1}-&gt;Button(
			       -text =&gt; "Edit",
#			       -width =&gt; 10,
			       -command =&gt; sub {edit_entry($node)},
			       );
    $WP[$node]-&gt;{cntframe1}-&gt;{edit}-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');

    $WP[$node]-&gt;{cntframe1}-&gt;{edit} =  $WP[$node]-&gt;{cntframe1}-&gt;Button(
			       -text =&gt; "Delete Waypoint",
#			       -width =&gt; 10,
			       -command =&gt; sub {delete_waypoint($node)},
			       );
    $WP[$node]-&gt;{cntframe1}-&gt;{edit}-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');

    $WP[$node]-&gt;{cntframe2} = $WP[$node]-&gt;{MW}-&gt;Frame(-borderwidth =&gt; 2,);
    $WP[$node]-&gt;{cntframe2}-&gt;{saverange} =  $WP[$node]-&gt;{cntframe2}-&gt;Button(
			       -text =&gt; "Save Range",
			       -command =&gt; sub {SaveRange($node);},
			       );
    $WP[$node]-&gt;{cntframe2}-&gt;{saverange}-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');

    $WP[$node]-&gt;{cntframe2}-&gt;{pasterange} =  $WP[$node]-&gt;{cntframe2}-&gt;Button(
			       -text =&gt; "Paste Saved Range",
			       -command =&gt; sub {PasteSavedRange($node);},
			       );
    $WP[$node]-&gt;{cntframe2}-&gt;{pasterange}-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');

    $WP[$node]-&gt;{cntframe2}-&gt;{close} =  $WP[$node]-&gt;{cntframe2}-&gt;Button(
			       -text =&gt; "Close",
#			       -width =&gt; 10,
			       -command =&gt; sub {undisplay_waypoints($node);},
			       );
    $WP[$node]-&gt;{cntframe2}-&gt;{close}-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');

    $WP[$node]-&gt;{cntframe1}-&gt;pack();
    $WP[$node]-&gt;{cntframe2}-&gt;pack();

    $WP[$node]-&gt;{wplist}-&gt;insert(0,build_entries($node));
    display_movetrace($node);

    DoOneEvent(DONT_WAIT | ALL_EVENTS);

    ####
    $WP[$node]-&gt;{wplist}-&gt;bind('&lt;Double-1&gt;' =&gt; sub { edit_entry($node)},);
    $WP[$node]-&gt;{wplist}-&gt;bind('&lt;Button-1&gt;' =&gt; 
			       [sub {ToggleWaypointHighlight(@ARG)},$node],);
    $WP[$node]-&gt;{wplist}-&gt;bind('&lt;B1-Motion&gt;' =&gt; 
			       [sub {ExtendWaypointHighlight(@ARG)},$node],);
    ####

};

sub SaveRange {
    my ($node) = @ARG;
    if (-1 == $WP[$node]-&gt;{highlight_start}) {
	Msg("No range of waypoints highlighted");
	return;
    }
    @SAVED_MOVE = [];
    my ($i, $j);
    for ($i = $WP[$node]-&gt;{highlight_start}, $j = 0; 
	 $i &lt;= $WP[$node]-&gt;{highlight_stop}; $i++, $j++) {
	@SAVED_MOVE[$j] = @MOVE[$node]-&gt;[$i];
    }
    Msg("Waypoints $WP[$node]-&gt;{highlight_start} to $WP[$node]-&gt;{highlight_stop} saved to clipboard");
    ToggleWaypointHighlight(0,$node);
}

sub WaypointCompletionTime {
    my ($node,$wp) = @ARG;
    my ($dx, $dy, $dt, $d);
    
    if (0 == $wp) {return 0;}

    $dx = $MOVE[$node]-&gt;[$wp]-&gt;[$TOX] - $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOX];
    $dy = $MOVE[$node]-&gt;[$wp]-&gt;[$TOY] - $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOY];
    $d = sqrt($dx * $dx + $dy * $dy);
    $dt = $MOVE[$node]-&gt;[$wp]-&gt;[$PT] + $d / $MOVE[$node]-&gt;[$wp]-&gt;[$SPEED];
    return $dt;
}

sub PasteSavedRange {
    my ($node) = @ARG;
    my ($i,$j,$insert_len);
    my ($dx, $dy, $dt, $d);

    if (-1 == $#SAVED_MOVE) {
	Msg("No saved region");
    }

    if (0 == $SAVED_MOVE[0]-&gt;[$SPEED]) {
	Msg("Can't paste in a saved range that includes a starting point");
	return;
    }

    my $wp = $WP[$node]-&gt;{wplist}-&gt;index('active');
    $wp += 1;    #insert after the selected waypoint

    print "wp is $wp\n";

#    print "Saved move\n";
#    dumpValue(\@SAVED_MOVE);
#    print "before paste\n";
#    dumpValue(\@MOVE[$node]);
    
    $insert_len = $#SAVED_MOVE + 1;
    for ($i = $NUM_TIMES[$node] + $insert_len - 1;
	 $i &gt;= $wp + $insert_len;
	 $i--) {
	$MOVE[$node]-&gt;[$i] = @MOVE[$node]-&gt;[$i - $insert_len];
    }
    $NUM_TIMES[$node] += $insert_len;

#    print "after shift\n";
#    dumpValue(\@MOVE[$node]);
	 
    for ($j = 0; $j &lt; $insert_len; $j++) {
	# need to make a copy of the saved_move, since we don't want sharing
	#  I just can't understand Perl's model of references well enough to
	#  do this copy in a reasonable fashion.  perl-- -dam 9/23/98
	my $cur = $wp + $j;
	$MOVE[$node]-&gt;[$cur] = [];
	$MOVE[$node]-&gt;[$cur]-&gt;[$TIME] = $SAVED_MOVE[$j]-&gt;[$TIME];
	$MOVE[$node]-&gt;[$cur]-&gt;[$SPEED] = $SAVED_MOVE[$j]-&gt;[$SPEED];
	$MOVE[$node]-&gt;[$cur]-&gt;[$TOX] = $SAVED_MOVE[$j]-&gt;[$TOX];
	$MOVE[$node]-&gt;[$cur]-&gt;[$TOY] = $SAVED_MOVE[$j]-&gt;[$TOY];
	$MOVE[$node]-&gt;[$cur]-&gt;[$PT] = $SAVED_MOVE[$j]-&gt;[$PT];

	#now fix up the start time of the new current waypoint
	$MOVE[$node]-&gt;[$cur]-&gt;[$TIME] = $MOVE[$node]-&gt;[$cur-1]-&gt;[$TIME] 
	    + WaypointCompletionTime($node,$cur-1);
    }

#    print "after paste\n";
#    dumpValue(\@MOVE[$node]);

    # now adjust the times of all following waypoints
    my $insert_stop_time = $MOVE[$node]-&gt;[$wp + $insert_len - 1]-&gt;[$TIME] + 
	WaypointCompletionTime($node, $wp + $insert_len - 1);
    my $time_delta = $insert_stop_time - $MOVE[$node]-&gt;[$wp + $insert_len]-&gt;[$TIME];
    for ($i = $wp + $insert_len; $i &lt; $NUM_TIMES[$node] ; $i++) {
	$MOVE[$node]-&gt;[$i]-&gt;[$TIME] += $time_delta;
    }

    $CANVAS-&gt;delete(trace_name($node));
    display_movetrace($node);

    $WP[$node]-&gt;{wplist}-&gt;delete(0,'end');
    $WP[$node]-&gt;{wplist}-&gt;insert(0,build_entries($node));
}

###########################################################################
###########################################################################
sub finish_edit {
    my ($node,$wp) = @ARG;

    if (abs($EDIT[$node]-&gt;{ox} != 0 + $EDIT[$node]-&gt;{x}-&gt;get()) &gt; $EP 
	|| abs($EDIT[$node]-&gt;{oy} != 0 + $EDIT[$node]-&gt;{y}-&gt;get()) &gt; $EP) {
	update_waypoint_position($node,$wp, $EDIT[$node]-&gt;{x}-&gt;get(),
				 $EDIT[$node]-&gt;{y}-&gt;get());
    }
    
    if ($wp != 0
	&amp;&amp; abs($EDIT[$node]-&gt;{otime} != 0 + $EDIT[$node]-&gt;{time}-&gt;get()) &gt; $EP) {
	update_waypoint_time($node, $wp, $EDIT[$node]-&gt;{time}-&gt;get());
    }
    
    if ($wp != 0
	&amp;&amp; abs($EDIT[$node]-&gt;{opt} != 0 + $EDIT[$node]-&gt;{pt}-&gt;get()) &gt; $EP) {
	update_waypoint_pt($node, $wp, $EDIT[$node]-&gt;{pt}-&gt;get());
    }

    if ($wp != 0
	&amp;&amp; abs($EDIT[$node]-&gt;{ospeed} - $EDIT[$node]-&gt;{speed}-&gt;get()) &gt; $EP) {
	update_waypoint_speed($node, $wp, $EDIT[$node]-&gt;{speed}-&gt;get());
    }

    $WP[$node]-&gt;{wplist}-&gt;delete(0,'end');
    $WP[$node]-&gt;{wplist}-&gt;insert(0,build_entries($node));

    $EDIT[$node]-&gt;{MW}-&gt;destroy();
    $EDIT[$node]-&gt;{MW} = '';
};

sub edit_entry {
    my ($node) = @ARG;

    my $wp = $WP[$node]-&gt;{wplist}-&gt;index('active');
#    print $WP[$node]-&gt;{wplist}-&gt;get('active');
#    print " index $wp\n";

    if ($EDIT[$node]-&gt;{MW} != '') {
	Msg("First close existing waypoint edit window for node $node!");
	return;
    }
     
    $EDIT[$node]-&gt;{ox} = $MOVE[$node]-&gt;[$wp]-&gt;[$TOX];
    $EDIT[$node]-&gt;{oy} = $MOVE[$node]-&gt;[$wp]-&gt;[$TOY];
    $EDIT[$node]-&gt;{otime} = $MOVE[$node]-&gt;[$wp]-&gt;[$TIME];
    $EDIT[$node]-&gt;{ospeed} = $MOVE[$node]-&gt;[$wp]-&gt;[$SPEED];
    $EDIT[$node]-&gt;{opt} = $MOVE[$node]-&gt;[$wp]-&gt;[$PT];

#    print "time is  $EDIT[$node]-&gt;{otime} old is \n";

    $EDIT[$node]-&gt;{MW} = MainWindow-&gt;new;
    $EDIT[$node]-&gt;{MW}-&gt;title("Node $node - Waypoint $wp");
    
        ## make the controls
    $EDIT[$node]-&gt;{close} =  $EDIT[$node]-&gt;{MW}-&gt;Button(
			       -text =&gt; "Okay",
			       -command =&gt; sub {finish_edit($node,$wp);},
			       );
    $EDIT[$node]-&gt;{close}-&gt;pack(-side =&gt; 'bottom', 
				-expand =&gt; 'yes');
    $EDIT[$node]-&gt;{cntframe1} = $EDIT[$node]-&gt;{MW}-&gt;Frame(-borderwidth =&gt; 2,);
    $EDIT[$node]-&gt;{cntframe1}-&gt;pack(-side =&gt;'top');
    $EDIT[$node]-&gt;{cntframe2} = $EDIT[$node]-&gt;{MW}-&gt;Frame(-borderwidth =&gt; 2,);
    $EDIT[$node]-&gt;{cntframe2}-&gt;pack(-side =&gt;'top');

    $EDIT[$node]-&gt;{cntframe1}-&gt;Label(-text =&gt; 'Time: ',
				    -font =&gt; $FONT,)-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{time} = $EDIT[$node]-&gt;{cntframe1}-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 16,
       );
    $EDIT[$node]-&gt;{time}-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{time}-&gt;insert(0, sprintf("%f",$EDIT[$node]-&gt;{otime}));

    $EDIT[$node]-&gt;{cntframe1}-&gt;Label(-text =&gt; 'Pause: ',
				    -font =&gt; $FONT,)-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{pt} = $EDIT[$node]-&gt;{cntframe1}-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 16,
       );
    $EDIT[$node]-&gt;{pt}-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{pt}-&gt;insert(0, sprintf("%f",$EDIT[$node]-&gt;{opt}));

    $EDIT[$node]-&gt;{cntframe2}-&gt;Label(-text =&gt; 'X: ',
				    -font =&gt; $FONT,)-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{x} = $EDIT[$node]-&gt;{cntframe2}-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 16,
       );
    $EDIT[$node]-&gt;{x}-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{x}-&gt;insert(0, $EDIT[$node]-&gt;{ox});

    $EDIT[$node]-&gt;{cntframe2}-&gt;Label(-text =&gt; 'Y: ',
				    -font =&gt; $FONT,)-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{y} = $EDIT[$node]-&gt;{cntframe2}-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 16,
       );
    $EDIT[$node]-&gt;{y}-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{y}-&gt;insert(0, $EDIT[$node]-&gt;{oy});

    $EDIT[$node]-&gt;{cntframe2}-&gt;Label(-text =&gt; 'Speed: ',
				    -font =&gt; $FONT,)-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{speed} = $EDIT[$node]-&gt;{cntframe2}-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 16,
       );
    $EDIT[$node]-&gt;{speed}-&gt;pack(-side =&gt;'left');
    $EDIT[$node]-&gt;{speed}-&gt;insert(0, sprintf("%f",$EDIT[$node]-&gt;{ospeed}));

    if ($wp == 0) {
	# fix up some stuff for stupid users
	$EDIT[$node]-&gt;{speed}-&gt;delete(0,'end');
	$EDIT[$node]-&gt;{time}-&gt;delete(0,'end');
	$EDIT[$node]-&gt;{pt}-&gt;delete(0,'end');
	$EDIT[$node]-&gt;{speed}-&gt;insert(0, 'n/a');
	$EDIT[$node]-&gt;{time}-&gt;insert(0, 'start');
	$EDIT[$node]-&gt;{pt}-&gt;insert(0, 'n/a');
    }
};

sub build_entries {
    my ($node) = @ARG;
    my ($i,$l);
    my @out = ();

# looks like
#  3:   80.676 - pause    0.0 =&gt;  570.9,  85.2    8.3m/s

    $l = sprintf("%2d:  start ----&gt;               %6.1f,%6.1f",
		 $i,
		 $MOVE[$node]-&gt;[$i]-&gt;[$TOX],
		 $MOVE[$node]-&gt;[$i]-&gt;[$TOY]);
    $out[0] = $l;

    for ($i = 1; $i &lt; $NUM_TIMES[$node]; $i++) {
	$l = sprintf("%2d: %8.3f - pause %6.1f =&gt; %6.1f,%6.1f  %5.2fm/s",
		     $i,
		     $MOVE[$node]-&gt;[$i]-&gt;[$TIME],
		     $MOVE[$node]-&gt;[$i]-&gt;[$PT],
		     $MOVE[$node]-&gt;[$i]-&gt;[$TOX],
		     $MOVE[$node]-&gt;[$i]-&gt;[$TOY],
		     $MOVE[$node]-&gt;[$i]-&gt;[$SPEED]);
	$out[$i] = $l;
    }
    return @out;
};

sub ToggleWaypointHighlight {
   my ($w,$node) = @ARG;

   if (-1 != $WP[$node]-&gt;{highlight_start}) {
       $WP[$node]-&gt;{highlight_start} = -1;
       $WP[$node]-&gt;{highlight_stop} = -1;
       $WP[$node]-&gt;{wplist}-&gt;selection('clear',0,'end');
       $CANVAS-&gt;itemconfigure(trace_name($node), -fill =&gt; $waypoint_color, );
   } else {
       my $e = $w-&gt;XEvent;
       my($x, $y) = ($e-&gt;x, $e-&gt;y);
       my $wp = $WP[$node]-&gt;{wplist}-&gt;nearest($y);

       $WP[$node]-&gt;{highlight_start} = $wp;
       $WP[$node]-&gt;{highlight_stop} = $wp;
       $WP[$node]-&gt;{wplist}-&gt;selection('clear',0,'end');
       $WP[$node]-&gt;{wplist}-&gt;selection('set', $WP[$node]-&gt;{highlight_start},
				       $WP[$node]-&gt;{highlight_stop});
       $CANVAS-&gt;itemconfigure("w$node-$wp", -fill =&gt; $waypoint_highlight_color, );
   }
}

sub ExtendWaypointHighlight {
   my ($w,$node) = @ARG;

   if (-1 == $WP[$node]-&gt;{highlight_start}) {
       return;
   }
   
   my $e = $w-&gt;XEvent;
   my($x, $y) = ($e-&gt;x, $e-&gt;y);

   my $wp = $WP[$node]-&gt;{wplist}-&gt;nearest($y);

   if ($wp &lt; $WP[$node]-&gt;{highlight_start}) {
       $WP[$node]-&gt;{highlight_start} = $wp;
   } else {
       $WP[$node]-&gt;{highlight_stop} = $wp;
   }
   
   $WP[$node]-&gt;{wplist}-&gt;selection('clear',0,'end');
   $WP[$node]-&gt;{wplist}-&gt;selection('set', $WP[$node]-&gt;{highlight_start},
				   $WP[$node]-&gt;{highlight_stop});

   $CANVAS-&gt;itemconfigure(trace_name($node), -fill =&gt; $waypoint_color, );
   my $i;
   for ($i = $WP[$node]-&gt;{highlight_start}; $i &lt;= $WP[$node]-&gt;{highlight_stop}; $i++) {
       $CANVAS-&gt;itemconfigure("w$node-$i", -fill =&gt; $waypoint_highlight_color, );
   }
}

sub add_waypoint {
    my ($node) = @ARG;
    
    my $new = $NUM_TIMES[$node];
    $MOVE[$node]-&gt;[$new]-&gt;[$TOX] = $MOVE[$node]-&gt;[$new-1]-&gt;[$TOX] 
	+ 2 * unscale_dist($DOT_SIZE);
    $MOVE[$node]-&gt;[$new]-&gt;[$TOY] = $MOVE[$node]-&gt;[$new-1]-&gt;[$TOY]
	+ 2 * unscale_dist($DOT_SIZE);
    if ($new &gt; 1) {
	$MOVE[$node]-&gt;[$new]-&gt;[$SPEED] = $MOVE[$node]-&gt;[$new-1]-&gt;[$SPEED];
    } else {
	$MOVE[$node]-&gt;[$new]-&gt;[$SPEED] = 1.0;
    }
    $MOVE[$node]-&gt;[$new]-&gt;[$PT] = 0.0;

    if ($new == 1) {
	$MOVE[$node]-&gt;[$new]-&gt;[$TIME] = 0.0;
    } else {
	my ($dx, $dy, $dt, $x, $y, $d, $i);
	$dx = $MOVE[$node]-&gt;[$new-1]-&gt;[$TOX] - $MOVE[$node]-&gt;[$new-2]-&gt;[$TOX];
	$dy = $MOVE[$node]-&gt;[$new-1]-&gt;[$TOY] - $MOVE[$node]-&gt;[$new-2]-&gt;[$TOY];
	$d = sqrt($dx * $dx + $dy * $dy);
	$dt = $MOVE[$node]-&gt;[$new-1]-&gt;[$PT] +
	    $d / $MOVE[$node]-&gt;[$new-1]-&gt;[$SPEED];
	
	$MOVE[$node]-&gt;[$new]-&gt;[$TIME] = $dt + $MOVE[$node]-&gt;[$new-1]-&gt;[$TIME];
    }
    $NUM_TIMES[$node]++;

    $CANVAS-&gt;delete(trace_name($node));
    display_movetrace($node);

    $WP[$node]-&gt;{wplist}-&gt;delete(0,'end');
    $WP[$node]-&gt;{wplist}-&gt;insert(0,build_entries($node));
};

sub delete_waypoint {
    my ($node) = @ARG;
    my ($j);

    my $wp = $WP[$node]-&gt;{wplist}-&gt;index('active');
#    print $WP[$node]-&gt;{wplist}-&gt;get('active');
#    print " delete index $wp\n";

    if (0 == $wp) {
	Msg("Can't delete start waypoint!");
	return;
    } elsif ($wp == $NUM_TIMES[$node] - 1) {
	$NUM_TIMES[$node]--;	
    } else {	

	$MOVE[$node]-&gt;[$wp+1]-&gt;[$PT] += $MOVE[$node]-&gt;[$wp+1]-&gt;[$TIME] -
	    $MOVE[$node]-&gt;[$wp]-&gt;[$TIME];
	$MOVE[$node]-&gt;[$wp+1]-&gt;[$TIME] = $MOVE[$node]-&gt;[$wp]-&gt;[$TIME];

#	dumpValue(\$MOVE[$node]);
	for ($j = $wp; $j &lt; $NUM_TIMES[$node]; $j++) {
	    $MOVE[$node]-&gt;[$j]-&gt;[$TIME] = $MOVE[$node]-&gt;[$j+1]-&gt;[$TIME];
	    $MOVE[$node]-&gt;[$j]-&gt;[$SPEED] = $MOVE[$node]-&gt;[$j+1]-&gt;[$SPEED];
	    $MOVE[$node]-&gt;[$j]-&gt;[$TOX] = $MOVE[$node]-&gt;[$j+1]-&gt;[$TOX];
	    $MOVE[$node]-&gt;[$j]-&gt;[$TOY] = $MOVE[$node]-&gt;[$j+1]-&gt;[$TOY];
	    $MOVE[$node]-&gt;[$j]-&gt;[$PT] = $MOVE[$node]-&gt;[$j+1]-&gt;[$PT];
	}
#	dumpValue(\$MOVE[$node]);

	$NUM_TIMES[$node]--;	
	update_waypoint_position($node,$wp,$MOVE[$node]-&gt;[$wp]-&gt;[$TOX],
				 $MOVE[$node]-&gt;[$wp]-&gt;[$TOY]);
    }


    $CANVAS-&gt;delete(trace_name($node));
    display_movetrace($node);

    $WP[$node]-&gt;{wplist}-&gt;delete(0,'end');
    $WP[$node]-&gt;{wplist}-&gt;insert(0,build_entries($node));
    
}


#change the position of the waypoint, and change the speeds coming 
# in and going out of the waypoint (so as to leave the times on adj 
# waypoints constant)
sub update_waypoint_position {
    my ($node,$wp,$newx,$newy) = @ARG;
    
    $MOVE[$node]-&gt;[$wp]-&gt;[$TOX] = $newx;
    $MOVE[$node]-&gt;[$wp]-&gt;[$TOY] = $newy;
    
    ## now adj the speeds
    my ($dx, $dy, $dt, $d);

    if ($wp != 0 &amp;&amp; $wp != $NUM_TIMES[$node] - 1) {
	$dx = $MOVE[$node]-&gt;[$wp]-&gt;[$TOX] - $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOX];
	$dy = $MOVE[$node]-&gt;[$wp]-&gt;[$TOY] - $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOY];
	$d = sqrt($dx * $dx + $dy * $dy);
	$dt = $MOVE[$node]-&gt;[$wp+1]-&gt;[$TIME] - $MOVE[$node]-&gt;[$wp]-&gt;[$PT]
	    - $MOVE[$node]-&gt;[$wp]-&gt;[$TIME];
	$MOVE[$node]-&gt;[$wp]-&gt;[$SPEED] = $d / $dt;	
    }

    # the speed of the last leg is unconstrained, since there's no
    # set time by which the node must reach the end of the leg
    if ($wp &lt; $NUM_TIMES[$node] - 2) {
	$dx = $MOVE[$node]-&gt;[$wp+1]-&gt;[$TOX] - $MOVE[$node]-&gt;[$wp]-&gt;[$TOX];
	$dy = $MOVE[$node]-&gt;[$wp+1]-&gt;[$TOY] - $MOVE[$node]-&gt;[$wp]-&gt;[$TOY];
	$d = sqrt($dx * $dx + $dy * $dy);
	$dt = $MOVE[$node]-&gt;[$wp+2]-&gt;[$TIME] - $MOVE[$node]-&gt;[$wp+1]-&gt;[$PT]
	    - $MOVE[$node]-&gt;[$wp+1]-&gt;[$TIME];
	$MOVE[$node]-&gt;[$wp+1]-&gt;[$SPEED] = $d / $dt;	
    }

    $WP[$node]-&gt;{wplist}-&gt;delete(0,'end');
    $WP[$node]-&gt;{wplist}-&gt;insert(0,build_entries($node));
};

#change the time of the waypoint, and apply the same delta to all 
# following waypoints
sub update_waypoint_time {
    my ($node,$wp,$newtime) = @ARG;


    if ($wp &lt;= 1) {
	Msg("Can't change the start time of waypoints 0 or 1");
	return;
    }

    my $oldtime = $MOVE[$node]-&gt;[$wp]-&gt;[$TIME];
    $MOVE[$node]-&gt;[$wp]-&gt;[$TIME] = $newtime;

    if ($newtime &gt; $oldtime) {
	# take up the slack by increasing the pause time
	$MOVE[$node]-&gt;[$wp-1]-&gt;[$PT] = $newtime - $oldtime;
    } else {
	# fix up the speed of the previous leg so we arrive at $wp at the new
	# time
	my ($dx, $dy, $dt, $d);
	$dx = $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOX] - $MOVE[$node]-&gt;[$wp-2]-&gt;[$TOX];
	$dy = $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOY] - $MOVE[$node]-&gt;[$wp-2]-&gt;[$TOY];
	$d = sqrt($dx * $dx + $dy * $dy);
	$dt = $MOVE[$node]-&gt;[$wp]-&gt;[$TIME] - $MOVE[$node]-&gt;[$wp-1]-&gt;[$PT]
	    - $MOVE[$node]-&gt;[$wp-1]-&gt;[$TIME];
	$MOVE[$node]-&gt;[$wp-1]-&gt;[$SPEED] = $d / $dt;	
    }

    my $i;
    for ($i = $wp + 1; $i &lt; $NUM_TIMES[$node] ; $i++) {
	$MOVE[$node]-&gt;[$i]-&gt;[$TIME] += ($newtime - $oldtime);
    }

    $WP[$node]-&gt;{wplist}-&gt;delete(0,'end');
    $WP[$node]-&gt;{wplist}-&gt;insert(0,build_entries($node));
};


#change the pause time of the waypoint, and adjust the speed of the link
# to arrive at the next waypoint on schedule.
sub update_waypoint_pt {
    my ($node,$wp,$newpt) = @ARG;

    if ($wp == 0) { return; }  # the start pos has no pause time

    my $oldpt = $MOVE[$node]-&gt;[$wp]-&gt;[$PT];
    $MOVE[$node]-&gt;[$wp]-&gt;[$PT] = $newpt;

    if ($wp == $NUM_TIMES[$node] - 1) { return; } # no deadlines for last wp
    if ($newpt + $MOVE[$node]-&gt;[$wp]-&gt;[$TIME] 
	&gt;= $MOVE[$node]-&gt;[$wp+1]-&gt;[$TIME]) {
	Msg("Illegal pause time change: couldn't meet start time for next waypoint");
	$MOVE[$node]-&gt;[$wp]-&gt;[$PT] = $oldpt;
	return;
    }

    my ($dx, $dy, $dt, $d);
    $dx = $MOVE[$node]-&gt;[$wp]-&gt;[$TOX] - $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOX];
    $dy = $MOVE[$node]-&gt;[$wp]-&gt;[$TOY] - $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOY];
    $d = sqrt($dx * $dx + $dy * $dy);
    $dt = $MOVE[$node]-&gt;[$wp+1]-&gt;[$TIME] - $MOVE[$node]-&gt;[$wp]-&gt;[$PT]
	- $MOVE[$node]-&gt;[$wp]-&gt;[$TIME];
    $MOVE[$node]-&gt;[$wp]-&gt;[$SPEED] = $d / $dt;	
    
    $WP[$node]-&gt;{wplist}-&gt;delete(0,'end');
    $WP[$node]-&gt;{wplist}-&gt;insert(0,build_entries($node));
};


#change the speed of the waypoint, and update the next waypoint with the
# new arrival time
sub update_waypoint_speed {
    my ($node,$wp,$newspeed) = @ARG;

    my $oldspeed = $MOVE[$node]-&gt;[$wp]-&gt;[$SPEED];
    $MOVE[$node]-&gt;[$wp]-&gt;[$SPEED] = $newspeed;

    if ($wp == 0) { return; }  # the start pos has no speed
    if ($wp == $NUM_TIMES[$node] - 1) { return; } # no deadlines for last wp

    my ($dx, $dy, $dt, $d, $change, $i);
    $dx = $MOVE[$node]-&gt;[$wp]-&gt;[$TOX] - $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOX];
    $dy = $MOVE[$node]-&gt;[$wp]-&gt;[$TOY] - $MOVE[$node]-&gt;[$wp-1]-&gt;[$TOY];
    $d = sqrt($dx * $dx + $dy * $dy);
    $dt = $d / $MOVE[$node]-&gt;[$wp]-&gt;[$SPEED] + $MOVE[$node]-&gt;[$wp]-&gt;[$PT];

    update_waypoint_time($node, $wp + 1, $dt + $MOVE[$node]-&gt;[$wp]-&gt;[$TIME]);
    
    $WP[$node]-&gt;{wplist}-&gt;delete(0,'end');
    $WP[$node]-&gt;{wplist}-&gt;insert(0,build_entries($node));
};

###########################################################################
###########################################################################
sub display_movetrace {
    my ($node) = @ARG;
    
    my ($i);
    for ($i = 0; $i &lt; $NUM_TIMES[$node]; $i++) {
	plot_waypoint($node,$i,$MOVE[$node]-&gt;[$i]-&gt;[$TOX],
		      $MOVE[$node]-&gt;[$i]-&gt;[$TOY]);
	if ($i &lt; $NUM_TIMES[$node] - 1) {
	    my $item = $CANVAS-&gt;create('line', 
				       scale_dist($MOVE[$node]-&gt;[$i]-&gt;[$TOX]),
				       scale_dist($MOVE[$node]-&gt;[$i]-&gt;[$TOY]),
				       scale_dist($MOVE[$node]-&gt;[$i+1]-&gt;[$TOX]),
				       scale_dist($MOVE[$node]-&gt;[$i+1]-&gt;[$TOY]),
				       -arrowshape =&gt; [8,14,4],
				       -arrow =&gt; 'last',
				       -width =&gt; 2,
				       -fill =&gt; $waypoint_color, 
				       -tag =&gt; "t$node-$i" );
	    $CANVAS-&gt;addtag(trace_name($node),'withtag',$item);
	}
    }
    
    if ($WP_DOT_SIZE &gt; $DOT_SIZE) {
	$CANVAS-&gt;raise(node_name($node));
    }
};

sub plot_waypoint {
    my ($n, $i, $x, $y) = @ARG;
    $x = scale_dist($x); $y = scale_dist($y);
    my $item = $CANVAS-&gt;create('oval', $x-$WP_DOT_SIZE, $y-$WP_DOT_SIZE, 
			    $x+$WP_DOT_SIZE, $y+$WP_DOT_SIZE,
		  -outline =&gt; $waypoint_color, 
		  -fill =&gt; $waypoint_color, -tag =&gt; "w$n-$i" );
    $CANVAS-&gt;addtag('waypoint','withtag',$item);
    $CANVAS-&gt;addtag(trace_name($n),'withtag',$item);
}

###########################################################################
###########################################################################

sub move_waypoint {
    my ($n, $i, $x, $y) = @ARG;
    my ($j, @coords);

    $x = scale_dist($x); $y = scale_dist($y);
    @coords = $CANVAS-&gt;coords("w$n-$i");
    if (@coords == '') {
	die;   # I don't think this code path should ever be used -dam 6/98
	plot_waypoint($n,$i,$x,$y);
    } else {
	my ($x1,$y1) = @coords;
	$CANVAS-&gt;move("w$n-$i", 
		      $x - $x1 - $WP_DOT_SIZE, 
		      $y - $y1 - $WP_DOT_SIZE);
	
	### Now move the trace lines
	if ($i != 0) {
	    $j = $i - 1;
	    @coords = $CANVAS-&gt;coords("t$n-$j");
	    if (@coords != '') {
		$CANVAS-&gt;coords("t$n-$j", $coords[0], $coords[1], $x, $y);
	    } else {
		print "not found t$n-$j\n";
		die;
	    }
	}
	if ($i != $NUM_TIMES[$n] - 1) {
	    @coords = $CANVAS-&gt;coords("t$n-$i");
	    if (@coords != '') {
		$CANVAS-&gt;coords("t$n-$i", $x, $y, $coords[2], $coords[3]);
	    } else {
		print "not found t$n-$i\n";
		die;
	    }
	}
    }

    if ($WP_DOT_SIZE &gt; $DOT_SIZE) {
	$CANVAS-&gt;raise(node_name($n));
    }
}

sub reposition_waypoint {
    my($w) = @ARG;

    my $e = $w-&gt;XEvent;
    my ($screen_x, $screen_y) = ($e-&gt;x, $e-&gt;y);
    my ($x, $y) = (unscale_dist($screen_x), unscale_dist($screen_y));

    if ($x &gt; $MAXX) { $x = $MAXX;}
    if ($x &lt; 0) { $x = 0;}
    if ($y &gt; $MAXY) { $y = $MAXY;}
    if ($y &lt; 0) { $y = 0;}

    my @tags = $CANVAS-&gt;gettags('current');
    if (join(' ',@tags) =~ /\bw(\d+)-(\d+)\b/o) {
	move_waypoint($1,$2,$x,$y);
	update_waypoint_position($1,$2,$x,$y);
    }
};

###########################################################################
###########################################################################
# Trace file manipulations
###########################################################################
my %next_fileevent = (time =&gt; -1.0, event =&gt; "");
my $TRACEFILE = '';
my $maxtrpos = 0;

sub ReadAddrMap {
    my ($fname) = @ARG;

    open(F,$fname) or die "Can't open address map file '$fname'";
    while (&lt;F&gt;) {
        if (/[^\#]*(\d+)\s+([\w\.]+)\s+([0-9a-fA-F\.:]+)/) {
            $ADDRMAP{$2} = $1;
        } 
    }

#    print "read addrmap\n";
#    dumpValue(\%ADDRMAP);

    close F;
}

sub SetTRPos {
# set the trace file pointer to the next line following the given location
    my ($new_pos) = @ARG;
    seek(TRACEFILE,$new_pos,0);
    # sync to line break
    my $c;

    for ($c = getc(TRACEFILE); 
	 !eof(TRACEFILE) &amp;&amp; $c ne "\n"; 
	 $c = getc(TRACEFILE)) {}
    $next_fileevent{time} = -1;  # ignore the old next_event
}

sub PeekNextEventTime {
# return the time of the next event, &lt; 0 if at EOF
    if ($next_fileevent{time} != -1.0) { return $next_fileevent{time};}

    $next_fileevent{event} = &lt;TRACEFILE&gt;;

    my @fields;
    if ($pctd_file) {
	@fields = split " ",$next_fileevent{event};
#	print "event len $#fields\n fields are ";
#	print join "|",@fields;
#	print "\n";
    }

    if ($next_fileevent{event} =~ /^[sf] (\d+\.\d+)/) {
	$next_fileevent{time} = $1;

    } elsif ($next_fileevent{event} =~ /^r (\d+\.\d+).*?(\d+) \[/) {
	# a recv event is posted to the trace when the event completes, but
	# we'd like to know about it
	$next_fileevent{time} = $1 - ($2 * 8)/$LINK_BW;

    } elsif ($next_fileevent{event} =~ /^\w+ (\d+\.\d+)/) {
	$next_fileevent{time} = $1;

    } elsif ($pctd_file &amp;&amp; $#fields == $#pctd_header ) {
	SetPCTDData(@fields);
	$next_fileevent{time} = $PCTD_DATA{time};
	$next_fileevent{event} = 'pctd-data';

    } elsif (eof TRACEFILE) {
	# $next_fileevent{event} is already false
	$next_fileevent{time} = -1;

    } else {
	print "DFU: unknown trace file line:\n$next_fileevent{event}\n";
	die;
    }
    return $next_fileevent{time};
};

sub GetNextEvent {
# return the next event and its time as (time, event)
# rtns time as -1 and event as false in case of EOF
    if ($next_fileevent{time} == -1.0) { 
	PeekNextEventTime();
    }
    my ($time,$event) = ($next_fileevent{time},$next_fileevent{event});
    $next_fileevent{time} = -1;
    return ($time,$event);
};

sub OpenTraceFile {
    ($TRACEFILE) = @ARG;
    if ($trace_loaded) { CloseTraceFile(); }
    if ($TRACEFILE eq "") {
	return -1;
    }
    if (!open(TRACEFILE, "&lt;$TRACEFILE")) {
	Msg("Can't open trace file $TRACEFILE");
	return -1;
    }

    if ($pctd_file) {
	my $line = &lt;TRACEFILE&gt;;
	@pctd_header = split(" ",$line);
	print "Read PCTD header size $#pctd_header : $line\n";
	ReadAddrMap($addrmap_file);
    }

    $next_fileevent{time} = -1.0;
    seek(TRACEFILE, 0, 2) or die;  #find EOF
    $maxtrpos = tell TRACEFILE;
    seek(TRACEFILE, 0, 0) or die;  #back to start
    $trace_loaded = 1;
    return 0;
};

sub CloseTraceFile {
    close TRACEFILE;
    $trace_loaded = 0;
}

sub SetNextEventTime {
    # do binary search in file
    my ($new_time) = @ARG;

    my $done = 0;
    my $time; 
    my $old_time = -1;

    my ($min,$mid,$max) = (0, int ($maxtrpos / 2), $maxtrpos);
    while (!$done) {
	SetTRPos($mid);
	$time = PeekNextEventTime();

# print "$min $mid $max $time |$next_fileevent{event}|\n";

	if (abs($time - $new_time) &lt; $EP) {
	    $done = 1;
	} elsif (!$next_fileevent{event}) {
	    # EOF condition
	    $done = 1;
	} elsif (abs($min - $max) &lt;= 1) {
	    $done = 1;
	} elsif ($time == $old_time) {
	    # encourage faster convergence.
	    # pos is in characters, but we only care about lines.
	    # If we get the same line twice, we're done.
	    # Note that this is not exactly correct, but is close enuf
	    # for the visualizer since off by one line won't matter and
	    # otherwise the search bounces a bunch between the last two lines
	    $done = 1;
	} elsif ($time &lt; $new_time) {
	    $min = $mid;
	} else {
	    $max = $mid;
	}
	$mid = int (($max - $min) / 2) + $min;
	$old_time = $time;
    }

    $next_fileevent{time} = -1;
};

sub SetPCTDData {
    if ($#ARG != $#pctd_header) {
	die "$#ARG != $#pctd_header when setting PCTD data\n";
    }

    %PCTD_DATA = ();

    my $field_name;
    foreach $field_name (@pctd_header) {
	$PCTD_DATA{$field_name} = shift @ARG;
    }

    if ($BASE_TIME &lt; 0.0) {
	$BASE_TIME = $PCTD_DATA{'gps_time.tv_sec'} + 
	    ($PCTD_DATA{'gps_time.tv_usec'} / 1000000);
    }

    $PCTD_DATA{time} = $PCTD_DATA{'gps_time.tv_sec'} + 
	($PCTD_DATA{'gps_time.tv_usec'} / 1000000) - $BASE_TIME;
    
    $PCTD_DATA{node} = $ADDRMAP{$PCTD_DATA{gps_homeaddr}};

#    print "===========================================================================\n";
#    dumpValue(\%PCTD_DATA);
#    print "===========================================================================\n";

};

###########################################################################
###########################################################################
# Configuration Dialog
###########################################################################
sub Configuration {

    my $W = MainWindow-&gt;new;
    $W-&gt;title("Scenario Configuration");

    my $f = $W-&gt;Frame(-width =&gt; '15c');

    my $l1 = $f-&gt;Frame();
    $l1-&gt;pack(-side =&gt; 'top');
    my $xdim = $l1-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 16,);
    $l1-&gt;Label(-text =&gt; 'X dimension (meters):')-&gt;pack(-side =&gt; 'left');
    $xdim-&gt;pack(-side =&gt; 'left');
    $xdim-&gt;insert(0,$MAXX);

    my $ydim = $l1-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 16,);
    $l1-&gt;Label(-text =&gt; 'Y dimension (meters):')-&gt;pack(-side =&gt; 'left');
    $ydim-&gt;pack(-side =&gt; 'left');
    $ydim-&gt;insert(0,$MAXY);

    my $l2 = $f-&gt;Frame();
    $l2-&gt;pack(-side =&gt; 'top', -anchor =&gt; 'w');
    $l2-&gt;Label(-text =&gt; 'Max Time (secs):')-&gt;pack(-side =&gt; 'left');
    my $maxtime = $l2-&gt;Entry(-relief =&gt; 'sunken',);
    $maxtime-&gt;pack(-side =&gt; 'left', -fill =&gt; 'x', -expand =&gt; 1);
    $maxtime-&gt;insert(0,$MAX_TIME);
    
    my $l3 = $f-&gt;Frame();
    $l3-&gt;pack(-side =&gt; 'top', -anchor =&gt; 'w');
    $l3-&gt;Label(-text =&gt; 'Nominal Range (meters):')-&gt;pack(-side =&gt; 'left');
    my $range = $l3-&gt;Entry(-relief =&gt; 'sunken',);
    $range-&gt;pack(-side =&gt; 'left');
    $range-&gt;insert(0,"$RANGE");

    $l3-&gt;Label(-text =&gt; 'Link Bandwidth (bps):')-&gt;pack(-side =&gt; 'left');
    my $bw = $l3-&gt;Label(-relief =&gt; 'sunken',-text =&gt;$LINK_BW);
    $bw-&gt;pack(-side =&gt; 'left');

    my $l5 = $f-&gt;Frame();
    $l5-&gt;pack(-side =&gt; 'top');
    my $bmname = $l5-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 26,);
    $l5-&gt;Label(-text =&gt; 'Bitmap filename:')-&gt;pack(-side =&gt; 'left');
    $bmname-&gt;pack(-side =&gt; 'left');
    $bmname-&gt;insert(0,$bitmap_file);

    my $bmx = $l5-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 4,);
    $l5-&gt;Label(-text =&gt; 'X dim (pixels):')-&gt;pack(-side =&gt; 'left');
    $bmx-&gt;pack(-side =&gt; 'left');
    $bmx-&gt;insert(0,$bitmap_xdim);

    my $bmy = $l5-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 4,);
    $l5-&gt;Label(-text =&gt; 'Y dim (pixels):')-&gt;pack(-side =&gt; 'left');
    $bmy-&gt;pack(-side =&gt; 'left');
    $bmy-&gt;insert(0,$bitmap_ydim);


    my $done = sub {
	$MAXX = 0 + $xdim-&gt;get();
	$MAXY = 0 + $ydim-&gt;get();
	$MAX_TIME = 0.0 + $maxtime-&gt;get();
	$RANGE = 0.0 + $range-&gt;get();
	$bitmap_file = $bmname-&gt;get();
	$bitmap_xdim = $bmx-&gt;get();
	$bitmap_ydim = $bmy-&gt;get();
	ConfigureUI();

	$W-&gt;destroy();
    };

    my $l4 = $f-&gt;Frame();
    $l4-&gt;pack(-side =&gt; 'top', -pady =&gt; 5);

    $l4-&gt;Button(-text =&gt; "Okay", -command =&gt; $done,
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -padx =&gt; 3);
    $l4-&gt;Button(-text =&gt; "Cancel", -command =&gt; sub { $W-&gt;destroy(); },
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -padx =&gt; 3);

    $f-&gt;pack(-side =&gt; 'top');
    
};

###########################################################################
###########################################################################
# File Dialog
###########################################################################
sub FileMenu {

    my $W = MainWindow-&gt;new;
    $W-&gt;title("Save/Load Files");

    my $f = $W-&gt;Frame(-width =&gt; '15c');

    my $l1 = $f-&gt;Frame();
    $l1-&gt;pack(-side =&gt; 'top');
    $l1-&gt;Label(-text =&gt; 'Scenario File:')-&gt;pack(-side =&gt; 'left');
    my $scenario = $l1-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 40,);
    $scenario-&gt;pack(-side =&gt; 'left');
    $scenario-&gt;insert(0, $default_scenario);

    my $l2 = $f-&gt;Frame();
    $l2-&gt;pack(-side =&gt; 'top', -anchor =&gt; 'w');
    $l2-&gt;Label(-text =&gt; 'Trace File:')-&gt;pack(-side =&gt; 'left');
    my $trace = $l2-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 40);
    $trace-&gt;pack(-side =&gt; 'left', -fill =&gt; 'x', -expand =&gt; 1);
    $trace-&gt;insert(0,$default_trace);

    my $l3 = $f-&gt;Frame();
    $l3-&gt;pack(-side =&gt; 'top', -anchor =&gt; 'w');
    $l3-&gt;Label(-text =&gt; 'Communication File:')-&gt;pack(-side =&gt; 'left');
    my $comm = $l3-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 40);
    $comm-&gt;pack(-side =&gt; 'left', -fill =&gt; 'x', -expand =&gt; 1);
    $comm-&gt;insert(0,$default_commpattern);
    
    my $load = sub {
	$default_scenario = $scenario-&gt;get();
	$default_trace = $trace-&gt;get();
	$default_commpattern = $comm-&gt;get();
	if (!ClearAll()) {
	    return;
	}
	Msg('Load Completed');
	ReadScenario($default_scenario);
	ConfigureUI();
	OpenTraceFile($default_trace);
	ReadCommunicationPattern($default_commpattern);

	$W-&gt;destroy();
    };

    my $save = sub {
	$default_scenario = $scenario-&gt;get();
	$default_trace = $trace-&gt;get();
	$default_commpattern = $comm-&gt;get();
	Msg('Save Completed');
	SaveScenario($default_scenario);
	ConfigureUI();
	SaveCommunicationPattern($default_commpattern);
	$W-&gt;destroy();
    };

    my $l4 = $f-&gt;Frame();
    $l4-&gt;pack(-side =&gt; 'top', -pady =&gt; 5);

    $l4-&gt;Button(-text =&gt; "Load", -command =&gt; $load,
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -padx =&gt; 3);
    $l4-&gt;Button(-text =&gt; "Cancel", -command =&gt; sub { $W-&gt;destroy(); },
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -padx =&gt; 3);
    $l4-&gt;Button(-text =&gt; "Save", -command =&gt; $save,
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -padx =&gt; 3);

    $f-&gt;pack(-side =&gt; 'top');
    
};

###########################################################################
###########################################################################
# SchedulePackets
###########################################################################
my @ORIG;
my $num_orig;
my $next_orig;
my $OrigWin;       # window for originations
my $OrigList;      # list box of originations


sub FindOrigIndex {
    my ($time) = @ARG;
    my ($i);
    for ($i = 0; $i &lt; $num_orig; $i++) {
	last if ($ORIG[$i]-&gt;{time} &gt;= $time);
    }
    return $i;
};

sub InsertOrig {
    my ($time,$type,$from,$to,$count,$rate,$size) = @ARG;
    
    my $insert_point = FindOrigIndex($time);
    my ($i);
    for ($i = $num_orig; $i &gt; $insert_point; $i--) {
	$ORIG[$i] = $ORIG[$i - 1];
    }

    $ORIG[$insert_point] = {time =&gt; $time,
			    type =&gt; $type,
			    from =&gt; $from,
			    to =&gt; $to,
			    count =&gt; $count,
			    rate =&gt; $rate,
			    size =&gt; $size,};

    $num_orig++;
};

sub DeleteOrig {
    my ($index) = @ARG;

    if ($num_orig &lt;= 0) { $num_orig = 0; return; }

    my $i;
    for ($i = $index; $i &lt; $num_orig - 1; $i++) {
	$ORIG[$i] = $ORIG[$i+1];
    }
    $num_orig--;
};

sub FormatOrig {
    my ($index) = @ARG;
    return "" if ($index &gt;= $num_orig);
    
    if ($ORIG[$index]-&gt;{type} eq 'cbr') {
	return sprintf("%8.3f %s %d -&gt; %d send %d pkts at %f/sec (MSS %d)",
		       $ORIG[$index]-&gt;{time},
		       $ORIG[$index]-&gt;{type},
		       $ORIG[$index]-&gt;{from},
		       $ORIG[$index]-&gt;{to},
		       $ORIG[$index]-&gt;{count},
		       $ORIG[$index]-&gt;{rate},
		       $ORIG[$index]-&gt;{size});
    } elsif ($ORIG[$index]-&gt;{type} eq 'tcp') {
	return sprintf("%8.3f %s %d -&gt; %d send %d bytes (MSS %d)",
		       $ORIG[$index]-&gt;{time},
		       $ORIG[$index]-&gt;{type},
		       $ORIG[$index]-&gt;{from},
		       $ORIG[$index]-&gt;{to},
		       $ORIG[$index]-&gt;{count},
		       $ORIG[$index]-&gt;{size});
    } else {
	return "DFU: $index unknown type $ORIG[$index]-&gt;{type}";
    }
};

sub ReadCommunicationPattern {
    my ($CP) = @ARG;

    if ($CP eq "") {
	return 0;
    }

    if (!open(CP,"&lt;$CP")) {
	Msg("Can't read communication pattern file $CP\n");
	return -1;
    }
    
    while (&lt;CP&gt;) {

	if (/^\# (\d+.\d+) (\d+) -&gt; (\d+) cbr (\d+) (\d+\.*\d+) (\d+)/) {

## 10.123 1 -&gt; 2 cbr 10 8.0 512

	    InsertOrig($1, 'cbr', $2, $3, $4, $5, $6);
	} elsif (/^\# (\d+.\d+) (\d+) -&gt; (\d+) tcp (\d+) (\d+)/) {

## 10.123 1 -&gt; 2 tcp 1000 512 

	    InsertOrig($1, 'tcp', $2, $3, $4, 0, $5);

	} else {
	}
    }
    close CP;
    return 0;
};

sub SaveCommunicationPattern {
    my ($CP) = @ARG;

    if ($CP eq "" ){
	return 0;
    }
    if (!open(CP,"&gt;$CP")) {
	Msg("Can't write communication pattern file $CP\n");
	return -1;
    }
    
    my $i;
    for ($i = 0; $i &lt; $num_orig; $i++) {
	if ($ORIG[$i]-&gt;{type} eq 'cbr') {

	    my $buf = sprintf("%f %d -&gt; %d cbr %d %f %d",
			      $ORIG[$i]-&gt;{time},
			      $ORIG[$i]-&gt;{from},
			      $ORIG[$i]-&gt;{to},
			      $ORIG[$i]-&gt;{count},
			      $ORIG[$i]-&gt;{rate},
			      $ORIG[$i]-&gt;{size});
	    my $rate = 1/$ORIG[$i]-&gt;{rate};
	    print CP &lt;&lt;"CBR"
#
# $buf
#
set cbr_($i) [\$ns_ create-connection  CBR \$node_($ORIG[$i]-&gt;{from}) \\
	      CBR \$node_($ORIG[$i]-&gt;{to}) 0]
\$cbr_($i) set packetSize_ $ORIG[$i]-&gt;{size}
\$cbr_($i) set interval_ $rate
\$cbr_($i) set random_ 0
\$cbr_($i) set maxpkts_ $ORIG[$i]-&gt;{count}
\$ns_ at $ORIG[$i]-&gt;{time} "\$cbr_($i) start"
CBR
	} elsif  ($ORIG[$i]-&gt;{type} eq 'tcp') {
	    
	    my $buf = sprintf("%f %d -&gt; %d tcp %d %d",
			      $ORIG[$i]-&gt;{time},
			      $ORIG[$i]-&gt;{from},
			      $ORIG[$i]-&gt;{to},
			      $ORIG[$i]-&gt;{count},
			      $ORIG[$i]-&gt;{size});
	    my $maxpkt = int($ORIG[$i]-&gt;{count}/ $ORIG[$i]-&gt;{size});
	    print CP &lt;&lt;"TCP"
#
# $buf
#
set tcp_($i) [\$ns_ create-connection \\
	      TCP/Reno \$node_($ORIG[$i]-&gt;{from}) TCPSink/DelAck \\
	      \$node_($ORIG[$i]-&gt;{to}) 0]
\$tcp_($i) set packetSize_ $ORIG[$i]-&gt;{size}
set ftp_($i) [\$tcp_($i) attach-source FTP]
\$ftp_($i) set  maxpkts_ $maxpkt
\$ns_ at $ORIG[$i]-&gt;{time} "\$ftp_($i) start"
TCP
	} else {
	    print "DFU: unknown origination type\n"; die;
	}
    }

    close CP;
};

sub SetNextOrigination {
    if ($OrigWin != '') {
	my ($time) = @ARG;
	$next_orig = FindOrigIndex($time);
	$OrigList-&gt;selection('clear',0,'end');
    };
};

sub GetNextOrigination {
    #rtns reference to next origination or -1 if not possible
    if ($next_orig &lt; $num_orig) {
	my $t = $next_orig;
	$next_orig++;
	return $ORIG[$t];
    } else {
	return -1;
    }
};

sub PeekNextOriginationTime {
    if ($next_orig &lt; $num_orig) {
	return $ORIG[$next_orig]-&gt;{time};
    } else {
	return -1;
    }
};

sub DisplayOriginations {
    my ($start_time, $end_time) = @ARG;

    if ($OrigList == '') { 
	$show_originations = 0; 
	return; 
    } 
    my $from = FindOrigIndex($start_time);
    my $to = FindOrigIndex($end_time);
    $OrigList-&gt;selection('clear',0,'end');
    $OrigList-&gt;selection('set',$from,$to);
    $OrigList-&gt;yview($from);
};

sub ShowOrig {
    my ($list) = @ARG;

    $list-&gt;delete(0,'end');
    my $i;
    for ($i = 0; $i &lt; $num_orig; $i++) {
	$list-&gt;insert($i,FormatOrig($i));
    }
};

sub ScheduleOriginations {
    
    if ($OrigWin != '') {
	Msg('Close existing originations window first!');
	return -1;
    };
    $OrigWin = MainWindow-&gt;new;
    $OrigWin-&gt;title("Communication Pattern");

    ## make the connections
    my $listframe = $OrigWin-&gt;Frame(
			      -borderwidth =&gt; 2,
			      -width =&gt; '15c',
			      );
    $listframe-&gt;pack(-side =&gt; 'top', -expand =&gt; 'yes', -fill =&gt; 'y');
    my $scroll =  $listframe-&gt;Scrollbar;
    $scroll-&gt;pack(-side =&gt; 'right', -fill =&gt; 'y');
    $OrigList = $listframe-&gt;Listbox(
        -yscrollcommand =&gt; [$scroll =&gt; 'set'],
        -setgrid        =&gt; 1,
        -height         =&gt; 20,
        -width          =&gt; 60,
	-selectbackground =&gt; 'yellow',
    );
    $scroll-&gt;configure(-command =&gt; [$OrigList =&gt; 'yview']);
    $OrigList-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -fill =&gt; 'both');

    ## make the controls
    my $cntframe = $OrigWin-&gt;Frame(-borderwidth =&gt; 2,);
    $cntframe-&gt;pack(-side =&gt; 'bottom', -expand =&gt; 'yes');
    $cntframe-&gt;Button(-text =&gt; "Add TCP Src",
	       -command =&gt; [\&amp;AddTCPSrc, $OrigList]
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');
    $cntframe-&gt;Button(-text =&gt; "Add CBR Src",
	       -command =&gt; [\&amp;AddCBRSrc, $OrigList]
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');
    $cntframe-&gt;Button(-text =&gt; "Delete Src",
	       -command =&gt; [\&amp;DeleteSrc, $OrigList],
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');
    $cntframe-&gt;Button(-text =&gt; "Close",
	       -command =&gt; sub { $OrigWin-&gt;destroy; $OrigList = ''; 
				 $OrigWin = ''; },
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');

    ShowOrig($OrigList);
};

sub DeleteSrc {
    my ($list) = @ARG;
    DeleteOrig($list-&gt;index('active'));
    ShowOrig($list);
};

sub AddCBRSrc {
    my ($list) = @ARG;

    my $W = MainWindow-&gt;new;
    $W-&gt;title('Add CBR Source');

    my $cancel = sub {
	Msg("Canceled...");
	$W-&gt;destroy;
    };

    my $text = $W-&gt;Text(-font =&gt; $FONT, -width =&gt; 40, -height =&gt; 1,
			-relief =&gt; 'sunken')-&gt;pack(-side =&gt;'top');

    $text-&gt;delete('1.0','end');
    $text-&gt;insert('1.0','Left click on source node now');

    my $l1 = $W-&gt;Frame();
    $l1-&gt;pack(-side =&gt; 'top');
    my $n1 = $l1-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 4,);
    $l1-&gt;Label(-text =&gt; 'From node:')-&gt;pack(-side =&gt; 'left');
    $n1-&gt;pack(-side =&gt; 'left');
    my $from_node = GetNode();
    if ($from_node &lt; 0) {&amp;$cancel(); return;}
    $n1-&gt;insert(0,$from_node); 

    $text-&gt;delete('1.0','end');
    $text-&gt;insert('1.0','Left click on destination node now');

    my $n2 = $l1-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 4,);
    $l1-&gt;Label(-text =&gt; 'To node:')-&gt;pack(-side =&gt; 'left');
    $n2-&gt;pack(-side =&gt; 'left');
    my $to_node = GetNode();
    if ($to_node &lt; 0) {&amp;$cancel(); return;}
    $n2-&gt;insert(0,$to_node); 

    $text-&gt;delete('1.0','end');
    $text-&gt;insert('1.0','Set parameters and hit okay or cancel');

    my $l2 = $W-&gt;Frame();
    $l2-&gt;pack(-side =&gt; 'top');
    $l2-&gt;Label(-text =&gt; 'Number pkts:')-&gt;pack(-side =&gt; 'left');
    my $count = $l2-&gt;Entry(-relief =&gt; 'sunken',);
    $count-&gt;pack(-side =&gt; 'left', -fill =&gt; 'x', -expand =&gt; 1);
    $count-&gt;insert(0,10);
    
    my $l3 = $W-&gt;Frame();
    $l3-&gt;pack(-side =&gt; 'top');
    $l3-&gt;Label(-text =&gt; 'Pkts per sec:')-&gt;pack(-side =&gt; 'left');
    my $rate = $l3-&gt;Entry(-relief =&gt; 'sunken',);
    $rate-&gt;pack(-side =&gt; 'left', -fill =&gt; 'x', -expand =&gt; 1);
    $rate-&gt;insert(0,10);

    my $l4 = $W-&gt;Frame();
    $l4-&gt;pack(-side =&gt; 'top');
    $l4-&gt;Label(-text =&gt; 'Pkt size (bytes):')-&gt;pack(-side =&gt; 'left');
    my $size = $l4-&gt;Entry(-relief =&gt; 'sunken',);
    $size-&gt;pack(-side =&gt; 'left', -fill =&gt; 'x', -expand =&gt; 1);
    $size-&gt;insert(0,512);

    my $done = sub {
	my $t;

	if (int($CUR_TIME) == $timepos_scale-&gt;get()) {
	    $t = $CUR_TIME;
	} else {
	    $t = $timepos_scale-&gt;get();
	}

	InsertOrig($t, 'cbr',
		   int($n1-&gt;get()),
		   int($n2-&gt;get()),
		   int($count-&gt;get()),
		   int($rate-&gt;get()),
		   int($size-&gt;get()));
	ShowOrig($list);	
	$W-&gt;destroy();
    };

    my $l5 = $W-&gt;Frame();
    $l5-&gt;pack(-side =&gt; 'top', -pady =&gt; 5);

    $l5-&gt;Button(-text =&gt; "Okay", -command =&gt; $done,
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -padx =&gt; 3);
    $l5-&gt;Button(-text =&gt; "Cancel", 
		-command =&gt; $cancel,
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -padx =&gt; 3);
};


sub AddTCPSrc {
    my ($list) = @ARG;

    my $W = MainWindow-&gt;new;
    $W-&gt;title('Add TCP Source');

    my $cancel = sub {
	Msg("Canceled...");
	$W-&gt;destroy;
    };

    my $text = $W-&gt;Text(-font =&gt; $FONT, -width =&gt; 40, -height =&gt; 1,
			-relief =&gt; 'sunken')-&gt;pack(-side =&gt;'top');

    $text-&gt;delete('1.0','end');
    $text-&gt;insert('1.0','Left click on source node now');

    my $l1 = $W-&gt;Frame();
    $l1-&gt;pack(-side =&gt; 'top');
    my $n1 = $l1-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 4,);
    $l1-&gt;Label(-text =&gt; 'From node:')-&gt;pack(-side =&gt; 'left');
    $n1-&gt;pack(-side =&gt; 'left');
    my $from_node = GetNode();
    if ($from_node &lt; 0) {&amp;$cancel(); return;}
    $n1-&gt;insert(0,$from_node); 

    $text-&gt;delete('1.0','end');
    $text-&gt;insert('1.0','Left click on destination node now');

    my $n2 = $l1-&gt;Entry(-relief =&gt; 'sunken', -width =&gt; 4,);
    $l1-&gt;Label(-text =&gt; 'To node:')-&gt;pack(-side =&gt; 'left');
    $n2-&gt;pack(-side =&gt; 'left');
    my $to_node = GetNode();
    if ($to_node &lt; 0) {&amp;$cancel(); return;}
    $n2-&gt;insert(0,$to_node); 

    $text-&gt;delete('1.0','end');
    $text-&gt;insert('1.0','Set parameters and hit okay or cancel');

    my $l2 = $W-&gt;Frame();
    $l2-&gt;pack(-side =&gt; 'top');
    $l2-&gt;Label(-text =&gt; 'Number bytes:')-&gt;pack(-side =&gt; 'left');
    my $count = $l2-&gt;Entry(-relief =&gt; 'sunken',);
    $count-&gt;pack(-side =&gt; 'left', -fill =&gt; 'x', -expand =&gt; 1);
    $count-&gt;insert(0,1024);
    
    my $l4 = $W-&gt;Frame();
    $l4-&gt;pack(-side =&gt; 'top');
    $l4-&gt;Label(-text =&gt; 'Pkt size (bytes):')-&gt;pack(-side =&gt; 'left');
    my $size = $l4-&gt;Entry(-relief =&gt; 'sunken',);
    $size-&gt;pack(-side =&gt; 'left', -fill =&gt; 'x', -expand =&gt; 1);
    $size-&gt;insert(0,512);

    my $done = sub {
	my $t;

	if (int($CUR_TIME) == $timepos_scale-&gt;get()) {
	    $t = $CUR_TIME;
	} else {
	    $t = $timepos_scale-&gt;get();
	}

	InsertOrig($t, 'tcp',
		   int($n1-&gt;get()),
		   int($n2-&gt;get()),
		   int($count-&gt;get()),
		   0,
		   int($size-&gt;get()));
	ShowOrig($list);	
	$W-&gt;destroy();
    };

    my $l5 = $W-&gt;Frame();
    $l5-&gt;pack(-side =&gt; 'top', -pady =&gt; 5);

    $l5-&gt;Button(-text =&gt; "Okay", -command =&gt; $done,
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -padx =&gt; 3);
    $l5-&gt;Button(-text =&gt; "Cancel", 
		-command =&gt; $cancel,
	       )-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes', -padx =&gt; 3);
};
###########################################################################
###########################################################################
# Manipulate Obstacles
###########################################################################
my @OBST;          # array of references to obstacles
my $num_obst = 0;
my $obst_uid = 0;

sub AddBox {
    my %pinfo;
    my $done = 0;

    my $save_point = sub {
	my ($w, $pinfo) = @ARG;
	my $e = $w-&gt;XEvent;
	my ($x, $y) = ($e-&gt;x, $e-&gt;y);
	$pinfo-&gt;{x1} = $x;
	$pinfo-&gt;{y1} = $y;
	$pinfo-&gt;{x2} = $x;
	$pinfo-&gt;{y2} = $y;
	$CANVAS-&gt;create('rect', $pinfo-&gt;{x1}, $pinfo-&gt;{y1},
			$pinfo-&gt;{x2}, $pinfo-&gt;{y2},
			-outline =&gt; $obst_color, -width =&gt; $obst_width,
			-tag =&gt; 'cur_rect');
	Msg('Hold and drag out box');
    };

    my $drag_box = sub {
	my ($w, $pinfo) = @ARG;
	my $e = $w-&gt;XEvent;
	my ($x, $y) = ($e-&gt;x, $e-&gt;y);
	$pinfo-&gt;{x2} = $x;
	$pinfo-&gt;{y2} = $y;
	$CANVAS-&gt;coords('cur_rect', $pinfo-&gt;{x1}, $pinfo-&gt;{y1},
			$pinfo-&gt;{x2}, $pinfo-&gt;{y2});
	Msg(sprintf("from %6.1f,%6.1f to %6.1f,%6.1f (%6.1fx%6.1f)",
		    unscale_dist($pinfo-&gt;{x1}),
		    unscale_dist($pinfo-&gt;{y1}),
		    unscale_dist($pinfo-&gt;{x2}),
		    unscale_dist($pinfo-&gt;{y2}),
		    unscale_dist(abs($pinfo-&gt;{x1} - $pinfo-&gt;{x2})),
		    unscale_dist(abs($pinfo-&gt;{y1} - $pinfo-&gt;{y2}))));
    };

    Msg('Left click start point');
    $CANVAS-&gt;Tk::bind('&lt;Button-1&gt;' =&gt; [sub{&amp;$save_point(@ARG)},\%pinfo] );
    $CANVAS-&gt;Tk::bind('&lt;B1-Motion&gt;' =&gt; [sub{&amp;$drag_box(@ARG)}, \%pinfo] );
    $CANVAS-&gt;Tk::bind('&lt;ButtonRelease-1&gt;' =&gt; sub {$done = 1;} );
    while (!$done) {
	DoOneEvent(DONT_WAIT | ALL_EVENTS);
    }
    $CANVAS-&gt;Tk::bind('&lt;Button-1&gt;' =&gt; sub{;} );
    $CANVAS-&gt;Tk::bind('&lt;B1-Motion&gt;' =&gt; sub {;} );
    $CANVAS-&gt;Tk::bind('&lt;ButtonRelease-1&gt;' =&gt; sub {;} );

    $OBST[$num_obst]-&gt;{type} = 'box';
    $OBST[$num_obst]-&gt;{uid} = $obst_uid++;;
    $OBST[$num_obst]-&gt;{permeability} = $default_permeability;
    $OBST[$num_obst]-&gt;{points} = {
	x1 =&gt; unscale_dist($pinfo{x1}), y1 =&gt; unscale_dist($pinfo{y1}),
	x2 =&gt; unscale_dist($pinfo{x2}), y2 =&gt; unscale_dist($pinfo{y2}),};

    $CANVAS-&gt;addtag('obst','withtag','cur_rect');
    $CANVAS-&gt;addtag('obst'.$OBST[$num_obst]-&gt;{uid},'withtag','cur_rect');
    $CANVAS-&gt;dtag('cur_rect');

    Msg(sprintf("Added %6.1fx%6.1f box (%6.1f,%6.1f -&gt; %6.1f,%6.1f) perm %.2f)",
		unscale_dist(abs($pinfo{x1} - $pinfo{x2})),
		unscale_dist(abs($pinfo{y1} - $pinfo{y2})),
		unscale_dist($pinfo{x1}),
		unscale_dist($pinfo{y1}),
		unscale_dist($pinfo{x2}),
		unscale_dist($pinfo{y2}),
		$OBST[$num_obst]-&gt;{permeability}));

    $num_obst++;
};

sub AddLine {
    my %pinfo;
    my $done = 0;

    my $save_point = sub {
	my ($w, $pinfo) = @ARG;
	my $e = $w-&gt;XEvent;
	my ($x, $y) = ($e-&gt;x, $e-&gt;y);
	$pinfo-&gt;{x1} = $x;
	$pinfo-&gt;{y1} = $y;
	$pinfo-&gt;{x2} = $x;
	$pinfo-&gt;{y2} = $y;
	$CANVAS-&gt;create('line', $pinfo-&gt;{x1}, $pinfo-&gt;{y1},
			$pinfo-&gt;{x2}, $pinfo-&gt;{y2},
			-fill =&gt; $obst_color, -width =&gt; $obst_width,
			-tag =&gt; 'cur_line');
	Msg('Hold and drag out line');
    };

    my $drag_line = sub {
	my ($w, $pinfo) = @ARG;
	my $e = $w-&gt;XEvent;
	my ($x, $y) = ($e-&gt;x, $e-&gt;y);
	$pinfo-&gt;{x2} = $x;
	$pinfo-&gt;{y2} = $y;
	$CANVAS-&gt;coords('cur_line', $pinfo-&gt;{x1}, $pinfo-&gt;{y1},
			$pinfo-&gt;{x2}, $pinfo-&gt;{y2});
	my $dist = sqrt(($pinfo-&gt;{x1} - $pinfo-&gt;{x2}) 
			* ($pinfo-&gt;{x1} - $pinfo-&gt;{x2})
			+ ($pinfo-&gt;{y1} - $pinfo-&gt;{y2}) 
			* ($pinfo-&gt;{y1} - $pinfo-&gt;{y2}));
	Msg(sprintf("from %6.1f,%6.1f to %6.1f,%6.1f (len = %6.1f)",
		    unscale_dist($pinfo-&gt;{x1}),
		    unscale_dist($pinfo-&gt;{y1}),
		    unscale_dist($pinfo-&gt;{x2}),
		    unscale_dist($pinfo-&gt;{y2}),
		    unscale_dist($dist)));
    };

    Msg('Left click start point');
    $CANVAS-&gt;Tk::bind('&lt;Button-1&gt;' =&gt; [sub{&amp;$save_point(@ARG)},\%pinfo] );
    $CANVAS-&gt;Tk::bind('&lt;B1-Motion&gt;' =&gt; [sub{&amp;$drag_line(@ARG)}, \%pinfo] );
    $CANVAS-&gt;Tk::bind('&lt;ButtonRelease-1&gt;' =&gt; sub {$done = 1;} );
    while (!$done) {
	DoOneEvent(DONT_WAIT | ALL_EVENTS);
    }
    $CANVAS-&gt;Tk::bind('&lt;Button-1&gt;' =&gt; sub{;} );
    $CANVAS-&gt;Tk::bind('&lt;B1-Motion&gt;' =&gt; sub {;} );
    $CANVAS-&gt;Tk::bind('&lt;ButtonRelease-1&gt;' =&gt; sub {;} );

    $OBST[$num_obst]-&gt;{type} = 'line';
    $OBST[$num_obst]-&gt;{uid} = $obst_uid++;;
    $OBST[$num_obst]-&gt;{permeability} = $default_permeability;
        $OBST[$num_obst]-&gt;{points} = {
	x1 =&gt; unscale_dist($pinfo{x1}), y1 =&gt; unscale_dist($pinfo{y1}),
	x2 =&gt; unscale_dist($pinfo{x2}), y2 =&gt; unscale_dist($pinfo{y2}),};

    $CANVAS-&gt;addtag('obst','withtag','cur_line');
    $CANVAS-&gt;addtag('obst'.$OBST[$num_obst]-&gt;{uid},'withtag','cur_line');
    $CANVAS-&gt;dtag('cur_line');

    Msg(sprintf("Added line (%6.1f,%6.1f -&gt; %6.1f,%6.1f) perm %.2f)",
		unscale_dist($pinfo{x1}),
		unscale_dist($pinfo{y1}),
		unscale_dist($pinfo{x2}),
		unscale_dist($pinfo{y2}),
		$OBST[$num_obst]-&gt;{permeability}));		  

    $num_obst++;
};

sub DrawObstacles {
    my ($i, $item);
    for ($i = 0; $i &lt; $num_obst; $i++) {
	if ($OBST[$i]{type} eq 'line') {
	    $item = $CANVAS-&gt;create('line', 
				    scale_dist($OBST[$i]{points}{x1}),
				    scale_dist($OBST[$i]{points}{y1}),
				    scale_dist($OBST[$i]{points}{x2}),
				    scale_dist($OBST[$i]{points}{y2}),
			    -fill =&gt; $obst_color, -width =&gt; $obst_width,
			    -tag =&gt; 'obst'.$OBST[$i]{uid});
	    $CANVAS-&gt;addtag('obst','withtag',$item);
	} elsif ($OBST[$i]{type} eq 'box') {
	    $item = $CANVAS-&gt;create('rect', 
				    scale_dist($OBST[$i]{points}{x1}),
				    scale_dist($OBST[$i]{points}{y1}),
				    scale_dist($OBST[$i]{points}{x2}),
				    scale_dist($OBST[$i]{points}{y2}),
			    -outline =&gt; $obst_color, -width =&gt; $obst_width,
			    -tag =&gt; 'obst'.$OBST[$i]{uid});
	    $CANVAS-&gt;addtag('obst','withtag',$item);
	} else {
	    Msg("unknown obstacle type '$OBST[$i]{type}");
	}
    }
};

sub DeleteObstByUID {
    my ($uid) = @ARG;

    if ($num_obst &lt;= 0) { $num_obst = 0; return; }

    my $i;
    for ($i = 0; $i &lt; $num_obst; $i++) {
	if ($OBST[$i]-&gt;{uid} == $uid) {
	    $OBST[$i] = $OBST[$num_obst - 1];
	    $num_orig--;
	    return;
	}
    }
    print "DFU: UID not found?\n"; die;
};

sub DeleteObst {

    my $done = 0;

    my $delete = sub {
	my @tags = $CANVAS-&gt;gettags('current');
	if (join(' ',@tags) =~ /\bobst(\d+)\b/o) {
	    $CANVAS-&gt;delete('current');
	    DeleteObstByUID($1);
	} 
	$done = 1;
    };

    $CANVAS-&gt;bind('obst', '&lt;Button-1&gt;' =&gt; $delete);
    my ($opt,$name,$class,$default,$save_cursor) = $MW-&gt;configure('-cursor');
    $CANVAS-&gt;configure(-cursor =&gt; 'pirate');
    while (!$done) {
	DoOneEvent(DONT_WAIT | ALL_EVENTS);
    }
    $CANVAS-&gt;configure(-cursor =&gt; $save_cursor);
    $CANVAS-&gt;bind('obst', '&lt;Button-1&gt;' =&gt; sub{;});
};

sub SaveObstacles {
    my ($OB) = @ARG;
    
    if ($#ARG == -1) {
	if (!open(OB,"&gt;$OB")) {
	    Msg("Can't write obstacle file $OB $ERRNO\n");
	    return -1;
	}
    } else {
	if (!open(OB,"&gt;&gt;$OB")) {
	    Msg("Can't append obstacle file $OB $ERRNO\n");
	    return -1;
	}
    }

    my $i;
    for ($i = 0; $i &lt; $num_obst ; $i++) {
	my $buf = sprintf("obstacle %s %f,%f %f,%f perm %f",
			  $OBST[$i]-&gt;{type},
			  $OBST[$i]-&gt;{points}{x1},
			  $OBST[$i]-&gt;{points}{y1},
			  $OBST[$i]-&gt;{points}{x2},
			  $OBST[$i]-&gt;{points}{y2},
			  $OBST[$i]-&gt;{permeability});

	print OB &lt;&lt;"OBST"
#
# $buf
#
OBST
    }
    close OB;
};

sub ReadObstacles {
    my ($OB) = @ARG;
    
    if (!open(OB,"&lt;$OB")) {
	Msg("Can't read obstacle file $OB $ERRNO\n");
	return -1;
    }
    while (&lt;OB&gt;) {
	if (/^\# obstacle (\w+) (\d+.\d+),(\d+.\d+) (\d+.\d+),(\d+.\d+) perm (\d+.\d+)/) {
	    $OBST[$num_obst]-&gt;{type} = $1;
	    $OBST[$num_obst]-&gt;{points}{x1} = $2;
	    $OBST[$num_obst]-&gt;{points}{y1} = $3;
	    $OBST[$num_obst]-&gt;{points}{x2} = $4;
	    $OBST[$num_obst]-&gt;{points}{y2} = $5;
	    $OBST[$num_obst]-&gt;{permeabilty} = $6;
	    $OBST[$num_obst]-&gt;{uid} = $obst_uid++;
	    $num_obst++;
	}
    }
    if ($#ARG == -1) {close OB;}
    DrawObstacles();
};

###########################################################################
###########################################################################
# Clear All
###########################################################################

sub ClearAllNoAsk {
    $#MOVE = -1;
    $#NUM_TIMES = -1;
    $trace_loaded = 0;
    my $i;
    for ($i = 1; $i &lt;= $NN; $i++) {
	undisplay_waypoints($i);
	if ($EDIT[$i]-&gt;{MW} != '') {
	    $EDIT[$i]-&gt;{MW}-&gt;destroy();
	}
    }
    $#NODE_ATTR = -1;
    $#EDIT = -1;
    $#WP = -1;
    $NN = 0;
    $CANVAS-&gt;delete('all');
    $num_ends = 0;
    $num_orig = 0;
    $#ORIG = -1;
    if ($OrigWin != '') { $OrigWin-&gt;destroy(); $OrigWin = ''; }
    $#OBST = -1;
    $num_obst = 0; $obst_uid = 0;
    Msg('Cleared all...');
};

sub ClearAll {
    
    my ($erase, $cancel) = ('Erase', 'Cancel');
    my $dialog = $MW-&gt;Dialog(
	    -title          =&gt; 'Really Clear All?',
            -text           =&gt; "You are about to erase the current trace and scenario files from Ad-Hockey.\nAre you sure you want to do this?",
            -bitmap         =&gt; 'info',
            -default_button =&gt; $erase,
            -buttons        =&gt; [$erase, $cancel],
            -wraplength =&gt; '4i',
        );

    my $button = $dialog-&gt;Show;
    if ($button eq $cancel) {	
	return 0;
    }
    ClearAllNoAsk();
    return 1;
};

###########################################################################
###########################################################################
my $rin = '';
my $ns_slave_initialized = 0;
my $NS_SOCKET;

sub CheckNSSlave {
    if (!$ns_slave_initialized) {
	my $paddr = sockaddr_in($slave_to_ns_port, INADDR_ANY);
	socket(NS_SOCKET,PF_INET,SOCK_DGRAM,0) or
	    Msg("Can't get socket to listen for ns: $!") and 
		goto abort_ns_slave;
	bind(NS_SOCKET,$paddr) or Msg("bind: $!") and goto abort_ns_slave;
	vec($rin,fileno(NS_SOCKET),1) = 1;	
	$ns_slave_initialized = 1;
    }

    # poll for a message, while preserving the $rin vector
    my $rout = '';
    my $msg = '';
    my ($nfound,$timeleft) = select($rout = $rin, undef, undef, 0);
    if ($nfound &gt; 0) {
	recv(NS_SOCKET, $msg, $NS_SLAVE_MSG_LEN,0) or die "recv $!";
	my ($ns_time) = unpack($NS_SLAVE_MSG_FORMAT, $msg);
	if ($ns_time != int($CUR_TIME)) {
	    # need to resync ad-hockey with ns
	    Msg("Resyncing time with ns...");
	    change_time($ns_time);
	    $speed_scale-&gt;set(10);  #reset speed to real time
	}
    }
    
    return;

  abort_ns_slave:
    $slave_to_ns = 0;
    toggle_display() if $running;
    return;    
}



###########################################################################
###########################################################################
###########################################################################
###########################################################################
sub DEAD_CODE {
my $DEFAULT_CONNECTIONS = 'usrc-rts';

my $controls;
my $exit_but = $controls-&gt;Button(
			       -text =&gt; "Exit",
#			       -width =&gt; 10,
			       -command =&gt; sub {exit; },
);
my $addnode_but = $controls-&gt;Button(
			       -text =&gt; "Add Node",
#			       -width =&gt; 10,
			       -command =&gt; \&amp;add_node,
);
my $print_but = $controls-&gt;Button(
			       -text =&gt; "Print",
#			       -width =&gt; 10,
			       -command =&gt; \&amp;print_it,
);
my $save_but = $controls-&gt;Button(
			       -text =&gt; "Save",
			       -width =&gt; 15,
			       -command =&gt; sub {SaveScenario($main::SCEN)},
);

$addnode_but-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');
$save_but-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');
$print_but-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');
$exit_but-&gt;pack(-side =&gt; 'left', -expand =&gt; 'yes');

my $display_frame = $MW-&gt;Frame(-borderwidth =&gt; 2, -relief =&gt; 'groove');
my $display_label = $display_frame-&gt;Label(-text =&gt; 'Show Events: ',
					  -font =&gt; $FONT,);
my $show_rtrbut = $display_frame-&gt;Checkbutton(
		  -text =&gt; 'RTR',
		  -variable =&gt; \$show_rtr,
		  -relief =&gt; 'flat',
					   );
my $show_agtbut = $display_frame-&gt;Checkbutton(
		  -text =&gt; 'AGT',
		  -variable =&gt; \$show_agt,
		  -relief =&gt; 'flat',
					    );
$display_label-&gt;pack(-side =&gt; 'left');
$show_rtrbut-&gt;pack(-side =&gt;'left');
$show_agtbut-&gt;pack(-side =&gt;'left');

my $connections_frame = $display_frame-&gt;Frame();
my $connections_label = $connections_frame-&gt;Label(-text =&gt; 'Connections: ',
						  -font =&gt; $FONT,);
my $connections_entry = $connections_frame-&gt;Entry(
       -relief =&gt; 'sunken',
       -width =&gt; 16,
       );
$connections_entry-&gt;insert(0,$DEFAULT_CONNECTIONS);
my $connections_on = $connections_frame-&gt;Button(
       -text =&gt; 'show',
#       -relief =&gt; 'flat',
       -command =&gt; \&amp;show_connections,
       );
my $connections_all = $connections_frame-&gt;Checkbutton(
       -text =&gt; 'only feasible',
       -variable =&gt; \$show_feasible_connections,
       -relief =&gt; 'flat',
       );
$connections_label-&gt;pack(-side =&gt;'left');
$connections_entry-&gt;pack(-side =&gt;'left');
$connections_on-&gt;pack(-side =&gt;'left');
$connections_all-&gt;pack(-side =&gt;'left');
$connections_frame-&gt;pack();

$display_frame-&gt;pack();


###########################################################################
###########################################################################
# show connections
###########################################################################
sub show_connections {
    my ($i, $name, @from_coords, @to_coords, @nodes, $item, $rt, $rt_ok);
    my (@locations);
    
    $#locations = 0; # clear location of all nodes

    # find the positions of all nodes
    for ($i = 1 ; $i &lt;= $NN ; $i++) {
	@from_coords = $CANVAS-&gt;coords('n'.$i);
	$locations[$i]-&gt;[0] =  $from_coords[0];
	$locations[$i]-&gt;[1] =  $from_coords[1];
#	print("node $i at $locations[$i]-&gt;[0] $locations[$i]-&gt;[1]\n");
    }

    $CANVAS-&gt;delete('connections'); 
    my $CONNECTIONS = $connections_entry-&gt;get();
    if (!open(CONNECTIONS)) { Msg("No such file: $CONNECTIONS"); return;} 
ROUTE: while (&lt;CONNECTIONS&gt;) {
	chop;
	$#nodes = 0;
	@nodes = split / /;
	$rt = join(':',@nodes);
#	printf("connection nodes: %s\n",$rt);

	printf("."); # a busy marked to give the natives something to look at

	$rt_ok = 1;
	if ($show_feasible_connections) {
	    my ($dist, $dx, $dy);
	    for ($i = 0; $i &lt; $#nodes - 1; $i++) {
               $dx = $locations[$nodes[$i+1]]-&gt;[0]-$locations[$nodes[$i]]-&gt;[0];
	       $dy = $locations[$nodes[$i+1]]-&gt;[1]-$locations[$nodes[$i]]-&gt;[1];
		$dist = sqrt($dx * $dx + $dy * $dy);
		if ($dist &gt; scale_dist($RANGE)) {
		    $rt_ok = 0;
		    last;
		}
	    }
	}

	if ($rt_ok) {
	    for ($i = 0; $i &lt; $#nodes - 1; $i++) {
#		print("line for $nodes[$i] to $nodes[$i+1]\n");
#		print("drawing $locations[$nodes[$i]]-&gt;[0], $locations[$nodes[$i]]-&gt;[1] to $locations[$nodes[$i+1]]-&gt;[0], $locations[$nodes[$i+1]]-&gt;[1]\n");

		$name = $nodes[0].'-&gt;'.$nodes[$#nodes];
		$item = $CANVAS-&gt;create('line', 
				       $locations[$nodes[$i]]-&gt;[0]+$DOT_SIZE,
				       $locations[$nodes[$i]]-&gt;[1]+$DOT_SIZE,
				       $locations[$nodes[$i+1]]-&gt;[0]+$DOT_SIZE,
				       $locations[$nodes[$i+1]]-&gt;[1]+$DOT_SIZE,
					-fill =&gt; $conn_color, -tag =&gt; $name);
		$CANVAS-&gt;addtag('connections','withtag',$item);
		$CANVAS-&gt;addtag('rt|'.$rt,'withtag',$item);
	    }
	    print("\n");
	}
    }
    print("\n");
}

}				# end sub DEADCODE
</pre></body></html>