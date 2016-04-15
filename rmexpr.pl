#!/usr/bin/perl


for($redNum=1; $redNum<=4; $redNum=$redNum+1)
{
	$mapNum=$redNum*2+2;
	$testDir="/home/oslo/simu/testResult/m-$mapNum-r-$redNum";
	for($j=1; $j<=8;$j=$j+1)
	{
		$inputFile="$testDir/expr_data-$j.txt";
		system("rm $inputFile");
	}
}


#system("shutdown -h now");



