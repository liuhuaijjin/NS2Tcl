#!/usr/bin/perl

$logFile="/home/oslo/simu/result-pror-8.txt";
$tclFile="/home/oslo/simu/ns2program/prior_test8.tcl";

#$AllocInput="/home/hadoop/myGit/ns2/w_file.tcl";

$AwkFile = "/home/oslo/simu/ns2program/awkpacketLoss.awk";
$TraceFile = "/home/oslo/simu/prior_test8.tr";


#system("rm $logFile");

#system("rm /home/hadoop/loaDis.txt");
$f2=$logFile;
$tag=1;
$runTime=5;

for($j=1; $j<=8;$j=$j+1)
{
	$logFile="/home/oslo/simu/result-pror-8-$j.txt";
	$f2=$logFile;
	$totalJob=$j;

	for($i=1; $i<=$runTime; $i=$i+1)
	{
		#system("echo	TEST  >> $f2");
		#system("echo	total : $total   tag : $tag  >> $f2");
		#system("echo	Number : $i >> $f2");
		#system("ns $AllocInput 200 >> $f2");
		# 		ns tclFile	jobNum		优先级	文件读取方式	多路径方式(flow/spray)	路径方式(单/多)
		system("ns $tclFile $totalJob	$totalJob	2	1	0 >> $f2");
		system("ns $tclFile $totalJob	0			1	1	0 >> $f2");
		system("ns $tclFile $totalJob	$totalJob	1	0	0 >> $f2");
		system("ns $tclFile $totalJob	0			1	0	0 >> $f2");
		system("ns $tclFile $totalJob	$totalJob	1	0	1 >> $f2");
		system("ns $tclFile $totalJob	0			1	0	1 >> $f2");
	}
}
# tcl程序接受5个参数
# argv0		jobnum
# argv1		queueNum
# argv2		HowToReadPoint	-- 1代表读取文件	-- 2代表随机产生
# argv3		isflowBased		-- 1代表flowBased	-- 0代表packetBased
# argv4		isSinglePath	-- 1代表设置成单路径
# 进行6次实验
	# 1 : flow		优先级
	# 2 : flow		无优先级
	# 3 : spray		优先级
	# 4 : spray		无优先级
	# 5 : single	优先级
	# 6 : single	无优先级
#每次实验输出格式
# queueNum :
#	job1	job2	...		jobN	totalTime

system("gnome-screensaver-command -l");
#system("shutdown -h now");



