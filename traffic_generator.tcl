# Author: Oslo Wong
# Date:   5/15/15
#


#		为了产生background traffic，
#		使用流量产生器，有指数分布，柏拉图分布和恒定速率。
#		未测试
#
#
#        s1                 s3
#         \                 /
# 5Mb,3ms \    2Mb,10ms   / 5Mb,3ms
#           r1 --------- r2
# 5Mb,3ms /               \ 5Mb,3ms
#         /                 \
#        s2                 s4 
#

set ns [new Simulator]

$ns rtproto simple

#Define different colors for data flows
$ns color 0 Black
$ns color 1 Blue
$ns color 2 Red
$ns color 3 green
$ns color 4 yellow
$ns color 5 brown
$ns color 6 chocolate
$ns color 7 gold
$ns color 8 tan


#Open the nam trace file
set nf [open traffic_generator.nam w]
set tf [open traffic_generator.tr w]
$ns namtrace-all $nf
$ns trace-all $tf

#Define a 'finish' procedure
proc finish {} {
        global ns nf tf
	puts "------simulation over--------"
        $ns flush-trace
        #Close the trace file
        close $nf
        close $tf
        #Execute nam on the trace file
        exec nam traffic_generator.nam &
        exit 0
}

proc record {} {

    global ns myq

    set now [$ns now]
    puts "$now"
    #$myq print;

    $ns at [expr $now + 0.5] "record"

}

proc changeSpeed {} {
	global ns
	set aLink [$ns get-link-arr]
	array set arrLink $aLink

	puts "\n########"
	set now [$ns now]
    puts "$now"
	parray arrLink

	foreach i [array names arrLink] {
		#puts "$i  =  [$arrLink($i) bw]"
		$arrLink($i) setbw 100Mb
	}
	puts "########\n"
}

proc printBw {} {
	global ns
	set aLink [$ns get-link-arr]
	array set arrLink $aLink

	puts "\n########"
	set now [$ns now]
    puts "$now"
	parray arrLink

	foreach i [array names arrLink] {
		puts "$i  =  [expr [$arrLink($i) bw]  / 1000 / 1000] "
	}
	puts "########\n"

}

proc changeBandwidth {} {
	global ns
	set aLink [$ns get-link-arr]
	array set arrLink $aLink

#	set now [$ns now]
#    puts "$now"
#	parray arrLink

	foreach i [array names arrLink] {
		#puts "$i  =  [$arrLink($i) bw]"
		$arrLink($i) setbw 100Mb
	}
	puts "########\n"
}



set node_(s1) [$ns node]
set node_(s2) [$ns node]
set node_(r1) [$ns node]
set node_(r2) [$ns node]
set node_(s3) [$ns node]
set node_(s4) [$ns node]

set speed 100Mb

set		speed		[lindex $argv 0]
append speed "Mb"
puts $speed



$ns duplex-link $node_(s1) $node_(r1) $speed 3ms DropTail 
$ns duplex-link $node_(s2) $node_(r1) $speed 3ms DropTail 
$ns duplex-link $node_(r1) $node_(r2) $speed 3ms DTPR
$ns duplex-link $node_(s3) $node_(r2) $speed 3ms DropTail 
$ns duplex-link $node_(s4) $node_(r2) $speed 3ms DropTail 

#Set DTRR queue size to 20
$ns queue-limit $node_(r1) $node_(r2) 100

#set myq [$ns get-link-queue [$node_(r1) id] [$node_(r2) id]]
#$myq queue-test
#$myq queue-num 3
#puts $myq

set aLink [$ns get-link-arr]
array set arrLink $aLink
parray arrLink
[$arrLink([$node_(r1) id]:[$node_(r2) id]) queue] queue-test
foreach i [array names arrLink] {
	puts "$i [$arrLink($i) queue]"
}


#$ns duplex-link-op $node_(r1) $node_(r2) queuePos 0.5

$ns duplex-link-op $node_(s1) $node_(r1) orient right-down
$ns duplex-link-op $node_(s2) $node_(r1) orient right-up
$ns duplex-link-op $node_(r1) $node_(r2) orient right
$ns duplex-link-op $node_(s3) $node_(r2) orient left-down
$ns duplex-link-op $node_(s4) $node_(r2) orient left-up


set tcp0 [new Agent/TCP]
$ns attach-agent $node_(s1) $tcp0

set sink0 [new Agent/TCPSink]
$ns attach-agent $node_(s3) $sink0

set tcp1 [new Agent/TCP]
$ns attach-agent $node_(s2) $tcp1

set sink1 [new Agent/TCPSink]
$ns attach-agent $node_(s4) $sink1

set tcp2 [new Agent/TCP]
$ns attach-agent $node_(s2) $tcp2

set sink2 [new Agent/TCPSink]
$ns attach-agent $node_(s4) $sink2




$ns connect $tcp0 $sink0
$tcp0 set fid_ 1
$tcp0 set window_ 128
$tcp0 set packetSize_ 1000
$ns connect $tcp1 $sink1
$tcp1 set fid_ 2
$tcp1 set window_ 128
$tcp1 set packetSize_ 1000
$ns connect $tcp2 $sink2
$tcp2 set fid_ 3
$tcp2 set window_ 128
$tcp2 set packetSize_ 1000

set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1

set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2

#set flowVol [lindex $argv 0]
set flowVol 20

set nbytes [expr $flowVol * 1000 * 1000]
#puts $nbytes


#proc traffic_gen_init {num src dst} {
#
#}

# traffic generator
set udp0	[new Agent/UDP]
set sink0	[new Agent/UDP]
$udp0 set fid_ 1

$ns attach-agent $node_(s1)	$udp0
$ns attach-agent $node_(s3)	$sink0
$ns connect $udp0 $sink0

#set tg0 [new Application/Traffic/Exponential]
set tg0 [new Application/Traffic/Pareto]
#set tg0 [new Application/Traffic/CBR]

$tg0 attach-agent $udp0
$tg0 set packetSize_ 	1000
$tg0 set burst_time_ 	500ms
$tg0 set idle_time_  	500ms
$tg0 set rate_ 100k
$tg0 set shape_ 1.5


#Simulation Scenario
$ns at 1.0 "$ftp0 send $nbytes"
#$ns at 1.0 "$ftp1 send $nbytes"
#$ns at 1.0 "$ftp2 send $nbytes"
#$ns at 1.0	"$tg0 start"
#$ns at 1.0 "record"
$ns at 10.0 "printBw"
$ns at 11.0 "changeSpeed"
$ns at 12.0 "printBw"
$ns at 100.0 "finish"

$ns run







