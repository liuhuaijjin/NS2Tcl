# Creating New Simulator
set ns [new Simulator]

$ns rtproto simple

#---------TOPOLOGY-------------
#
#Create Nodes
#

set     k				4
set     coreNum         [expr $k * $k / 4]
set     podNum	      	$k
set     eachPodNum		[expr $k / 2]
set     hostNum			[expr $k * $k * $k /4]
set		TAGSEC			1
set		runningTAGSEC	0


array set   coreSw		""
array set   pod			""
array set   host		""

# core switch
for {set i 0} {$i < $coreNum} {incr i} {
    set  coreSw($i) [$ns node]
}

# pod aggregation switch
# switch 命名规则：pod(i, type, j)
# i : podNum
# type : a-agg, e-edge
# j : eachPodNum

for {set i 0} {$i < $podNum} {incr i} {
    for {set j 0} {$j < $eachPodNum} {incr j} {
        set  pod($i,a,$j) [$ns node]
    }
}

# pod edge switch
for {set i 0} {$i < $podNum} {incr i} {
    for {set j 0} {$j < $eachPodNum} {incr j} {
        set  pod($i,e,$j) [$ns node]
    }
}

# host
for {set i 0} {$i < $hostNum} {incr i} {
    set  host($i) [$ns node]
}


#---------Set Switch arguments-------------
# 设置节点类型
# t_host, t_core单路径
# t_agg, t_edge 可多路径
set t_host      1
set t_core      2
set t_agg       3
set t_edge      4
set t_nc       	-1

# core switch
for {set i 0} {$i < $coreNum} {incr i} {
    set  classifier  [$coreSw($i) entry]
    $classifier  setNodeType    $t_nc
}


# host
for {set i 0} {$i < $hostNum} {incr i} {
    set  classifier  [$host($i) entry]
    $classifier  setNodeType    $t_nc
}


# agg switch
for {set pn 0} {$pn < $podNum} {incr pn} {
    for {set i 0} {$i < $eachPodNum} {incr i} {
		set aggsh [expr i * eachPodNum]
        set  classifier  [$pod($pn,a,$i) entry]
        $classifier    setFatTreeK $k
        $classifier    setNodeInfo  $pn $i $t_nc -1
		puts [$pod($pn,a,$i) id], aggsh
    }
}

# edge switch
for {set pn 0} {$pn < $podNum} {incr pn} {
    set aggsh [$pod($pn,a,0) id]
    for {set i 0} {$i < $eachPodNum} {incr i} {
        set  classifier  [$pod($pn,e,$i) entry]
        $classifier    setFatTreeK $k
        $classifier    setNodeInfo  $pn $i $t_nc $aggsh
    }
}







