#
#
#	topo : fat tree k = 4
# 
#	2个job， only 1 flow per job
#
#
#
#	scene 2 重新建立连接
#
#
#
#
#
#
#
#	2015-04-16 09:43:01



# -----------------------------------------------------


# 产生0~Range范围的随机整数
proc randInt { Range } {
    return [expr {int (rand()*$Range)}]
}

# 在job 数组中，设置jobId的map个数。
# job($jobId,mapNum) = base + (0 ~ range)
proc setMapNum {job jobId base range} {
    upvar $job arr
    set arr($jobId,mapNum) [expr $base + [randInt $range]]
}

# 在job 数组中，设置jobId的reduce个数。
# job($jobId,reduceNum) = base + (0 ~ range)
proc setReduceNum {job jobId base range} {
    upvar $job arr
    set arr($jobId,reduceNum) [expr $base + [randInt $range]]
}



# 给jobId的job中map和reduce随机分配到host中
# 并记录分配结果
proc allocNode {job jobId host {record -1}} {
    upvar $job      arrj
    upvar $host     arrl3
    set mapn $arrj($jobId,mapNum)
    set arraySize [array size arrl3]
    for {set i 0} {$i < $mapn} {incr i} {
        set seq [randInt   $arraySize]
        set arrj($jobId,m,$i) $arrl3($seq)
        #if {-1 != $record} {
            #puts $record "($jobId,m,$i) = [$arrl3($seq) id]"
            #puts $arrRecord($jobId,m,$i)
        #}
    }
    set reducen $arrj($jobId,reduceNum)
    for {set i 0} {$i < $reducen} {incr i} {
        set seq [randInt   $arraySize]
        set arrj($jobId,r,$i) $arrl3($seq)
        #if {-1 != $record} {
            #puts $record "($jobId,r,$i) = [$arrl3($seq) id]"
            #puts $arrRecord($jobId,r,$i)
        #}
    }
    #puts $record ""
} 


# 在jobId的map和reduce之间建立ftp链接
# 在tcp_a数组中，	tcp_a($jobId,$i,$j)  = $tcp
# 在sink_a数组中，	sink_a($jobId,$i,$j) = $sink
# 在ftp_a数组中，	ftp_a($jobId,$i,$j)  = $ftp
# ftp中添加一维，表示 ftp状态
# "r" 代表未开始 "s" 代表正在进行 "d" 代表完成
# job(jobId,ing) 表示job正在运行的流的个数
proc createTcpConnection {job_a jobId tcp_a sink_a ftp_a record {wnd 128} {packetSize 1000}} {
    upvar $job_a		arrj
    upvar $tcp_a		arrtcp
    upvar $sink_a		arrsink
    upvar $ftp_a		arrftp
    global ns

    set mapn 		$arrj($jobId,mapNum)
    set reducen 	$arrj($jobId,reduceNum)
    for {set i 0} {$i < $mapn} {incr i} {
        for {set j 0} {$j < $reducen} {incr j} {
            set tcp [new Agent/TCP/Reno]
            $tcp set fid_ 			$jobId
            $tcp set window_ 		$wnd
            $tcp set packetSize_ 	$packetSize
            $ns		attach-agent 	$arrj($jobId,m,$i)	$tcp

            set sink [new Agent/TCPSink]
            $ns attach-agent 		$arrj($jobId,r,$j)	$sink

            $ns connect 			$tcp 				$sink
            # ftp
            set ftp [new Application/FTP]
            $ftp attach-agent 		$tcp
            $ftp set type_ FTP

            set arrtcp($jobId,$i,$j) 		$tcp
            set arrsink($jobId,$i,$j) 		$sink
            set arrftp($jobId,$i,$j) 		$ftp
            set arrftp($jobId,$i,$j,status) 	"r"
            set arrj($jobId,r$j,started) 	0
            set arrj($jobId,r$j,fin) 			0
            set arrj($jobId,ing) 			0
            puts $record "($jobId,m$i,r$j) = [$arrj($jobId,m,$i) id].[$tcp port],[$arrj($jobId,r,$j) id].[$tcp dst-port]"
        }
    }
    
   	#parray arrftp
   	#puts "----------"
   	
    flush $record
}



