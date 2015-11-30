#!/usr/bin/perl

system("rm /home/hadoop/simu/ns2_test/result-pror-1.txt");

#system("rm /home/hadoop/loaDis.txt");
$f2="/home/hadoop/simu/ns2_test/result-pror-1.txt";
$total=2;
$tag=1;
$runTime=100;

    for($i=1; $i<=$runTime; $i=$i+1)
    {
        system("echo	TEST  >> $f2");
        system("echo	total : $total   tag : $tag  >> $f2");
        system("echo	Number : $i >> $f2");
        system("ns /home/hadoop/myGit/ns2/prior_test1.tcl $i >> $f2");
        system("echo  TEST  >> $f2");
        system("echo   ''''                 >> $f2");
        #print "\n";
    }

