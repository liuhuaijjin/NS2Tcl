set a 1
set b [expr exp($a)]

#puts $b

set a 1.000000000000001
set b 1
#if {$a > $b} {
	#puts "aaa"
#}

proc poisson { ru } {
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

#期望为0.0，方差为1.0
proc gaussian_NORMAL {} {
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

proc gaussian { { mean 0.0 } { std 1.0 } } {
	puts "$mean $std"

	set normal [gaussian_NORMAL ]
	while {$normal < 0} {
		set normal [gaussian_NORMAL ]
	}
	return [expr $mean + $normal * $std]
}


proc exponential { { lambda 2} } {
	puts $lambda

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


for {set i 0} { $i < 10} { incr i} {
	#puts [poisson 2]
	#puts [expr rand()]
	#puts [expr sqrt()]
	#puts [expr sqrt(28.0 / 3)]
	#puts [gaussian_NORMAL]
	puts [gaussian 2 3]
	puts [gaussian ]
	#puts [exponential ] 
	#puts [exponential 0.5] 
}



