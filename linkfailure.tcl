#
#
#	topo : fat tree k = 4
# 
#
#	目的：
#	linkfailure, 基于background分支的background.tcl。
#
#
#	已有：
#	(1)	输出格式
#		t1	t2	t3 ...	sceneTime
#	！！完成	2015-04-23 16:04:41 
#
#	(2)	点的读入	
#	要完成点的选择，读取文件|随机产生
#	
#	(3) 当最高优先级完成，次优先级变成最高优先级，即设置最高优先级动态设定。
#
#	新增：
#		
#
#
#
#	2015-12-01 15:01:55 

	# tcl程序接受5个参数
	# argv0		jobnum
	# argv1		queueNum
	# argv2		HowToReadPoint	-- 1代表读取文件	-- 2代表随机产生
	# argv3		isflowBased		-- 1代表flowBased	-- 0代表packetBased
	# argv4		isSinglePath	-- 1代表设置成单路径

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
    
    global allocInputFile
    global HowToReadPoint
    
    set mapn $arrj($jobId,mapNum)
    set arraySize [array size arrl3]
    for {set i 0} {$i < $mapn} {incr i} {
        
        if { 1 == $HowToReadPoint} {
        	# 1 代表读取文件
        	# 2 代表随机产生
        	gets $allocInputFile	line
        	set		seq		[expr	$line % $arraySize]
        } else {
        	set seq [randInt   $arraySize]
        	puts $allocInputFile $seq
        }
        
        set arrj($jobId,m,$i) $arrl3($seq)
        if {-1 != $record} {
            puts $record "($jobId,m,$i) = [$arrl3($seq) id]"
        }
    }
    set reducen $arrj($jobId,reduceNum)
    for {set i 0} {$i < $reducen} {incr i} {
        
        if { 1 == $HowToReadPoint} {
        	# 1 代表读取文件
        	# 2 代表随机产生
        	gets $allocInputFile	line
        	set		seq		[expr	$line % $arraySize]
        } else {
        	set seq [randInt   $arraySize]
        	puts $allocInputFile $seq
        }
        
        set arrj($jobId,r,$i) $arrl3($seq)
        if {-1 != $record} {
            puts $record "($jobId,r,$i) = [$arrl3($seq) id]"
        }
    }
    puts $record ""
} 


# 在jobId的map和reduce之间建立ftp链接
# 在tcp_a数组中，	tcp_a($jobId,$i,$j)  = $tcp
# 在sink_a数组中，	sink_a($jobId,$i,$j) = $sink
# 在ftp_a数组中，	ftp_a($jobId,$i,$j)  = $ftp
# ftp中添加一维，表示 ftp状态
# "r" 代表未开始 "s" 代表正在进行 "d" 代表完成
# job(jobId,ing) 表示job正在运行的流的个数
proc createTcpConnection {job_a jobId tcp_a sink_a ftp_a record {wnd 256} {packetSize 1000}} {
    upvar $job_a		arrj
    upvar $tcp_a		arrtcp
    upvar $sink_a		arrsink
    upvar $ftp_a		arrftp
    global ns isFlowBased ftpRecord

    global pod
    global hostShift
    global srcAddrPodId dstAddrPodId hostNumInPod

    set mapn 		$arrj($jobId,mapNum)
    set reducen 	$arrj($jobId,reduceNum)
	set flowCnt		0

    for {set i 0} {$i < $mapn} {incr i} {
        for {set j 0} {$j < $reducen} {incr j} {
            set tcp [new Agent/TCP/Reno]
			
			set jjobid	[expr $jobId * 1000 + $flowCnt]
			#puts $jjobid
			#set jjobid	$jobId
			incr flowCnt
			if {0 == $isFlowBased} {
				set jjobid 		[expr $jjobid / 1000]
			}
			#puts $jjobid
            $tcp set fid_ 			$jjobid

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

			# 记录ftp的src，dst 节点, fid。 用于flow based scheduling
			set ftpRecord($ftp,src)	$arrj($jobId,m,$i)
			set ftpRecord($ftp,dst)	$arrj($jobId,r,$j)
			set ftpRecord($ftp,fid)	$jjobid

			if {1 == $isFlowBased} {
				foreach index [array names pod] {
					set  classifier  [$pod($index) entry]
					$classifier addFidToDstAddr $jjobid [expr [$arrj($jobId,r,$j) id] - $hostShift] 0
					$classifier addFidToDstAddr $jjobid [expr [$arrj($jobId,m,$i) id] - $hostShift] 1
				}

				set dstAddrPodId($jjobid) [expr ([$arrj($jobId,r,$j) id] - $hostShift) / $hostNumInPod]
				set srcAddrPodId($jjobid) [expr ([$arrj($jobId,m,$i) id] - $hostShift) / $hostNumInPod]
			}

            set arrtcp($jobId,$i,$j) 		$tcp
            set arrsink($jobId,$i,$j) 		$sink
            set arrftp($jobId,$i,$j) 		$ftp
            set arrftp($jobId,$i,$j,status) 	"r"
            set arrj($jobId,r$j,started) 	0
            set arrj($jobId,r$j,fin) 			0
            set arrj($jobId,ing) 			0
            #puts $record "($jobId,m$i,r$j) = [$arrj($jobId,m,$i) id].[$tcp port],[$arrj($jobId,r,$j) id].[$tcp dst-port]"
        }
    }
    flush $record
}

