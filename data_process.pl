#!/usr/bin/perl

# perl_prior_test8.pl　输出的处理程序
# 处理结果放到 /home/oslo/simu/testResult/文件夹里面
$inputFile="/home/oslo/simu/result-pror-8.txt";
$scriptFile="/home/oslo/simu/ns2program/newAvg.awk";
$outputFile="/home/oslo/simu/testResult/expr_data.txt";

for($j=1; $j<=8;$j=$j+1)
{
	$inputFile="/home/oslo/simu/result-pror-8-$j.txt";
	$outputFile="/home/oslo/simu/testResult/expr_data-$j.txt";
	system("awk -f $scriptFile $inputFile >> $outputFile");
}

#system("shutdown -h now");



