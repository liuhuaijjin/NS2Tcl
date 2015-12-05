BEGIN{
	testId = 1;
	testIdmax = -1;
	testNum = 0;
	line = 0;
	totalJob = -1;
}

# NF 代表列数
{
	if (NF > 0 && $1 != "queueNum") {
		
		if(totalJob <= 0)
			totalJob = NF - 1;

		sum = 0;
		for(i=1;i<=NF - 1;i++){
			result[testId,i] += $i;
			sum += $i;
		}
		result[testId,NF] += sum / (NF - 1);

		++testId;
	}
	else if(NF == 0) {
		testIdmax = testId - 1;
		testId = 1;
		++testNum;
	}
	#print NF
}

END {
	print "testIdmax = " testIdmax " testNum = " testNum " totalJob = " totalJob

	for(i = 1; i <= testIdmax; ++i){
		print "scene " i " : "
		for(j = 1; j <= totalJob + 1; ++j){
			printf	(result[i,j] / testNum) "\t"
		}
		print "\n"
	}

#	for (k in result) {
#		split(k,idx,SUBSEP); 
#		print idx[1] "," idx[2] " = "result[idx[1],idx[2]];
#		print k result[k] 
#	}

}
