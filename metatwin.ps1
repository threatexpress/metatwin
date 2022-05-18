Function Invoke-MetaTwin {
    
<#
.SYNOPSIS  
    
    Meta-Twin copies metadata and the AuthenticodeSignature from a source binary and into a target binary
    
    Function: Meta-Twin
    Author: Joe Vest (@joevest), PSv2 Compatibility by Andrew Chiles (@andrewchiles)
    License: BSD 3-Clause
    Required Dependencies: ResourceHacker.exe
    Optional Dependencies: None
    
.DESCRIPTION  
        Meta-Twin copies metadata and the AuthenticodeSignature from a source binary and into a target binary
        Note: SigThief and Resource Hacker may not detect valid metadata or digital signature.  This project may switch to a different tool set, but for now, be aware of potential limitations.
        
.LINK  
    https://www.github.com/minisllc/metatwin
    http://threatexpress.com/2017/10/metatwin-borrowing-microsoft-metadata-and-digital-signatures-to-hide-binaries/
    
.PARAMETER Source

        Path to source binary (where you want to copy the resources from)
        
.PARAMETER Target

        Path to target binary (where you want the resources copied to)
        
.PARAMETER Sign

        Switch to perform AuthenticodeSignature copying via SigThief
        
.EXAMPLE
    
        C:\PS> Invoke-MetaTwin -Source C:\windows\explorer.exe -Target c:\mypayload.exe -Sign
 
        Description
        -----------
        Copies binary resource metadata and AuthenticodeSignature from a source binary to a new copy of the target binary
#>

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
        
  )

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

Set-StrictMode -Version 2

# Basic file timestomping, maybe redundant since it will also need to be performed on target
Function Invoke-TimeStomp ($source, $dest) {
    $source_attributes = Get-Item $source
    $dest_attributes = Get-Item $dest 
    $dest_attributes.CreationTime = $source_attributes.CreationTime
    $dest_attributes.LastAccessTime = $source_attributes.LastAccessTime
    $dest_attributes.LastWriteTime = $source_attributes.LastWriteTime
}

# Binaries
$resourceHackerBin = ".\src\resource_hacker\ResourceHacker.exe"
$sigthiefBin       = ".\src\SigThief-master\dist\sigthief.exe"

# Perform some quick dependency checking
If ((Test-Path $resourceHackerBin) -ne $True) 
    {
        Write-Output "[!] Missing Dependency: $resourceHackerBin"
        Write-Output "[!] Ensure you're running MetaTwin from its local directory. Exiting"
        break
    }

If ((Test-Path $sigthiefBin) -ne $True) 
    {
        Write-Output "[!] Missing Dependency: $sigthiefBin"
        Write-Output "[!] Ensure you're running MetaTwin from its local directory. Exiting."
        break
    }

$timestamp = Get-Date -f yyyyMMdd_HHmmss
$log_file_base = (".\" + $timestamp + "\" + $timestamp)
$source_binary_filename = Split-Path $Source -Leaf -Resolve
$source_binary_filepath = $Source
$target_binary_filename = Split-Path $Target -Leaf -Resolve
$target_binary_filepath = $Target
$source_resource = (".\" + $timestamp + "\" + $timestamp + "_" + $source_binary_filename + ".res")
$target_saveas = (".\" + $timestamp + "\" + $timestamp + "_" + $target_binary_filename)
$target_saveas_signed = (".\" + $timestamp + "\" + $timestamp + "_signed_" + $target_binary_filename)

New-Item ".\$timestamp" -type directory | out-null
Write-Output $logo
Write-Output "Source:         $source_binary_filepath"
Write-Output "Target:         $target_binary_filepath"
Write-Output "Output:         $target_saveas"
Write-Output "Signed Output:  $target_saveas_signed"
Write-Output "---------------------------------------------- "

# Clean up existing ResourceHacker.exe that may be running

Stop-Process -Name ResourceHacker -ea "SilentlyContinue"

# Extract resources using Resource Hacker from source 
 Write-Output "[*] Extracting resources from $source_binary_filename "

$log_file = ($log_file_base + "_extract.log")

$arg = "-open $source_binary_filepath -action extract -mask ,,, -save $source_resource -log $log_file"
start-process -FilePath $resourceHackerBin -ArgumentList $arg -NoNewWindow -Wait

# Check if extract was successful
if (Select-String -Encoding Unicode -path $log_file -pattern "Failed") {
    Write-Output "[!] Failed to extract Metadata from $source_binary_filepath"
    Write-Output "    Perhaps, try a differenct source file. Exiting..."
    break   
}

# Copy resources using Resource Hacker
"[*] Copying resources from $source_binary_filename to $target_saveas"

$arg = "-open $target_binary_filepath -save $target_saveas -resource $source_resource -action addoverwrite"
start-process -FilePath $resourceHackerBin -ArgumentList $arg -NoNewWindow -Wait

# Add Digital Signature using SigThief
if ($Sign) {

    # Copy signature from source and add to target
    "[*] Extracting and adding signature ..."
    $arg = "-i $source_binary_filepath -t $target_saveas -o $target_saveas_signed"
    $proc = start-process -FilePath $sigthiefBin -ArgumentList $arg -Wait -PassThru
    #$proc | Select * |Format-List
    #$proc.ExitCode
    if ($proc.ExitCode -ne 0) {
        Write-Output "[-] Cannot extract signature, skipping ..."     
        $Sign = $False   
    }
}

# Display Results
Start-Sleep .5
Write-Output "`n[+] Results"
Write-Output " -----------------------------------------------"


if ($Sign) {

    Write-Output "[+] Metadata"
    Get-Item $target_saveas_signed | Select VersionInfo | Format-List

    Write-Output "[+] Digital Signature"
    Get-AuthenticodeSignature (gi $target_saveas_signed) | select SignatureType,SignerCertificate,Status | fl
    Invoke-TimeStomp $source_binary_filepath $target_saveas_signed
} 

else {
    Write-Output "[+] Metadata"
    Get-Item $target_saveas | Select VersionInfo | Format-List
    Write-Output "[+] Digital Signature"
    Write-Output "    Signature not added ... "
    Invoke-TimeStomp $source_binary_filepath $target_saveas
}

}