proc reCreateTcpConnection {} {

    global job tcp sink ftp
    global rec totalJobNum
    
    #global ns
    #set now [$ns now]
    #puts $now

    for {set i 1} {$i <= $totalJobNum} {incr i} {
#proc createTcpConnection {job_a jobId tcp_a sink_a ftp_a record {wnd 512} {packetSize 5000}}
    	createTcpConnection job $i tcp sink ftp $rec
    }
}




# ****************************************
proc setQueueNum { {num 0}} {
    global arrLink 
    foreach i [array names arrLink] {
        [$arrLink($i) queue] queue-num $num
    }
}


proc printScene { label {channel -1}} {

    global	totalJobNum	tagNum
    #global	jobTag 			jobNotTag 
    global 	jobDoneNum
    global 	flowVol 		bandWidth 	queueLimit 	queueType
    global 	TAGSEC

    puts ""
    if {-1 == $channel} {
        puts "###  $label  ###"
        puts "--------------"
        puts "totalJobNum = $totalJobNum"
        #puts "tagNum = $tagNum"
        puts "flowVol = $flowVol"
        puts "bandWidth = $bandWidth"
        puts "queueLimit = $queueLimit"
        puts "queueType = $queueType"
        puts "TAGSEC = $TAGSEC"
        #puts "jobDoneNum = $jobDoneNum"
        puts "--------------"
        #parray jobTag
		#puts "[array size jobTag]"
        #puts "--------------"
        #parray jobNotTag
        #puts "--------------"
    } else {
        puts  $channel "###$label###"
        puts  $channel "--------------"
        puts  $channel "totalJobNum = $totalJobNum"
        #puts  $channel "tagNum = $tagNum"
        puts "flowVol = $flowVol"
        puts "bandWidth = $bandWidth"
        puts "queueLimit = $queueLimit"
        puts "queueType = $queueType"
        puts "TAGSEC = $TAGSEC"
        #puts  $channel "jobDoneNum = $jobDoneNum"
        puts  $channel "--------------"
        #foreach {k v} {[array get jobTag *]} {
             #puts  $channel  $k $v
        #}
        #puts $channel  "--------------"
        #foreach {k v} {[array get jobNotTag *]} {
             #puts  $channel  $k $v
        #}
        #puts $channel  "--------------"
    }
}


# 开始运行jobId的job
# 而且每个reduce最多与5个map传输
proc startJob {job_a jobId ftp_a wtime {numMb 100}} {
    upvar $job_a arrj
    upvar $ftp_a arrftp
    global ns

    set mapn $arrj($jobId,mapNum)
    set reducen $arrj($jobId,reduceNum)
    if {$mapn <= 5} {
        set mp $mapn
    } else {
        set mp 5
    }

    for {set j 0} {$j < $reducen} {incr j} {
        for {set i 0} {$i < $mapn} {incr i} {
            set arrj($jobId,r$j,started) 0
            set arrj($jobId,r$j,fin) 0
        }
    }

    for {set j 0} {$j < $reducen} {incr j} {
        for {set i 0} {$i < $mp} {incr i} {
            set nbyte [expr 1000*1000*$numMb]
            $ns at $wtime "$arrftp($jobId,$i,$j) send $nbyte"
            set arrftp($jobId,$i,$j,status) "s"
        }
        set arrj($jobId,r$j,started) $mp
        # 设置job正在运行的flow的个数
        incr arrj($jobId,ing)  $mp
    }
}



# 场景开始
# 启动 totalJobNum 个 job
# 每个流大小由numMb决定
# 并在开始后0.1开始  everyDetect

