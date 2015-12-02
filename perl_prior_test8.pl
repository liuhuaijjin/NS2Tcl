#!/usr/bin/perl


$logFile="/home/oslo/simu/testResult/result-pror-8.txt";
$tclFile="/home/oslo/simu/ns2program/prior_test8.tcl";
$tclFile="/home/oslo/simu/ns2program/4test_prior_test8.tcl";

#$AllocInput="/home/hadoop/myGit/ns2/w_file.tcl";

$AwkFile = "/home/oslo/simu/ns2program/awkpacketLoss.awk";
$TraceFile = "/home/oslo/simu/prior_test8.tr";


system("rm $logFile");

#system("rm /home/hadoop/loaDis.txt");
$f2=$logFile;
$totalJob=2;
$tag=1;
$runTime=1;

for($i=1; $i<=$runTime; $i=$i+1)
{
	#system("echo	TEST  >> $f2");
	#system("echo	total : $total   tag : $tag  >> $f2");
	#system("echo	Number : $i >> $f2");
	#system("ns $AllocInput 200 >> $f2");
	# tcl程序接受4个参数
	# argv0		jobnum
	# argv1		queueNum
	# argv2		HowToReadPoint -- 1代表读取文件 --2代表随机产生
	# argv3		isflowBased		-- 1代表flowBased	-- 0 代表packetBased
	system("ns $tclFile $totalJob $totalJob 2 1 >> $f2");
	#system("awk -f $AwkFile $TraceFile >> $f2");
	#system("ns $tclFile $totalJob 0 1 0>> $f2");
	#system("awk -f $AwkFile $TraceFile >> $f2");

#print "\n";
}