# ****************************************
proc setQueueNum { {num 0}} {
    global arrLink 
    foreach i [array names arrLink] {
        [$arrLink($i) queue] queue-num $num
    }
}


proc setTopPriority { {num 0}} {
# 设置队列中，最高优先级的标号
    global arrLink 
    foreach i [array names arrLink] {
        [$arrLink($i) queue] setMaxPriority $num
    }
}

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

#proc addrToFirstNode { id } {
#	global hostShift hostNumInPod eachPodNum coreNum aggNumInPod
#	return [expr $coreNum + $aggNumInPod + $eachPodNum * [addrToPodId $id] + [addrToSubnetId $id]]
#}

# 不仅设置路径的flow base
# isFeedBack 用来表示是否是ack路径
proc centrlCtrlFlow { command fid srcNodeId dstNodeId isFeedBack} {
	global pod CmdaddFlow CmdremoveFlow
	global hostShift

	set spid	[addrToPodId $srcNodeId]
	set ssubpid	[addrToSubnetId $srcNodeId]
	set dpid	[addrToPodId $dstNodeId]
	set dsubpid	[addrToSubnetId $dstNodeId]

	set firstNode	$pod($spid,e,$ssubpid)
	set classifier  [$firstNode entry]

	if {$spid != $dpid} {
		# 不同pod内， 6hops, 4paths
		if {$command == $CmdaddFlow} {
			set nextId [$classifier	addFlowId $fid $isFeedBack [expr $dstNodeId - $hostShift]]
			if {-1 == $nextId} {
				return
			}
			set sndNode $pod([addrToPodId $nextId 1],a,[addrToSubnetId $nextId 1])
			set classifier2  [$sndNode entry]
			$classifier2	addFlowId $fid $isFeedBack [expr $dstNodeId - $hostShift]
		} elseif {$command == $CmdremoveFlow} {
			set nextId [$classifier removeFlowId $fid $isFeedBack]
			if {-1 == $nextId} {
				return
			}
			set sndNode $pod([addrToPodId $nextId 1],a,[addrToSubnetId $nextId 1])
			set classifier2  [$sndNode entry]
			$classifier2	removeFlowId	$fid $isFeedBack
		}

	} elseif { $ssubpid != $dsubpid} {
		# 同pod， 不同subpod， 4hops, 2path
		if {$command == $CmdaddFlow} {
			set nextId [$classifier	addFlowId $fid $isFeedBack [expr $dstNodeId - $hostShift]]
		} elseif {$command == $CmdremoveFlow} {
			set nextId [$classifier removeFlowId $fid $isFeedBack]
		}
	}

}

