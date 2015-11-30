#!/usr/bin/perl


$logFile="/home/hadoop/simu/ns2_test/result-pror-5.txt";
$tclFile="/home/hadoop/myGit/ns2/prior_test5.tcl";

#$AllocInput="/home/hadoop/myGit/ns2/w_file.tcl";

$AwkFile = "/home/hadoop/myGit/ns2/awkpacketLoss.awk";
$TraceFile = "/home/hadoop/simu/prior_test5.tr";


system("rm $logFile");

#system("rm /home/hadoop/loaDis.txt");
$f2=$logFile;
$totalJob=3;
$tag=1;
$runTime=5;

for($i=1; $i<=$runTime; $i=$i+1)
{
	#system("echo	TEST  >> $f2");
	#system("echo	total : $total   tag : $tag  >> $f2");
	#system("echo	Number : $i >> $f2");
	#system("ns $AllocInput 200 >> $f2");
	
	system("ns $tclFile $totalJob $totalJob 2  >> $f2");
	#system("awk -f $AwkFile $TraceFile >> $f2");
	system("ns $tclFile $totalJob 0 1 >> $f2");
	#system("awk -f $AwkFile $TraceFile >> $f2");

#print "\n";
}