proc sceneStart {startTime {numMb 100}} {
    global	job ftp
    global	jobDoneNum	totalJobNum
    global 	ns	sceneStartT		sceneEndT
    
    global	jobIng
    global	sceneNum
    
    incr	sceneNum

    set		sceneStartT		$startTime
    puts "SCENE START at $startTime"
    set		jobDoneNum	0
    for {set i 1} {$i <= $totalJobNum} {incr i} {
        startJob job $i ftp $startTime $numMb
        set jobIng($i)	0
    }
    #parray jobIng
    

    $ns at [expr $startTime + 0.1] "everyDetect $numMb"
}


# 判断 jodId 中正在执行的ftp是否完成，完成且有未启动的，则启动。
proc jobFtpEndDetect {jobId   {numMb 100}} {
    global job ftp tcp
    global ns fend
    set now [$ns now]

    set mapn		$job($jobId,mapNum)
    set reducen		$job($jobId,reduceNum)
    for {set j 0} {$j < $reducen} {incr j} {
        for {set k [expr $mapn - 1]} {$k >= 0} {set k [expr $k - 1]} {
            if {$ftp($jobId,$k,$j,status) == "s" && yes == [$ftp($jobId,$k,$j)   isend]} {
            	set		ftp($jobId,$k,$j,status)		"d"
                incr	job($jobId,r$j,fin)
                incr	job($jobId,ing)		-1
                puts	$fend "$now    ftp($jobId,$k,$j) end [$job($jobId,m,$k) id].[$tcp($jobId,$k,$j) port],[$job($jobId,r,$j) id].[$tcp($jobId,$k,$j) dst-port]"
                puts	$fend "$now    job($jobId,r$j,fin) = $job($jobId,r$j,fin)"
                puts	$fend ""
                set		started		$job($jobId,r$j,started)
                if { $started < $mapn} {
                    set	nbyte [expr 1000 * 1000 * $numMb]
                    set	ftp($jobId,$started,$j,status) "s"
                    $ns	at $now "$ftp($jobId,$started,$j)  send $nbyte"
                    incr	job($jobId,r$j,started)
                    incr	job($jobId,ing)
                    puts	$fend "$now    ftp($jobId,$started,$j) start"
                    puts	$fend "$now    job($jobId,r$j,started) = $job($jobId,r$j,started)"
                    puts	$fend ""
                }
            }
        }
    }
}



# 检测jobId 的 job 是否完成
proc jobEndDetect { jobId } {
    global job
    global ns

    set now [$ns now]
    set mapn $job($jobId,mapNum)
    set reducen $job($jobId,reduceNum)
    set flag "yes"
    for {set i 0} {$i < $reducen} {incr i} {
        if {$job($jobId,r$i,fin) != $mapn} {
            set flag "no"
        }
	#puts "$now : $job($jobId,r$i,fin)"
    }

    return $flag
}

