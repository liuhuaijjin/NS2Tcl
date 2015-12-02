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

set     k				4
set     coreNum         [expr $k * $k / 4]
set     podNum	      	$k
set     eachPodNum		[expr $k / 2]
set     hostNum			[expr $k * $k * $k /4]
set		TAGSEC			1
set		runningTAGSEC	0

set		aggShift		[expr $k * $k / 4]
set		hostShift		[expr 5 * $k * $k / 4]
set		hostNumInPod	[expr $k * $k / 4]
set		aggNumInPod		[expr $k * $k / 2]

set		totalNodeNum	[expr $hostShift + $k * $hostNumInPod]

proc addrToPodId { id {level 3}} {
	global hostShift hostNumInPod aggShift eachPodNum
	if {3 == $level} {
		return [expr ($id - $hostShift) / $hostNumInPod]
	} elseif {1 == $level} {
		return [expr ($id - $aggShift) / $eachPodNum]
	}
}

proc addrToSubnetId { id {level 3}} {
	global hostShift hostNumInPod aggShift eachPodNum
	if {3 == $level} {
		return [expr (($id - $hostShift) % $hostNumInPod) / $eachPodNum]
	} elseif {1 == $level} {
		return [expr ($id - $aggShift) % $eachPodNum]
	}
}

proc addrToFirstNode { id } {
	global hostShift hostNumInPod eachPodNum coreNum aggNumInPod
	return [expr $coreNum + $aggNumInPod + $eachPodNum * [addrToPodId $id] + [addrToSubnetId $id]]

}

proc getFirstNodeByAddr { id } {
	global hostShift hostNumInPod eachPodNum coreNum aggNumInPod
	return [expr $coreNum + $aggNumInPod + $eachPodNum * [addrToPodId $id] + [addrToSubnetId $id]]

}

# pod aggregation switch
# switch 命名规则：pod(i,type,j)
# i : podNum
# type : a-agg, e-edge
# j : eachPodNum

#$arrftp($jobId,$i,$
#ftpRecord()

#set  classifier  [$coreSw($i) entry]

set		CmdaddFlow		1
set		CmdremoveFlow	2

#for {set id $hostShift} {$id < $totalNodeNum} {incr id} {
#	puts "$id  [addrToPodId $id] -- [addrToSubnetId $id] -- [addrToFirstNode $id]"
#}

for {set id $aggShift} {$id < [expr $hostShift - $aggNumInPod]} {incr id} {
	puts "$id  [addrToPodId $id 1] -- [addrToSubnetId $id 1]"
}

# 根据ftp的src,dst，在相应的switch上添加/删除flow信息，
# 达成flow based scheduling
# centrlCtrlFlow ftp {CmdaddFlow/CmdremoveFlow}
proc centrlCtrlFlow { ftp command} {
	global ftpRecord pod CmdaddFlow CmdremoveFlow
	set srcNodeId	[$ftpRecord($ftp,src) id]
	set dstNodeId	[$ftpRecord($ftp,dst) id]
	set fid			$ftpRecord($ftp,fid)

	if {$srcNodeId == $dstNodeId} {
		return
	}
	set spid	[addrToPodId $srcNodeId]
	set ssubpid	[addrToSubnetId $srcNodeId]
	set dpid	[addrToPodId $dstNodeId]
	set dsubpid	[addrToSubnetId $dstNodeId]

	set firstNode	$pod($spid,e,$ssubpid)
	set classifier  [$firstNode entry]

	if {$spid != $dpid} {
		# 不同pod内， 6hops, 4paths
		if {$command == $CmdaddFlow} {
			set nextId [$classifier	addFlowId	$fid]
			if {-1 == $nextId} {
				return
			}
			set sndNode $pod([addrToPodId $nextId],a,[addrToSubnetId $nextId])
			set classifier2  [$sndNode entry]
			$classifier2	addFlowId	$fid
		} elseif {$command == $CmdremoveFlow} {
			set nextId [$classifier removeFlowId $fid]
			if {-1 == $nextId} {
				return
			}
			set sndNode $pod([addrToPodId $nextId],a,[addrToSubnetId $nextId])
			set classifier2  [$sndNode entry]
			$classifier2	removeFlowId	$fid
		}

	} elseif { $ssubpid != $dsubpid} {
		# 同pod， 不同subpod， 4hops, 2path
		if {$command == $CmdaddFlow} {
			set nextId [$classifier	addFlowId	$fid]
		} elseif {$command == $CmdremoveFlow} {
			set nextId [$classifier removeFlowId $fid]
		}
	}
}



proc ttt {} {

	set a 3
	set b 4
	if {$a == 1} {
		puts "-------------"
		return 
	} elseif {$b == 2} {
		puts "*************"
		return 
	}
	puts "88888888888888"

}



























