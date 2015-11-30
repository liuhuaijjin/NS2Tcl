set line		''"
set		file_in		[open  /home/hadoop/Desktop/alloc.txt r]
set i 1
while {[gets $file_in	line] >= 0 } {
	
	if {"" != $line} {
		regexp {([0-9]+)} $line number
		puts [format "%d\t%d" $i $number]
		incr i
	}
	
	
}


close $file_in


