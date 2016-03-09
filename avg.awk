


BEGIN{
	num = 0;
	line = 0;
}

{
	if (NF > 0 && $1 != "queueNum") {
		totalJob = NF - 1;
		sum = 0;
		for(i=1;i<=NF - 1;i++)
			sum+=$i;
		result[num] = sum / (NF - 1);
		fp[num] = $1;
		++num;
	}
	if(NF > 1)
		++line;
	#print NF
}

END {
	isAll = 1;
	
	numIsAll = 0;
	j = 0;
	sum = 0;
	sumfp = 0;
	for(j = 0; j < num; j += 2) {
		if (1 == isAll) {
			tmpfp = 1 - fp[j] / fp[j+1] ;
			tmp = 1 - result[j] / result[j+1] ;
#			print tmpfp "  " tmp;
			if (tmpfp > 0 && tmp > 0){
				sumfp += tmpfp;
				sum += tmp;
				++numIsAll;
			}
		} else {
			print 1 - fp[j] / fp[j+1] ;
			print 1 - result[j] / result[j+1] ;
			print "";
		}
	}
	
	if (1 == isAll) {
		print "totalJob = " totalJob
		print numIsAll;
		print line / 4;
		print sumfp / numIsAll;
		print sum / numIsAll;
		print "\n";
#		print sumfp * 2 / num;
#		print sum * 2 / num;
	}
}
