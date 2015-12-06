#!/usr/bin/perl


$inputFile="/home/oslo/simu/result-pror-8.txt";
$scriptFile="/home/oslo/simu/ns2program/newAvg.awk";
$outputFile="/home/oslo/simu/testResult/expr_data.txt"

for($j=1; $j<=8;$j=$j+1)
{
	$inputFile="/home/oslo/simu/result-pror-8-$j.txt";
	$outputFile="/home/oslo/simu/testResult/expr_data-$j.txt"
	system("awk -f $scriptFile $inputFile >> $outputFile");
	
}

#system("shutdown -h now");



