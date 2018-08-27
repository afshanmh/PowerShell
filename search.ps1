Param(
    [Parameter(Mandatory = $false)]
    [switch] $R=$true,     #Recursive searche which will go into subfolders 

    [Parameter(Mandatory = $false)]
    [ValidateScript( {Test-Path $_})]
    [String] $path="D:\Development\epo_nimbus\branches\cirrusSDU\082120182328\PP\content\AH",

    [Parameter(Mandatory=$false)]
    [String] $fileName='*1028.mst*',

    [Parameter(Mandatory=$false)]
    [String] $phrase

)

$ErrorActionPreference = 'Stop'

Trap {
    Write-Host -log -message "$($_.Exception | Format-List -Force | Out-String )"
    $formatList = $_ | Format-List * -Force
    
    $erroInfo = "`r`nError: Line# $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.ScriptName)" + "$($_.Exception | Format-List -Force | Out-String )"
    
    $ExceptReion = $_.Exception
    for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
    {   "$i" * 80
        $Exception |Format-List * -Force
    }
    if ( $PSVersionTable.PSVersion.Major -ge 5 ) {
        throw $erroInfo
    }
    else {
    Write-Host  "Powershell version is $($PSVersionTable.PSVersion).Please upgrade to a version 5 or above...."

        exit 1
    }
}

function WildcardToRegex {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ref] $wildCard
    )
    $wildCard = "^"+ ($wildCard.replace('*','.*')).replace('?','.') +"$"
}

function SearchForFileNameRecursively {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String] $path
    )
    $items = Get-ChildItem -Path $path -Recurse -File
    foreach($item in $items){
        $ext = ([IO.Path]::GetExtension($item.name)).tolower()
        switch ($ext) {
            {($_ -eq '.zip') -or ($_ -eq '.cab')}
            {
                if($item.name -like $fileName) {
                    "Found this file name matched: $($item.FullName)"   #zip filename itself matched
                    return
                }
                $newPath = "$($script:workspace)\"+$($item.name).replace('.', '_')      #replacing . with _ , so the directory name is less confusing

                if($ext -eq '.zip') {
                    Expand-Archive -Path $path"\$($item.name)" -DestinationPath $newPath
                }
                else {
                    New-Item -path $newPath -ItemType "directory" -Force
                    &expand.exe -F:*  $path"\$($item.name)" $newPath   #expanding all files in the .cab file
                }
                
                SearchForFileNameRecursively -path $newPath 
                return
            }
            {($_ -eq '.txt') -or ($_ -eq '.text') -or ($_ -eq '.csv') -or ($_ -eq '.log')  -or ($_ -eq '.xml') -or ($_ -eq '.http') }
            {
                "will need to read the content of $($item.name) "
            }

            Default { Write-Warning "Ignoring this file: $($item.name) "}
        }

    }
    
}

function SearchFileContent {

}

function Init {
    Clear-Host
    Add-Type -AssemblyName 'system.io.compression.filesystem'
    $script:workspace = (Get-Content env:temp) +'\'+ (Split-Path -leaf -Path $PSCommandPath).replace('.', '_')
    if(Test-Path -Path $script:workspace ) {
        Remove-Item $script:workspace\* -Force -Recurse
    }


}

function Main {
    Init

    if($true -eq $R) {
        if ( -not [String]::IsNullOrEmpty($fileName)) {
            SearchForFileNameRecursively -path $path
        }
    }
    else {

    }
}

Main



