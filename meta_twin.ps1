Function Meta-Twin {
    
<#
.SYNOPSIS  
        Meta-Twin copies metadata from one file ane inject into another.
.DESCRIPTION  
        Meta-Twin copies metadata from one file ane inject into another.
.LINK  
    n/a
                
.NOTES  
    Author/Copyright:     Copyright Joe Vest - All Rights Reserved
    
    Email/Blog/Twitter: joe@minis.io, threatexpress.com, @joevest
    
    Disclaimer:         THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
                        OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
                        While these scripts are tested and working in my environment, it is recommended 
                        that you test these scripts in a test environment before using in your production 
                        environment. Tom Arbuthnot further disclaims all implied warranties including, 
                        without limitation, any implied warranties of merchantability or of fitness for 
                        a particular purpose. The entire risk arising out of the use or performance of 
                        this script and documentation remains with you. In no event shall Tom Arbuthnot, 
                        its authors, or anyone else involved in the creation, production, or delivery of 
                        this script/tool be liable for any damages whatsoever (including, without limitation, 
                        damages for loss of business profits, business interruption, loss of business 
                        information, or other pecuniary loss) arising out of the use of or inability to use 
                        the sample scripts or documentation.
    
     
    Requirements:   See project README
.EXAMPLE
        Function-Template
 
        Description
        -----------
        Returns Objects
.EXAMPLE
        Function-Template -Param1
 
        Description
        -----------
        Actions Param1
# Parameters
.PARAMETER Param1
        Param1 description
.PARAMETER Param2
        Param2 Description
        
#>

  #############################################################
  # Param Block
  #############################################################
  
  Param     (
    [ValidateScript({Test-Path $_ })]
        [Parameter(Mandatory=$true,
        HelpMessage='Source binary')]
        $Source = '',
    
    [ValidateScript({Test-Path $_ })]
        [Parameter(Mandatory=$true,
        HelpMessage='Target binary')]
        $Target = '',

    [Parameter(Mandatory=$false,
        HelpMessage='Include digital signature')]
        [Switch]$Sign
    
    
  ) #Close Parameters


  #############################################################
  # Variables
  #############################################################

# Logo

$logo = @"




=================================================================
 ___ ___    ___ ______   ____      ______  __    __  ____  ____  
|   |   |  /  _]      | /    |    |      ||  |__|  ||    ||    \ 
| _   _ | /  [_|      ||  o  |    |      ||  |  |  | |  | |  _  |
|  \_/  ||    _]_|  |_||     | -- |_|  |_||  |  |  | |  | |  |  |
|   |   ||   [_  |  |  |  _  | --   |  |  |        | |  | |  |  |
|   |   ||     | |  |  |  |  |      |  |   \      /  |  | |  |  |
|___|___||_____| |__|  |__|__|      |__|    \_/\_/  |____||__|__|
=================================================================
Author: @joevest
=================================================================

"@

####################################
# VARIABLES

# Binaries
$resourceHackerBin = ".\src\resource_hacker\ResourceHacker.exe"
$resourceHacker_base_script = ".\src\rh_base_script.txt"
$mimikatzBin       = ".\src\resource_hacker\ResourceHacker.exe"
$sigtheifBin       = ".\src\SigThief-master\dist\sigthief.exe"

$timestamp = Get-Date -f yyyyMMdd_HHmmss
$log_file_base = (".\" + $timestamp + "\" + $timestamp)
$source_binary_filename = Split-Path $Source -Leaf -Resolve
$source_binary_filepath = $Source
$target_binary_filename = Split-Path $Target -Leaf -Resolve
$target_binary_filepath = $Target
$source_resource = (".\" + $timestamp + "\" + $timestamp + "_" + $source_binary_filename + ".res")
$target_saveas = (".\" + $timestamp + "\" + $timestamp + "_" + $target_binary_filename)
$target_saveas_signed = (".\" + $timestamp + "\" + $timestamp + "_signed_" + $target_binary_filename)
$resourcehacker_script = (".\" + $timestamp + "\" + $timestamp + "_rh_script.txt")

New-Item ".\$timestamp" -type directory | out-null
write-host $logo
write-host "    Source:        " $source_binary_filepath
write-host "    Target:        " $target_binary_filepath
write-host "    Output:        " $target_saveas
write-host "    Signed Output: " $target_saveas_signed
write-host "---------------------------------------------- "


####################################
# FUNCTIONS
# Wait for Resource Hacker to finish

Function WaitForResourceHacker {
    <#
    .SYNOPSIS  
        Meta-Twin copies metadata from one file ane inject into another.
    .DESCRIPTION  
        Meta-Twin copies metadata from one file ane inject into another.

    #>
    Param     (
        [Parameter(Mandatory=$true,
        HelpMessage='Wait Messagey')]
        $Message = ''
    
    )


    while (get-process resourcehacker -ErrorAction SilentlyContinue) {
        Write-Progress -Activity "$Message ..."
        Start-Sleep .2
        }
    }


####################################
# Start

# Clean up ResourceHacker.exe that may be running

Stop-Process -Name ResourceHacker -ea SilentlyContinue

# Extract resources using Resource Hacker from source 
$msg = " [*] Extracting resources from $source_binary_filename "
write-host $msg
$log_file = ($log_file_base + "_extract.log")

$arg = "-open $source_binary_filepath -action extract -mask ,,, -save $source_resource -log $log_file"
start-process -FilePath $resourceHackerBin -ArgumentList $arg -NoNewWindow
WaitForResourceHacker -Message $msg

# Check if extract was successful
if (Select-String -Encoding Unicode -path $log_file -pattern "Failed") {
    write-host " [!] Failed to extract Metadata from $source_binary_filepath"
    write-host "     Perhaps, try a differenct source file"
    write-host "     Exiting..."
    return   
}

# Build Resource Hacker Script
$log_file = ($log_file_base + "_add.log")
(Get-Content $resourceHacker_base_script).replace('AAA', $target) | Set-Content $resourcehacker_script
(Get-Content $resourcehacker_script).replace('BBB', $target_saveas) | Set-Content $resourcehacker_script
(Get-Content $resourcehacker_script).replace('CCC', $log_file) | Set-Content $resourcehacker_script
(Get-Content $resourcehacker_script).replace('DDD', $source_resource) | Set-Content $resourcehacker_script

# Copy resources using Resource Hacker
$msg = " [*] Copying resources from $source_binary_filename to $target_saveas"
Write-Host $msg
$arg = "-script $resourcehacker_script" 
start-process -FilePath $resourceHackerBin -ArgumentList $arg -NoNewWindow 
WaitForResourceHacker -Message $msg

# Add Digital Signature using SigTheif
if ($Sign) {

    # Copy signature from source and add to target
    $msg = " [*] Extrating and adding signature ..."
    Write-Host $msg
    $arg = "-i $source_binary_filepath -t $target_saveas -o $target_saveas_signed"
    $a = start-process -FilePath $sigtheifBin -ArgumentList $arg -wait -NoNewWindow -PassThru
    if ($a.ExitCode -eq -1) {
        write-host " [!] Cannot extract signature, skipping ..."     
        $Sign = $False   
    }

}

# Display Results
Start-Sleep .5
write-host ""
write-host " [*] Results"
write-host " -----------------------------------------------"


if ($Sign) {

    write-host " [*] Metadata"
    gi $target_saveas_signed | select VersionInfo | fl

    write-host " [*] Digital Signature"
    Get-AuthenticodeSignature (gi $target_saveas_signed) | select SignatureType,SignerCertificate,Status | fl

} else {
    write-host " [*] Metadata"
    gi $target_saveas | select VersionInfo | fl

    write-host " [*] Digital Signature"
    write-host "     Signature not added ... "

}




}