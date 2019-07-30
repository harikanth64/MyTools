<#

Script name: 	Get-Logs.ps1

Description: 	Use this script to capture required logs for diognosis for further troubleshooting

Requires:		Microsoft PowerShell

Written by: 	Harikanth on 20/04/2019

Usage: 			.\Get-Logs.ps1                         - without argument collectes all related logs files (complete logs).
				.\Get-Logs.ps1 <startdate> <enddate>   - with arguments StartDate EndDate collectes all data files between the dates.

				Example 1: .\Get-Logs.ps1
				Example 2: .\Get-Logs.ps1 20190327 20190410

				Logs captured in file Logs-YYYYMMDD.zip file format       YYYYMMDD - is current date
				Example: CustID_Logs_20190420.zip

Version History
Dev-v1.0    20-Jun-2019 Mamidala.Harikanth@hpe.com  New script
Dev-v1.1    21-Jun-2019	Mamidala.Harikanth@hpe.com  Updated the code to capture all control files from metering folder and added customer ID to the zip file
Prod-v1.2   27-Jun-2019 Pete.Sladden@hpe.com        Added output filename confirmation to console output in default option, modified date format to dd-MMM-yyyy in console messaging, cleaned up console output

#>

# Script Version
    $GetLogsVersion = 'v1.2 27-Jun-2019'   
    
# Console
    Write-Host "Running Get-Logs.ps1 script version $GetLogsVersion"

# Defining variables
$ctrlFile = ".\IAAS_ControlFile.txt"
$getControlFiles = Get-ChildItem . -Recurse -Include *Control*.txt -Exclude *ControlFile.Example*
$todayDate = Get-Date -Format "yyyyMMdd"
$zipflag = 0


$destination = Get-ChildItem -Path . -Recurse -Directory | Select-Object BaseName

[string]$start = $args[0]
[string]$end = $args[1]


#Function to zip IAAS_ControlFile and IAAS_ControlFileVM if used for metering
function zip-controlfiles {
    
    # Get text were ever it has | separated and trip the spaces
    
    #$line1 = $ctrlFile | ForEach-Object { $_.split("|")[0] }
    #$line2 = $ctrlFile | ForEach-Object { $_.split("|")[1] }
    #$fields = $line1 | ForEach-Object { $_.replace(" ","")}


    # Compress-Archive -path .\IAAS_ControlFile.txt -Update .\"$custID"_Logs_"$todayDate"
    Compress-Archive -path $getControlFiles -Update .\$custID"_Logs_"$todayDate
    Write-Host "`nControl files included:"
    $getControlFiles | Select-Object Name   


}

#Function to collect the all requried logs
function Get-logs([string]$s, [string]$e) {

    [string]$s_date = $s
	[string]$e_date = $e

    $SD = ([datetime]::ParseExact($s_date,"yyyyMMdd",$null)).toshortdatestring()
    $ED = ([datetime]::ParseExact($e_date,"yyyyMMdd",$null)).toshortdatestring()

    $Total_days = New-TimeSpan -Start $SD -End $ED
    $count = $todayDate.days

    $SDate = Get-Date $SD 
    $EDate = Get-Date $ED

    For($i=$SDate ; $i -le $EDate; $i=$i.AddDays(1)) { 
	
	    $timestamp = $i.ToString("yyyyMMdd")


  
	    # Checking for data files for a given date 
        $logs = Get-Childitem -path ".\Log" -Recurse -Include *$timestamp*; 
        $output = Get-Childitem -path ".\Output" -Recurse -Include *$timestamp*;
        $report = Get-Childitem -path ".\Report" -Recurse -Include *Report*;
        $xml = Get-Childitem -path ".\XML" -Recurse -Include *$timestamp*;
	    

        if (( Get-Childitem -path . -recurse | Select-String -Pattern $timestamp) -AND ($zipflag -eq 0))
        {
            foreach ($folder in $destination)
            {
                               
                if ( ($folder.basename -eq "Log") -and ($logs -ne $null) ) {

		            $Logdir = New-item ".\tempLogs\Logs" -type Directory -Force;	             
		            Copy-Item $logs -Destination ".\tempLogs\Logs" -Force
                                        
                    } #else { Write-Host "No Data file for $timestamp in Log folder"}

                if ( ($folder.basename -eq "Output") -and ($output -ne $null) ) {

		            $Logdir = New-item ".\tempLogs\Output" -type Directory -Force;	             
		            Copy-Item $output -Destination ".\tempLogs\Output" -Force
                    
                    } #else { Write-Host "No Data file for" $timestamp }

                if ( ($folder.basename -eq "Report") -and ($report -ne $null) ) { 

		            $Logdir = New-item ".\tempLogs\Report" -type Directory -Force;	             
		            Copy-Item $report -Destination ".\tempLogs\Report" -Force
                    
                    } #else { Write-Host "No Data file for" $timestamp }

                if ( ($folder.basename -eq "XML") -and ($xml -ne $null) ) {

		            $Logdir = New-item ".\tempLogs\XML" -type Directory -Force;	             
		            Copy-Item $xml -Destination ".\tempLogs\XML" -Force
                    
                    } #else { Write-Host "No Data file for" $timestamp }
		    }
        } else { Write-Host "No Data files for $timestamp in Log folder" -ForegroundColor Red}
        
	 }

    Write-Host "`nLog folders zipped to" $custID"_Logs_$timestamp.zip" -ForegroundColor Yellow
}


