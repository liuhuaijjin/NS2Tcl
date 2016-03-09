set a 1
set b [expr exp($a)]

#puts $b

set a 1.000000000000001
set b 1
#if {$a > $b} {
	#puts "aaa"
#}

# 泊松分布 ru 默认 1
proc poisson { {ru 1}  {vv 0} } {
	puts "泊松分布 $ru vv = $vv"

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
	puts "标准正态分布"

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
	puts "正态分布 $mean $std"

	set normal [gaussian_NORMAL ]
	while {$normal < 0} {
		set normal [gaussian_NORMAL ]
	}
	return [expr $mean + $normal * $std]
}

# 指数分布 lambda默认 2
proc exponential { { lambda 2}  { vv 0} } {
	puts "指数分布 $lambda vv = $vv"

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
#	global ns
#	set aLink [$ns get-link-arr]
#	array set arrLink $aLink

#	set now [$ns now]
#    puts "$now"
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

	puts $distribution
#	foreach i [array names arrLink] {
		set bgbw [expr int ([$distribution $can1 $can2] * 1000 * 1000) ]
#		$arrLink($i) setbw 100Mb
#	}
	puts $bgbw
	puts "########\n"
}

if {1 == 1 && 2 != 2} {
	puts "xxxx"
} elseif {1 ==1 } {
	puts "yyyy"
} elseif {3 == 3} {

}

changeBandwidth 3 2 3

for {set i 0} { $i < -1} { incr i} {
	#puts [expr rand()]
	#puts [expr sqrt()]
	#puts [expr sqrt(28.0 / 3)]

	puts [poisson ]
	puts [poisson 2]
	puts [gaussian_NORMAL]
	puts [gaussian ]
	puts [gaussian 2 3]
	puts [exponential ] 
	puts [exponential 0.5] 
	puts  ""
}



