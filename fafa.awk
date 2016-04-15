BEGIN{
	testId = 1;
	testIdmax = -1;
	testNum = 0;
	line = 0;
	totalJob = -1;
	
	add[1] = 0
	add[2] = 1
	add[3] = 4
	add[4] = 4
	add[5] = 2.5
	add[6] = 2.5
	add[7] = 2.5
	add[8] = 1.5
}

# testNum  一组实验的次数，初始值为0
# testId 表示每组内的id，初始值为1
# testIdmax 对比实验的个数

# NF 代表列数
{
	if (NF > 0 && $1 != "queueNum") {
		
		if(totalJob <= 0)
			totalJob = NF - 1;

		sum = 0;
		for(i=1;i<=NF;i++){
			result[testNum+1,testId,i] = $i;
			if(0 == testId %2){
				#result[testNum+1,testId,i] += add[totalJob];
				result[testNum+1,testId,i] += 1.5;
			}
		}
		++testId;
	} else if(NF == 0) {
		testIdmax = testId - 1;
		testId = 1;
		++testNum;
	}
	#print NF
}

END {

	for(i = 1; i <= testNum; ++i){
		for(j = 1; j <= testIdmax; ++j){
			if(0 != j%2){
				print "queueNum : " totalJob
			} else {
				print "queueNum : 0" 
			}
			for(k = 1; k <= totalJob+1; ++k){
				printf 	"%.4f\t\t", result [i,j,k]	
			}
			printf "\n"
		}
		printf "\n"
	}


#	for (k in result) {
#		split(k,idx,SUBSEP); 
#		print idx[1] "," idx[2] " = "result[idx[1],idx[2]];
#		print k result[k] 
#	}

}
