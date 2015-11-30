


BEGIN{

	fsDrops_1 = 0;
	fsDrops_2 = 0;
	numFs_1 = 0;
	numFs_2 = 0;

	firstStart1 =  20 ;
	firstEnd1=    12  ;
	
	firstStart2 =   20 ;
	firstEnd2=	    12 ;

}

{
	action = $1;
	time = $2;
	from = $3;
	to = $4;
	type = $5;
	pktsize = $6;
	flow_id = $8;
	src = $9;
	dst = $10;
	seq_no = $11;
	packet_id = $12;
	
	
	
	
	if (from == firstStart1 && to == firstEnd1 && action == "+")
	{
		if (flow_id == 1)
			++numFs_1;
	}
	if (from == firstStart2 && to == firstEnd2 && action == "+")
	{
		if (flow_id == 2)
			++numFs_2;
	}
	
	if (action == "d")
	{
		if (flow_id == 1)
			++fsDrops_1;
		if (flow_id == 2)
			++fsDrops_2;
	}
	
}



END {

	#printf("flow 1:\n");
	printf("send : %d\tlost : %d\n", numFs_1, fsDrops_1);
	#printf("flow 2:\n");
	printf("send : %d\tlost : %d\n", numFs_2, fsDrops_2);
	
	printf("\n");

}
