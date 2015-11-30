#!/usr/bin/perl


$logFile="/home/hadoop/simu/ns2_test/result-pror-2.txt";
$tclFile="/home/hadoop/myGit/ns2/prior_test2.tcl";


system("rm $logFile");

#system("rm /home/hadoop/loaDis.txt");
$f2=$logFile;
$total=2;
$tag=1;
$runTime=1;

for($i=1; $i<=$runTime; $i=$i+1)
{
	system("echo	TEST  >> $f2");
	system("echo	total : $total   tag : $tag  >> $f2");
	system("echo	Number : $i >> $f2");
	system("ns $tclFile $i >> $f2");
	system("echo  TEST  >> $f2");
	system("echo   ''''                 >> $f2");
#print "\n";
}