# 每隔intval检测一次，监测ftp和job的完成情况，并启动新的ftp
proc everyDetect { {numMb 100} } {
    global	job		ftp 
    global	jobTag	jobNotTag
    global 	ns fend jobDoneNum totalJobNum
    global 	sceneStartT sceneEndT
    global 	eachPodNum TAGSEC
    global 	qFile qMonitor
    global 	qRecordCount QUEUERECORD
    global 	jobEndTime
    global 	runningTAGSEC

	global jobIng
	global jobEndTime		sceneNum

    set intval 0.1
    set now [$ns now]
    #if {0 == [expr {int($now)} % 100]} {
        #puts "time : $now"
    #}

# 检测每个运行的job的每个运行的流的完成情况
# 如果完成且有未开始的，启动
    for {set seq 1} { $seq <= $totalJobNum} {incr seq} {
        #proc jobFtpEndDetect {jobId   {numMb 100}}
        jobFtpEndDetect $seq $numMb
    }


# 检测每个job是否完成
    for {set seq 1} { $seq <= $totalJobNum} {incr seq} {
        #proc jobEndDetect { jobId }
        if { yes == [jobEndDetect $seq] && 0 == $jobIng($seq)} {
        	#puts "$now job($jobTag($seq)) finished."
			puts "#[expr $now -  $sceneStartT] job($seq) finished."
			incr jobDoneNum
			set	jobIng($seq)	1
			#	jobIng($seq)	标记为 完成
			set	jobEndTime($sceneNum,$seq) [expr $now -  $sceneStartT]
			
			
        }
    }
    #puts "jobDoneNum = $jobDoneNum"


    if {1 == $QUEUERECORD} {
        foreach i [array names qMonitor] {
            puts $qFile($i) "$qRecordCount  [$qMonitor($i)  set pkts_]"
        }
        incr qRecordCount
        if {0 == [expr $qRecordCount % 10]} {
            foreach i [array names qFile] {
                flush $qFile($i)
            }
        }
    }

    if {$jobDoneNum < $totalJobNum} {
        $ns at [expr $now+$intval] "everyDetect $numMb"
    } else {
        set sceneEndT $now
        puts "scene Done at $now"
        puts "time : [expr $sceneEndT - $sceneStartT]"
        incr qRecordCount 10000
    }
}

#**********************************************************


# -----------------------------------------------------




# Creating New Simulator
set ns [new Simulator]

$ns rtproto simple

# Setting up the traces

# trace记录文件，nam动画记录文件
set		f	[open simu/prior_test1.tr w]
set		nf	[open simu/prior_test1.nam w]
# 设置nam记录
#$ns namtrace-all $nf
#$ns trace-all $f

proc finish { {isNAM yes} } {
    global ns nf f rec fend
    global qFile qMonitor
    
    global jobEndTime		sceneNum
    global jobCmp			totalJobNum
    global seqqq
    
    
    for {set i 1} {$i <= $sceneNum} {incr i} {
		puts		"\n####Scene No. $i : #######"
		for {set j 1} {$j <= $totalJobNum} {incr j} {
			puts -nonewline  "$jobEndTime($i,$j)\t"
		}
		puts  "\n#####################"
	}

	puts  "\n CMP:"
	for {set i 1} {$i <= $totalJobNum} {incr i} {
		set jobCmp($i) [expr $jobEndTime(2,$i) - $jobEndTime(1,$i)]
		puts -nonewline  "$jobCmp($i)\t"
	}
	puts  ""
	#parray	jobEndTime
	puts "--------------------"
	#parray jobCmp
    
    if {$jobCmp(1) > 0} {
    	puts "\n\[Warn\] This is a bad situation. ----- $seqqq -----\n"
    }
    
    set nodeAllocFile	/home/hadoop/nslog/nodeAlloc-log.tr
	set endlogFile		/home/hadoop/nslog/end-log.tr
    #file copy $nodeAllocFile  /home/hadoop/simu/ns2_test/record/nodeAlloc-log-$seqqq.txt
    #file copy $endlogFile  /home/hadoop/simu/ns2_test/record/endlog-$seqqq.txt
    
    $ns flush-trace
    puts "----------------------------------------"
    puts "Simulation completed."
    close $nf
    close $f
    close $rec
    close $fend

    foreach i [array names qFile] {
        close $qFile($i)
    }
    if {$isNAM} {
            #exec nam simu/prior_test1.nam &
    }
    exit 0
}

$ns color 0 Black
$ns color 1 Blue
$ns color 2 Red
$ns color 3 green
$ns color 4 yellow
$ns color 5 brown
$ns color 6 chocolate
$ns color 7 gold
$ns color 8 tan


#---------TOPOLOGY-------------
#
#Create Nodes
#

set     k					4
set     coreNum         	[expr $k * $k / 4]
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

#
#Create Link
#

# 设置队列记录
set QUEUERECORD 		0
#set QUEUERECORD 		1

array set   qFile			""
array set   qMonitor		""
set			fakeFile			[open simu/fake.tr w]
set			qRecordCount	0


