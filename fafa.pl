#!/usr/bin/perl

# perl_prior_test9.pl　输出的处理程序
# 处理结果直接放到对应的文件夹里面
$scriptFile="/home/oslo/simu/ns2program/fafa.awk";

for($redNum=1; $redNum<=4; $redNum=$redNum+1)
{
	$mapNum=$redNum*2+2;
	$testDir="/home/oslo/simu/testResult/m-$mapNum-r-$redNum";
	$outDir="/home/oslo/simu/testResult/fafa/m-$mapNum-r-$redNum";
	for($j=1; $j<=8;$j=$j+1)
	{
		$inputFile="$testDir/result-pror-8-$j.txt";
		$outputFile="$outDir/result-pror-8-$j.txt";
		system("mkdir -p $outDir");
		system("awk -f $scriptFile $inputFile > $outputFile");
	}
	system("rm -r $testDir");
}


#system("shutdown -h now");