# Main 
switch -file $ctrlFile {
        default {		
            $Fields = $_.split("|")			        
            switch ($Fields[0].replace(" ","")) { 
                "CustomerID" {
                                $custID = $Fields[1].replace(" ","")   # Get customer ID from controlfile
                                if ($custID -eq 'REPLACE_WITH_ACCOUNT_ID') {
                                    Write-Host "Customer ID missing" -ForegroundColor Red
                                    Write-Host "Update the Customer ID and rerun the script to the collect logs"
                                    $zipflag = 1
                                }
                                
                             }
                default	     { }

            }
        }
}
    # Write-Host $custID



if (($args[0].length -ne 0) -and ($args[1] -ne 0) -and ($zipflag -eq 0)) { 
             
            Get-logs -s $start -e $end
            Compress-Archive -path .\tempLogs\* -CompressionLevel Optimal -DestinationPath .\$custID"_Logs_"$todayDate
            zip-controlfiles
            Remove-Item .\templogs -Recurse
            
    } elseif ($zipflag -eq 0) {
            
            $today = Get-Date -Format "dd-MMM-yyyy"
            $LogsOutputFileName = $CustId+"_Logs_"+$todayDate+".zip"
            Write-Host "`nCollecting log folders: $today to $LogsOutputFileName`n" -ForegroundColor Yellow
            
            if ((test-path ".\Log") -AND (Test-Path ".\Log\*" -PathType Leaf)) {
                Write-Host "Log       : zipped"
                Compress-Archive -path .\Log -Update .\$custID"_Logs_"$todayDate
                } Else { Write-Host "Log       : Not Zipped  (folder missing OR no files in the folder)" -ForegroundColor Red}

            if ((test-path ".\Report") -AND (Test-Path ".\Report\*" -PathType Leaf)) {
                Write-Host "Report    : zipped"
                Compress-Archive -path .\Report -Update .\$custID"_Logs_"$todayDate
                } Else { Write-Host "Report    : Not Zipped  (folder missing OR no files in the folder)"}


            if ((test-path ".\Output") -AND (Test-Path ".\Output\*" -PathType Leaf)) {
                Write-Host "Output    : zipped"
                Compress-Archive -path .\Output -Update .\$custID"_Logs_"$todayDate
                } Else { Write-Host "Output    : Not Zipped  (folder missing OR no files in the folder)"}


            if ((test-path ".\XML") -AND (Test-Path ".\XML\*" -PathType Leaf)) {
                Write-Host "XML       : zipped"
                Compress-Archive -path .\XML -Update .\$custID"_Logs_"$todayDate
                } Else { Write-Host "XML       : Not Zipped  (folder missing OR no files in the folder)"}



            zip-controlfiles

      }

     