# 根据ftp的src,dst，在相应的switch上添加/删除flow信息，
# 达成flow based scheduling
# centrlCtrl ftp {CmdaddFlow/CmdremoveFlow}
proc centrlCtrl { ftp command} {
	global ftpRecord pod CmdaddFlow CmdremoveFlow
	set srcNodeId	[$ftpRecord($ftp,src) id]
	set dstNodeId	[$ftpRecord($ftp,dst) id]
	set fid			$ftpRecord($ftp,fid)

	if {$srcNodeId == $dstNodeId} {
		return
	}

	# 设置发包路径的 flow base
	centrlCtrlFlow $command $fid $srcNodeId $dstNodeId 0
	# 设置ack路径的 flow base
	centrlCtrlFlow $command $fid $dstNodeId $srcNodeId 1
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
    global ns isFlowBased CmdaddFlow CmdremoveFlow

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
			if {1 == $isFlowBased} {
				centrlCtrl $arrftp($jobId,$i,$j) $CmdaddFlow
			}
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
    #puts "SCENE START at $startTime"
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
    global ns fend isFlowBased CmdaddFlow CmdremoveFlow
    set now [$ns now]

    set mapn		$job($jobId,mapNum)
    set reducen		$job($jobId,reduceNum)
    for {set j 0} {$j < $reducen} {incr j} {
        for {set k [expr $mapn - 1]} {$k >= 0} {set k [expr $k - 1]} {
            if {$ftp($jobId,$k,$j,status) == "s" && yes == [$ftp($jobId,$k,$j)   isend]} {
            	set		ftp($jobId,$k,$j,status)		"d"
                incr	job($jobId,r$j,fin)
                incr	job($jobId,ing)		-1
				if {1 == $isFlowBased} {
					centrlCtrl $ftp($jobId,$k,$j) $CmdremoveFlow
				}
                puts	$fend "$now    ftp($jobId,$k,$j) end [$job($jobId,m,$k) id].[$tcp($jobId,$k,$j) port],[$job($jobId,r,$j) id].[$tcp($jobId,$k,$j) dst-port]"
                puts	$fend "$now    job($jobId,r$j,fin) = $job($jobId,r$j,fin)"
                puts	$fend ""
                set		started		$job($jobId,r$j,started)
                if { $started < $mapn} {
                    set	nbyte [expr 1000 * 1000 * $numMb]
                    set	ftp($jobId,$started,$j,status) "s"
					if {1 == $isFlowBased} {
						centrlCtrl $ftp($jobId,$started,$j) $CmdaddFlow
					}
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
	
	global TopPriorityNum queueNum

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
			#puts "#[expr $now -  $sceneStartT] job($seq) finished."
			incr jobDoneNum
			set	jobIng($seq)	1
			#	jobIng($seq)	标记为 完成
			set	jobEndTime($sceneNum,$seq) [expr $now -  $sceneStartT]
			
			#	如果最高优先级job完成
			#	次高优先级成为最高优先级
			#	2015年06月12日 星期五 09时46分46秒 
			#if {$queueNum > 0 && $seq == $TopPriorityNum} {
				#set nextTop [expr 1 + $TopPriorityNum]
				#for {set ii $nextTop} {$ii <= $totalJobNum} {incr ii} {
					#if {$jobIng($ii) == 0} {
						#set TopPriorityNum $ii
						#setTopPriority $TopPriorityNum
						#break
					#}
				#}
			#}
			
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
        #puts "scene Done at $now"
        #puts "time : [expr $sceneEndT - $sceneStartT]"
        set jobEndTime(scene)	[expr $sceneEndT - $sceneStartT]
        
        incr qRecordCount 10000
    }

	#proc changeBandwidth { type {can1 1} {can2 1} }
	#changeBandwidth 1 1 1

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


proc lfDealWithAggLink { podId subPodId linkDstSubId isFlowBased feedBack lSrc lDst} {
	global pod dstAddrPodId srcAddrPodId

	set  classifier  [$pod($podId,e,$subPodId) entry]
	$classifier enableLinkFailure $lSrc $lDst

	if {1 == $isFlowBased} {
		set flowNum [$classifier getFlowNum4LF $feedBack]
		for {set j 0} {$j < $flowNum} {incr j} {
			set flowId [$classifier getFlowId4LF $feedBack]
			if {-1 == $flowId} {
				continue;
			}
			set next [$classifier addFlowIdforLF $flowId $feedBack]
			if {-1 == $next} {
				continue;
			}

			if {0 == $feedBack && $dstAddrPodId($flowId) == $podId} {
				continue;
			}
			if {1 == $feedBack && $srcAddrPodId($flowId) == $podId} {
				continue;
			}
			set  classifier2  [$pod($podId,a,$linkDstSubId) entry]
			$classifier2 removeFlowId $flowId $feedBack
			set  classifier2  [$pod($podId,a,$next) entry]
			$classifier2 addFlowId $flowId $feedBack -1
		}
	}
}

proc linkFailure { {src 4} {dst 0}} {

    global pod edgeShift aggShift hostShift
    global ns eachPodNum k isFlowBased

    # 设置相应节点 void enableLinkFailure(int linkSrcId, int linkDstId);
    # 对于 flowbased 存在的分配要重新分配

    #pod($i,a,$j)

    # 1 表示CORE_LINK, 2 表示AGG_LINK
    set linkFailureType		""
    set linkPodNum			""
    set linkSrcSubId		""
    set linkDstSubId		""

    # 只需修改对应pod 内 对应 srcSubid 的节点

    # 判断 断开链路的类型 CORE_LINK or AGG_LINK
    if { $src >= $aggShift && $src < $edgeShift} {
        set linkFailureType 1
        set linkSrcSubId [expr ($src - $aggShift) % $eachPodNum ]
        set linkPodNum [expr ($src - $aggShift) / $eachPodNum ]

        for {set i 0} {$i < $k} {incr i} {
            set  classifier  [$pod($i,a,$linkSrcSubId) entry]
            $classifier enableLinkFailure $src $dst
        }

    } elseif {$src >= $edgeShift && $src < $hostShift} {
        set linkFailureType 2
		set linkSrcSubId [expr ($src - $edgeShift) % $eachPodNum ]
        set linkDstSubId [expr ($dst - $aggShift) % $eachPodNum ]
        set linkPodNum [expr ($src - $edgeShift) / $eachPodNum ]

        for {set i 0} {$i < $k} {incr i} {
			#proc lfDealWithAggLink { podId subPodId linkDstSubId isFlowBased feedBack lSrc lDst}
			for {set j 0} {$j < $eachPodNum} {incr j} {
				lfDealWithAggLink $i $j $linkDstSubId $isFlowBased 0 $src $dst
				lfDealWithAggLink $i $j $linkDstSubId $isFlowBased 1 $src $dst
			}
        }
    }

	# 清空链路队列的包
    [$ns get-link-queue $src $dst] clearQueue
    [$ns get-link-queue $src $dst] clearQueue

}

# link 恢复
proc linkRecovery { {src 4} {dst 0}} {

    global pod edgeShift aggShift hostShift
    global ns eachPodNum k isFlowBased

    # 设置相应节点 void disableLinkFailure();
    # 对于 flowbased 存在的分配, 暂时没有重新分配

    # 1 表示CORE_LINK, 2 表示AGG_LINK
    set linkFailureType		""
    set linkPodNum			""
    set linkSrcSubId		""
    set linkDstSubId		""

    # 判断 断开链路的类型 CORE_LINK or AGG_LINK
    if { $src >= $aggShift && $src < $edgeShift} {
        set linkFailureType 1
        set linkSrcSubId [expr ($src - $aggShift) % $eachPodNum ]
        set linkPodNum [expr ($src - $aggShift) / $eachPodNum ]
        for {set i 0} {$i < $k} {incr i} {
            set  classifier  [$pod($i,a,$linkSrcSubId) entry]
            $classifier disableLinkFailure
        }
    } elseif {$src >= $edgeShift && $src < $hostShift} {
        set linkFailureType 2
		set linkSrcSubId [expr ($src - $edgeShift) % $eachPodNum ]
        set linkDstSubId [expr ($dst - $aggShift) % $eachPodNum ]

        for {set i 0} {$i < $k} {incr i} {
        	for {set j 0} {$j < $eachPodNum} {incr j} {
				set  classifier  [$pod($i,e,$j) entry]
				$classifier disableLinkFailure
			}
        }
    }
}



#**********************************************************


# -----------------------------------------------------




# Creating New Simulator
set ns [new Simulator]

$ns rtproto simple

# Setting up the traces

# trace记录文件，nam动画记录文件
set		f	[open simu/linkfailure.tr w]
set		nf	[open simu/linkfailure.nam w]
# 设置nam记录
#$ns namtrace-all $nf
#$ns trace-all $f

proc finish { {isNAM yes} } {
    global ns nf f rec fend
    global qFile qMonitor
    
    global jobEndTime		sceneNum
    global jobCmp	totalJobNum		isSinglePath
    #global seqqq
    global queueNum
    
    for {set i 1} {$i <= $sceneNum} {incr i} {
		#puts		"\n####Scene No. $i : #######"
		for {set j 1} {$j <= $totalJobNum} {incr j} {
			#puts -nonewline  "$jobEndTime($i,$j)\t"
			puts -nonewline	[format "%.4f \t" $jobEndTime($i,$j)]
			#puts -nonewline	[format "%10.4f" $jobEndTime($i,$j)]
		}
		puts -nonewline	[format "%.4f \t" $jobEndTime(scene)]
		#puts -nonewline	[format "%10.4f" $jobEndTime($i,$j)]
		#puts  "\n#####################"
	}
	puts ""
	if {0 == $queueNum && 1 == $isSinglePath} {
		puts ""
	}
	

	#puts  "\n CMP:"
	#for {set i 1} {$i <= $totalJobNum} {incr i} {
	#	set jobCmp($i) [expr $jobEndTime(2,$i) - $jobEndTime(1,$i)]
	#	puts -nonewline  "$jobCmp($i)\t"
	#}
	#puts  ""
	#parray	jobEndTime
	#puts "--------------------"
	#parray jobCmp
    
    #if {$jobCmp(1) > 0} {
    #	puts "\n\[Warn\] This is a bad situation. ----- $seqqq----\n"
    #}
    
    #set nodeAllocFile	/home/hadoop/nslog/nodeAlloc-log.tr
	#set endlogFile		/home/hadoop/nslog/end-log.tr
    #file copy $nodeAllocFile  /home/hadoop/simu/ns2_test/record/nodeAlloc-log-$seqqq.txt
    #file copy $endlogFile  /home/hadoop/simu/ns2_test/record/endlog-$seqqq.txt
    
    $ns flush-trace
    #puts "----------------------------------------"
    #puts "Simulation completed."
    close $nf
    close $f
    close $rec
    close $fend

    foreach i [array names qFile] {
        close $qFile($i)
    }
    if {$isNAM} {
            #exec nam simu/prior_test8.nam &
    }
    exit 0
}

$ns color 0 Black
$ns color 1000 Blue
$ns color 2000 Red
$ns color 3000 green
$ns color 4 yellow
$ns color 5 brown
$ns color 6 chocolate
$ns color 7 gold
$ns color 8 tan

$ns color 1 Blue
$ns color 2 Red
$ns color 3 green


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


set		aggShift		[expr $k * $k / 4]
set		hostShift		[expr 5 * $k * $k / 4]
set		hostNumInPod	[expr $k * $k / 4]
set		aggNumInPod		[expr $k * $k / 2]

set     edgeShift       [expr 3 * $k * $k / 4]

# coreSw	记录core 的switch
# pod		记录agg & edge switch
# 			pod aggregation switch
# 			switch 命名规则：pod(i,type,j)asa
# 			i : podNum
# 			type : a-agg, e-edge
# 			j : eachPodNum
# host		记录host

array set   coreSw		""
array set   pod			""
array set   host		""

# core switch
for {set i 0} {$i < $coreNum} {incr i} {
    set  coreSw($i) [$ns node]
}

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
#set			fakeFile			[open simu/fake.tr w]
set			qRecordCount	0


# 链路参数设置
#   linkargu
set		upLinkNum			$eachPodNum
set		downLinkNum			$eachPodNum
#set		bandWidth			100Mb
set		bandWidth			[expr 100 * 1000 * 1000]
set		linkDelay			10ms
set		queueLimit			100
#set		queueType				RED
#set		queueType				DropTail
set		queueType			DTPR


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
            $ns duplex-link	 $pod($pn,e,$i)	$host($incrBase)	$bandWidth	$linkDelay	$queueType
            $ns queue-limit	 $pod($pn,e,$i)	$host($incrBase)	$queueLimit
            $ns queue-limit	 $host($incrBase)	$pod($pn,e,$i)	$queueLimit

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

set		isFlowBased		[lindex $argv 3]
set		isSinglePath	[lindex $argv 4]

# 1 代表flowBased
# 0 代表packetBased

set		CmdaddFlow			1
set		CmdremoveFlow		2


# core switch
for {set i 0} {$i < $coreNum} {incr i} {
    set  classifier  [$coreSw($i) entry]
    $classifier  setNodeType    $t_core
	#$classifier  setFlowBased    $isFlowBased
}


# host
for {set i 0} {$i < $hostNum} {incr i} {
    set  classifier  [$host($i) entry]
    $classifier  setNodeType    $t_host
	#$classifier  setFlowBased    $isFlowBased
}


# agg switch
for {set pn 0} {$pn < $podNum} {incr pn} {
	for {set i 0} {$i < $eachPodNum} {incr i} {
		set aggsh [expr $i * $eachPodNum]
		set  classifier  [$pod($pn,a,$i) entry]
		$classifier		setFatTreeK $k
		$classifier		setNodeInfo $pn $i $t_agg $aggsh
		$classifier		setFlowBased $isFlowBased 1
		if {1 == $isSinglePath} {
			$classifier  setNodeType    $t_nc
		}
	}
}

# edge switch
for {set pn 0} {$pn < $podNum} {incr pn} {
	set aggsh [$pod($pn,a,0) id]
	for {set i 0} {$i < $eachPodNum} {incr i} {
		set  classifier  [$pod($pn,e,$i) entry]
		$classifier		setFatTreeK $k
		$classifier		setNodeInfo $pn $i $t_edge $aggsh
		$classifier		setFlowBased $isFlowBased 1
		if {1 == $isSinglePath} {
			$classifier  setNodeType    $t_nc
		}
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

#set		seqqq				[lindex $argv 0]
#set		totalJobNum		6

set		totalJobNum		[lindex $argv 0]
set		queueNum		[lindex $argv 1]
set		HowToReadPoint	[lindex $argv 2]

set		TopPriorityNum	1


puts 	[format "queueNum : %d" $queueNum]



#puts $totalJobNum
#puts $queueNum
#puts $HowToReadPoint

if { 1 == $HowToReadPoint} {
	# 1 代表读取文件
	set		allocInputFile		[open  /home/oslo/simu/alloc.txt r]
} else {
	# 2 代表随机产生
	set		allocInputFile		[open  /home/oslo/simu/alloc.txt w]
}



set		mapNum			[lindex $argv 5]
set		reduceNum		[lindex $argv 6]

set		mapWive			0
set		reduceWive		0

set		flowVol			20

set		jobDoneNum		0
array set	jobIng		""


set sceneStartT		0
set sceneEndT		0
set rec				[open /home/oslo/simu/nodeAlloc-log.tr w]
set	fend			[open /home/oslo/simu/end-log.tr w]

array set	jobCmp		""
array set	jobEndTime		""
set		sceneNum		0

array set ftpRecord ""

array set srcAddrPodId ""
array set dstAddrPodId ""

#---------JOB ARGUMENTS---------

# 一次实验 ，场景设置，分配节点，建立链接
# jobId 从1开始。

for {set i 1} {$i <= $totalJobNum} {incr i} {
    setMapNum job $i	$mapNum 	0
    setReduceNum job $i $reduceNum		0
    #proc allocNode {job jobId l3 {record -1}}
    allocNode job $i host	$rec 
    #proc createTcpConnection {job_a jobId tcp_a sink_a ftp_a record {wnd 512} {packetSize 5000}}
    createTcpConnection job $i tcp sink ftp $rec 
}


if { 2 == $HowToReadPoint} {
	# 2 代表随机产生
	flush $rec
	flush $allocInputFile
}



set isNAM yes
if { ![info exists isNAM] } {
    set isNAM no
}

set FirstSet			9
set FirstStart		[expr 1 + $FirstSet]

# 设置 linkFailure 起始时间
set lfTime			[expr $FirstStart + 10]

# 设置 linkRecovery 时间
set lfRecoveryTime	[expr $lfTime + 10]

# 设置 linkFailure 的 link的id， 注意这里规定 srcId > dstId
set lfSrcId			4
set lfDstId			0

# -----------------------------
# 获得队列，可以设置队列中优先级的个数。
set aLink [$ns get-link-arr]
array set arrLink $aLink


if {"DTPR" == $queueType} {
	$ns at $FirstSet "setQueueNum $queueNum"
	if { $queueNum > 0} {
		set TopPriorityNum 1
	}
	
}

#$ns at $FirstSet "printScene Scene_1_QueueFair"

$ns at $FirstSet "sceneStart $FirstStart $flowVol"
#proc linkFailure { {src 4} {dst 0}}
$ns at $lfTime "linkFailure $lfSrcId $lfDstId"
#proc linkRecovery { {src 4} {dst 0}}
$ns at $lfRecoveryTime "linkRecovery $lfSrcId $lfDstId"

$ns at 5000.0 "finish $isNAM"

$ns run