# 链路参数设置
#   linkargu
set     upLinkNum     		$eachPodNum
set     downLinkNum     		$eachPodNum
set     bandWidth      		10Mb
set     linkDelay       		10ms
set     queueLimit      		100
#set	queueType				RED
#set	queueType				DropTail
set		queueType				DTPR


# link between Core and Pod
for {set pn 0} {$pn < $podNum} {incr pn} {
    set incrBase 0
    for {set i 0} {$i < $eachPodNum} {incr i} {
        for {set j 0} {$j < $upLinkNum} {incr j} {
            set nn [expr $incrBase + $j]
            $ns duplex-link $pod($pn,a,$i)	$coreSw($nn)	$bandWidth	$linkDelay	$queueType
            $ns queue-limit $pod($pn,a,$i)	$coreSw($nn)	$queueLimit
            $ns queue-limit $coreSw($nn)	$pod($pn,a,$i)	$queueLimit

            if {1 == $QUEUERECORD} {
                set lsrc  $pod($pn,a,$i)
                set ldst   $coreSw($nn)
                set qsrc [$lsrc id]
                set qdst [$ldst id]

                set qFile($qsrc-$qdst) [open queueFile/$qsrc-$qdst.out w]
                set qMonitor($qsrc-$qdst) [$ns monitor-queue $lsrc $ldst $fakeFile 0.1]

                set qFile($qdst-$qsrc) [open queueFile/$qdst-$qsrc.out w]
                set qMonitor($qdst-$qsrc) [$ns monitor-queue $ldst $lsrc $fakeFile 0.1]
            }

        }
        set incrBase [expr $incrBase + $upLinkNum]
    }
}

# link inside pod
for {set pn 0} {$pn < $podNum} {incr pn} {
    for {set i 0} {$i < $eachPodNum} {incr i} {
        for {set j 0} {$j < $eachPodNum} {incr j} {
            $ns duplex-link	$pod($pn,a,$i) $pod($pn,e,$j) $bandWidth $linkDelay $queueType
            $ns queue-limit $pod($pn,a,$i) $pod($pn,e,$j) $queueLimit
            $ns queue-limit $pod($pn,e,$j) $pod($pn,a,$i)  $queueLimit

            if {1 == $QUEUERECORD} {
                set lsrc  $pod($pn,a,$i)
                set ldst   $pod($pn,e,$j)
                set qsrc [$lsrc id]
                set qdst [$ldst id]

                set qFile($qsrc-$qdst) [open queueFile/$qsrc-$qdst.out w]
                set qMonitor($qsrc-$qdst) [$ns monitor-queue $lsrc $ldst $fakeFile 0.1]

                set qFile($qdst-$qsrc) [open queueFile/$qdst-$qsrc.out w]
                set qMonitor($qdst-$qsrc) [$ns monitor-queue $ldst $lsrc $fakeFile 0.1]
            }

        }
    }
}

set incrBase 0
# link between Pod and host
for {set pn 0} {$pn < $podNum} {incr pn} {
    for {set i 0} {$i < $eachPodNum} {incr i} {
        for {set j 0} {$j < $downLinkNum} {incr j} {
            $ns duplex-link	$pod($pn,e,$i)	$host($incrBase)	$bandWidth	$linkDelay	$queueType
            $ns queue-limit	$pod($pn,e,$i)	$host($incrBase)	$queueLimit
            $ns queue-limit	$host($incrBase)	$pod($pn,e,$i)	$queueLimit

            if {1 == $QUEUERECORD} {
                set lsrc  $pod($pn,e,$i)
                set ldst   $host($incrBase)
                set qsrc [$lsrc id]
                set qdst [$ldst id]

                set qFile($qsrc-$qdst) [open queueFile/$qsrc-$qdst.out w]
                set qMonitor($qsrc-$qdst) [$ns monitor-queue $lsrc $ldst $fakeFile 0.1]

                set qFile($qdst-$qsrc) [open queueFile/$qdst-$qsrc.out w]
                set qMonitor($qdst-$qsrc) [$ns monitor-queue $ldst $lsrc $fakeFile 0.1]
            }

            incr incrBase
        }
    }
}

