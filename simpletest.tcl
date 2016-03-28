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
        #exec nam traffic_generator.nam &
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

# new
# 泊松分布 ru 默认 1
proc poisson { {ru 1}  {vv 0} } {
	#puts "泊松分布 $ru vv = $vv"

	set k 0
	set p 1
	set l [expr exp([expr -1 * $ru])]

	set k [expr $k + 1]
	set u [expr rand()]
	set p [expr $p * $u]

	while { $p > $l} {
		set k [expr $k + 1]
		set u [expr rand()]
		set p [expr $p * $u]
	}
	return [expr $k - 1]
}

set V1_GAUSSIAN		0
set V2_GAUSSIAN		0
set S_GAUSSIAN		0
set phase_GAUSSIAN 	0

# 标准正态分布
# 期望为0.0，方差为1.0
proc gaussian_NORMAL {} {
	#puts "标准正态分布"

	global V1_GAUSSIAN
	global V2_GAUSSIAN
	global S_GAUSSIAN
	global phase_GAUSSIAN

	set X 0
	if {0 == $phase_GAUSSIAN} {
		set S_GAUSSIAN 1
		while {$S_GAUSSIAN >= 1 || 0 == $S_GAUSSIAN} {
			set U1 [expr rand()]
			set U2 [expr rand()]
	
			set V1_GAUSSIAN [expr 2 * $U1 - 1]
			set V2_GAUSSIAN [expr 2 * $U1 - 1]
			set S_GAUSSIAN [expr $V1_GAUSSIAN * $V1_GAUSSIAN + $V2_GAUSSIAN * $V2_GAUSSIAN]
		}
		#X = V1 * sqrt(-2 * log(S) / S);
		set X [expr $V1_GAUSSIAN * sqrt(double(-2) * log($S_GAUSSIAN) / $S_GAUSSIAN) ]
	} else {
		#X = V2 * sqrt(-2 * log(S) / S);
		set X [expr $V2_GAUSSIAN * sqrt(double(-2) * log($S_GAUSSIAN) / $S_GAUSSIAN) ]
	}
	set phase_GAUSSIAN [expr 1 - $phase_GAUSSIAN]
	
	return $X
}

# 正态分布 mean std 默认是 0.0 和 1.0
proc gaussian { { mean 0.0 } { std 1.0 } } {
	#puts "正态分布 $mean $std"

	set normal [gaussian_NORMAL ]
	while {$normal < 0} {
		set normal [gaussian_NORMAL ]
	}
	return [expr $mean + $normal * $std]
}

# 指数分布 lambda默认 2
proc exponential { { lambda 2}  { vv 0} } {
	#puts "指数分布 $lambda vv = $vv"

	set pV 0
	while { 1 == 1} {
		set pV [expr rand()]
		if {$pV != 1} {
			break;
		}
	}
	#pV = (-1.0/lambda)*log(1-pV);
	return [expr log(1 - $pV) * (-1.0 / $lambda)]
} 


# type  :	1 -- 泊松分布 默认
#			2 -- 正态分布
#			3 -- 指数分布
proc changeBandwidth { type {can1 1} {can2 1} } {
	global ns bandWidth
	set aLink [$ns get-link-arr]
	array set arrLink $aLink

#	set now [$ns now]
#   puts "$now"
#	parray arrLink

	set distribution 0
	if { 1 != $type &&  2 != $type && 3 != $type} {
		set type 1
	}
	
	if {1 == $type} {
		set distribution poisson
	} elseif {2 == $type} {
		set distribution gaussian
	} elseif {3 == $type} {
		set distribution exponential
	}

	#puts $distribution
	foreach i [array names arrLink] {
		set bgbw [expr int ([$distribution $can1 $can2] * 1000 * 1000) ]
		$arrLink($i) setbw [expr $bandWidth - $bgbw]
		#$arrLink($i) setbw [expr 100 * 1000 * 1000]
	}
	#puts $bgbw
}

proc timeTest {} {
	global ns
	set now [$ns now]
	puts "$now"
}


proc everyDetect {} {
	global interval ns 
	global ftp0 ftp1 ftp2 status
	
	set now [$ns now]

	if { 0 == $status(ftp0) && yes == [$ftp0   isend] } {
		puts "$now ftp0 end"
		set status(ftp0) 1
	}
	
	if { 0 == $status(ftp1) && yes == [$ftp1   isend] } {
		puts "$now ftp1 end"
		set status(ftp1) 1
	}
	
	if { 0 == $status(ftp2) && yes == [$ftp2   isend] } {
		puts "$now ftp2 end"
		set status(ftp2) 1
	}
	
	$ns at [expr $now+$interval] "everyDetect "
	

}

set node_(s1) [$ns node]
set node_(s2) [$ns node]
set node_(r1) [$ns node]
set node_(r2) [$ns node]
set node_(s3) [$ns node]
set node_(s4) [$ns node]

set		speed		[lindex $argv 0]

set bandWidth	[expr 10 * 1000 * 1000]

set linkType DTPR

#set linkType DropTail

$ns duplex-link $node_(s1) $node_(r1) $bandWidth 3ms DropTail 
$ns duplex-link $node_(s2) $node_(r1) $bandWidth 3ms DropTail 
$ns duplex-link $node_(r1) $node_(r2) $bandWidth 3ms $linkType
$ns duplex-link $node_(s3) $node_(r2) $bandWidth 3ms DropTail 
$ns duplex-link $node_(s4) $node_(r2) $bandWidth 3ms DropTail 

#Set DTPR queue size to 20
$ns queue-limit $node_(r1) $node_(r2) 100

$ns queue-limit $node_(s1) $node_(r1) 100
$ns queue-limit $node_(s2) $node_(r1) 100
$ns queue-limit $node_(s3) $node_(r2) 100
$ns queue-limit $node_(s4) $node_(r2) 100


if { "DTPR" == $linkType } {
 
set myq [$ns get-link-queue [$node_(r1) id] [$node_(r2) id]]
#$myq queue-test
$myq queue-num 3
$myq queue-num 4
$myq addFidPrior 1
$myq addFidPrior 2
$myq addFidPrior 3
}

#set aLink [$ns get-link-arr]
#array set arrLink $aLink
#parray arrLink
#[$arrLink([$node_(r1) id]:[$node_(r2) id]) queue] queue-test
#foreach i [array names arrLink] {
	#puts "$i [$arrLink($i) queue]"
#}


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


array set status ""
set status(ftp0) 0
set status(ftp1) 0
set status(ftp2) 0

#parray status


#set flowVol [lindex $argv 0]
set flowVol 20

set nbytes [expr $flowVol * 1000 * 1000]
#puts $nbytes

set interval 0.1


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
$ns at 1.0 "$ftp1 send $nbytes"
$ns at 1.0 "$ftp0 send $nbytes"
#$ns at 1.0 "$ftp2 send $nbytes"
#$ns at 1.0	"$tg0 start"
#$ns at 1.0 "record"
$ns at 1.0 "everyDetect"

#$ns at 1.2345678 "timeTest" 
#$ns at 10.0 "printBw"
#$ns at 11.0 "changeBandwidth 1 2 3"
#$ns at 12.0 "printBw"
$ns at 500.0 "finish"

$ns run







