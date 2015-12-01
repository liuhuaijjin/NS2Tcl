# Creating New Simulator
set ns [new Simulator]

$ns rtproto simple

set nf [open out.nam w]
$ns namtrace-all $nf
 
#Define a 'finish' procedure
proc finish {} {
        global ns nf
        $ns flush-trace
        #Close the NAM trace file
        close $nf
        #Execute NAM on the trace file
        exec nam out.nam &
        exit 0
}
 
#Create four nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

$ns color 0 Black
$ns color 1 Blue
$ns color 2 Red
$ns color 3 green
$ns color 4 yellow
$ns color 5 brown
$ns color 6 chocolate
$ns color 7 gold
$ns color 8 tan

#Create links between the nodes
$ns duplex-link $n0 $n1 2Mb 10ms DropTail
$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n3 2Mb 10ms DropTail
$ns duplex-link $n2 $n3 2Mb 10ms DropTail
 
set udp [new Agent/UDP]
$ns attach-agent $n0 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
$udp set fid_  1
$udp set fid_  2

puts [$n3 id]
puts [[$null set node_] id]


#Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 1mb
$cbr set random_ false
 
  #Schedule events for the CBR and FTP agents
#$ns at 0.1 "$cbr start"
#$ns at 4.5 "$cbr stop"
 
#$ns at 5.0 "finish"
#$ns run
array set ss ""

set isFlowBased	1


set jobId		1
set flowCnt		0
for {set i 0} {$i < 10} {incr i} {
	set ss($i)	[expr $jobId * 1000 + $flowCnt]
	incr flowCnt
	if {0 == $isFlowBased} {
		set ss($i) 		[expr $ss($i) / 1000]
	}
}

parray ss

array set tt ""
set ftp [new Application/FTP]
puts $ftp
set tt($ftp) 1

parray tt

#$arrftp($jobId,$i,$
#ftpRecord()

#set  classifier  [$coreSw($i) entry]

set     k				8
set     coreNum         [expr $k * $k / 4]
set     podNum	      	$k
set     eachPodNum		[expr $k / 2]
set     hostNum			[expr $k * $k * $k /4]
set		TAGSEC			1
set		runningTAGSEC	0

set		hostShift		[expr 5 * $k * $k / 4]
set		hostNumInPod	[expr $k * $k / 4]
set		aggNumInPod		[expr $k * $k / 2]

set		totalNodeNum	[expr $hostShift + $k * $hostNumInPod]

proc addrToPodId { id } {
	global hostShift hostNumInPod
	return [expr ($id - $hostShift) / $hostNumInPod]
}

proc addrToSubnetId { id } {
	global hostShift hostNumInPod eachPodNum
	return [expr (($id - $hostShift) % $hostNumInPod) / $eachPodNum]
}

proc addrToFirstNode { id } {
	global hostShift hostNumInPod eachPodNum coreNum aggNumInPod
	return [expr $coreNum + $aggNumInPod + $eachPodNum * [addrToPodId $id] + [addrToSubnetId $id]]

}


for {set id $hostShift} {$id < $totalNodeNum} {incr id} {
	puts "$id  [addrToPodId $id] -- [addrToSubnetId $id] -- [addrToFirstNode $id]"
}

