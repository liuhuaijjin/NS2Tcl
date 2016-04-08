#!/usr/bin/perl

$tclFile="/home/oslo/simu/ns2program/linkfailure.tcl";

$runTime=5;

$mapNum=0;
$redNum=0;

for($redNum=3; $redNum<=4; $redNum=$redNum+1)
{
	$mapNum=$redNum*2+2;
	$testDir="/home/oslo/simu/testResult/m-$mapNum-r-$redNum";
	system("mkdir -p $testDir");
	for($j=5; $j<=8;$j=$j+1)
	{
		# j -- job数
		$resultFile="$testDir/result-pror-8-$j.txt";
		$totalJob=$j;
		if($totalJob==1){
			$runTime=2;
		}
		else{
			$runTime=5;
		}

		for($i=1; $i<=$runTime; $i=$i+1)
		{
			# 		ns tclFile	jobNum		优先级	文件读取方式	多路径方式(flow/spray)	路径方式(单/多)
			system("ns $tclFile $totalJob	$totalJob	2	1	0 $mapNum $redNum >> $resultFile");
			system("ns $tclFile $totalJob	0			1	1	0 $mapNum $redNum >> $resultFile");
			system("ns $tclFile $totalJob	$totalJob	1	0	0 $mapNum $redNum >> $resultFile");
			system("ns $tclFile $totalJob	0			1	0	0 $mapNum $redNum >> $resultFile");
			system("echo  >> $resultFile");
			#system("ns $tclFile $totalJob	$totalJob	1	0	1 $mapNum $redNum >> $resultFile");
			#system("ns $tclFile $totalJob	0			1	0	1 $mapNum $redNum >> $resultFile");
		}
	}
}

# tcl程序接受7个参数
# argv0		jobnum
# argv1		queueNum
# argv2		HowToReadPoint	-- 1代表读取文件	-- 2代表随机产生
# argv3		isflowBased		-- 1代表flowBased	-- 0代表packetBased
# argv4		isSinglePath	-- 1代表设置成单路径
# argv5		mapNum			-- 设置job的mapNum数
# argv6		redNum			-- 设置job的reduceNum数

# 进行４对，　map/reduce
# 4-1, 6-2, 8-3, 10-4
# 每对map/reduce，创建文件夹，存放结果数据
# 在每对map/reduce中， job数从1--8，　每种情况进行6组实验，　每组实验进行10次。
	# 1 : flow		优先级
	# 2 : flow		无优先级
	# 3 : spray		优先级
	# 4 : spray		无优先级
	# 5 : single	优先级
	# 6 : single	无优先级
#每次实验输出格式
# queueNum :
#	job1	job2	...		jobN	totalTime

#system("gnome-screensaver-command -l");
#system("shutdown -h now");


