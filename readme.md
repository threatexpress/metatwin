# META TWIN

```
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
```

The project is designed as a file resource cloner.  Metadata, including digital signature, is extracted from one file and injected into another.
Note: The signature is added, but not valid.  

This project is based on a technique I've used for a few years.  This has been updated and modified to include copying digital signatures (thanks @subtee)

## Resources

 - Casey Smith (@subtee) MS Signed binary in 3 Steps - https://twitter.com/subTee/status/912769644473098240
 - Resource Hacker - http://www.angusj.com/resourcehacker/
 - SigThief - https://github.com/secretsquirrel/SigThief  (Included as a pyinstaller compiled binary)

## Install
 
 - Clone this project
 - Download and unzip Resource Hacker to .\src\resource_hacker\ResourceHacker.exe (http://www.angusj.com/resourcehacker/resource_hacker.zip)
 - Enjoy...

## Description

A version of this project has existed for several years to help a binary blend into a target environment by modifying it's metadata.  A binary's metadata can be replaced with the metadata of a source.  This includes values such as Product Name, Product Version, File Version, Copyright, etc.  In addition to standard metadata, sigthief is used to add the digital signature.  

## Usage

```
SYNOPSIS
    MetaTwin copies metadata from one file ane inject into another.

SYNTAX
    MetaTwin [-Source] <Object> [-Target] <Object> [-Sign] 

    Source     Source binary containing metadata and signature
    
    Target     Target binary that will be updated

    Sign       Optional setting that will add the source's digital signature   

```

## Example

```
c:> powershell -ep bypass
PS> Import-Module .\metatwin.ps1
PS> Invoke-MetaTwin -Source c:\windows\system32\netcfgx.dll -Target .\beacon.exe -Sign
```
