
# 产生0~Range范围的随机整数
proc randInt { Range } {
    return [expr {int (rand()*$Range)}]
}

set		totalNum	[lindex $argv 0]


set		WRITE		[open  /home/hadoop/simu/alloc.txt w]
set i 0
for {set i 0} { $i < $totalNum} { incr i} {
	puts	$WRITE	[randInt 100]
	#if {4 == $i} {
	#	puts $WRITE ""
	#}
}

close $WRITE