#---------TOPOLOGY-------------


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
    
    set now [$ns now]
    puts $now
    $classifier  printNodeInfo
}


# host
for {set i 0} {$i < $hostNum} {incr i} {
    set  classifier  [$host($i) entry]
    $classifier  setNodeType    $t_nc
}


# agg switch
for {set pn 0} {$pn < $podNum} {incr pn} {
    for {set i 0} {$i < $eachPodNum} {incr i} {
        set  classifier  [$pod($pn,a,$i) entry]
        $classifier    setFatTreeK $k
        $classifier    setNodeInfo  $pn $i $t_nc   -1
    }
}

# edge switch
for {set pn 0} {$pn < $podNum} {incr pn} {
    set aggsh [$pod($pn,a,0) id]
    for {set i 0} {$i < $eachPodNum} {incr i} {
        set  classifier  [$pod($pn,e,$i) entry]
        $classifier    setFatTreeK $k
        $classifier    setNodeInfo  $pn $i $t_nc   $aggsh
    }
}


proc resetAllLast {} {
    global pod podNum eachPodNum
    for {set pn 0} {$pn < $podNum} {incr pn} {
    for {set i 0} {$i < $eachPodNum} {incr i} {
            set  classifier  [$pod($pn,a,$i) entry]
            $classifier    resetLast
            set  classifier  [$pod($pn,e,$i) entry]
            $classifier    resetLast
        }
    }
}

#---------Set Switch arguments-------------


#---------JOB ARGUMENTS---------

# jobargu

set		seqqq				[lindex $argv 0]
set		totalJobNum		2

set		mapNum			1
set		reduceNum			1

set		mapWive			0
set		reduceWive			0

set		jobDoneNum		0
array set	jobIng			""


set		flowVol				20


set sceneStartT		0
set sceneEndT		0
set rec				[open nslog/nodeAlloc-log.tr w]
set	fend			[open nslog/end-log.tr w]

array set	jobCmp				""
array set	jobEndTime		""
set			sceneNum		0



#---------JOB ARGUMENTS---------

# 一次实验 ，场景设置，分配节点，建立链接
# jobId 从1开始。
for {set i 1} {$i <= $totalJobNum} {incr i} {
    setMapNum job $i	$mapNum 	0
    setReduceNum job $i $reduceNum		0
    #proc allocNode {job jobId l3 {record -1}}
    allocNode job $i host
    #proc createTcpConnection {job_a jobId tcp_a sink_a ftp_a record {wnd 512} {packetSize 5000}}
    createTcpConnection job $i tcp sink ftp $rec 
}



set isNAM yes
if { ![info exists isNAM] } {
    set isNAM no
}

set FirstSet			9
set FirstStart		[expr 1 + $FirstSet]

set SecondSet		499
set SecondStart		[expr 1 + $SecondSet]

# -----------------------------
# 获得队列，可以设置队列中优先级的个数。
set aLink [$ns get-link-arr]
array set arrLink $aLink

#$ns at $FirstSet "setQueueNum 0"
#$ns at $FirstSet "setQueueNum $totalJobNum"
#$ns at $FirstSet "printScene Scene_1_QueueFair"
$ns at $FirstSet "sceneStart $FirstStart $flowVol"

#$ns at $SecondSet "reCreateTcpConnection"
#$ns at $SecondSet "setQueueNum $totalJobNum"
#$ns at $SecondSet "setQueueNum 0"
#$ns at $SecondSet "printScene Scene_2_QueuePrior"
$ns at $SecondSet "sceneStart $SecondStart $flowVol"


$ns at 5000.0 "finish $isNAM"

$ns run



