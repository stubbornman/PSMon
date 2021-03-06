function Get-Monitoring{
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    BEGIN{
        Write-Verbose "[$(Get-Date)] $($MyInvocation.MyCommand) has started"

        Write-Verbose "Setting up variables"
        $results = @{}
        if($PSMon.ComputerName -ne $ComputerName){
            $PSMon.ComputerName = $ComputerName
        }

        Write-Verbose "Getting function defaults"
        if(Test-Path $PSMon.ConfigFile){
            [xml]$xmlConfig = Get-Content $PSMon.ConfigFile
            $FreeSpaceConfig = $xmlConfig.Configuration.Function | Where-Object {$_.ID -eq "Get-PSMonFreeSpace"}
            $ProcessorConfig = $xmlConfig.Configuration.Function | Where-Object {$_.ID -eq "Get-PSMonProcessor"}
            $WorkingSetConfig = $xmlConfig.Configuration.Function | Where-Object {$_.ID -eq "Get-PSMonWorkingSet"}
        } else{
            Write-Error "Config file not found. Run 'Install-Monitoring -Repair' to correct."
            $flag = -1
        }
    }

    PROCESS{
        Write-Verbose "Getting PSMon information"
        if([string]::IsNullOrEmpty($flag)){
            try{
                $FreeSpace = Get-FreeSpace -WarningThreshold $FreeSpaceConfig.WarningThreshold -ErrorThreshold $FreeSpaceConfig.ErrorThreshold
                $Processor = Get-Processor -WarningThreshold $ProcessorConfig.WarningThreshold -ErrorThreshold $ProcessorConfig.ErrorThreshold
                $WorkingSet = Get-WorkingSet -WarningThreshold $WorkingSetConfig.WarningThreshold -ErrorThreshold $WorkingSetConfig.ErrorThreshold

                $results.Add('FreeSpace',$FreeSpace)
                $results.Add('Processor',$Processor)
                $results.Add('WorkingSet',$WorkingSet)
                $results.Add('Collected',$(Get-Date))
                $results.Add('ComputerName',$env:COMPUTERNAME)
            }
            catch{
                Write-Error "$($PSItem.ToString)"
                $flag = -1
            }
        }
    }

    END{
        Write-Verbose "[$(Get-Date)] $($MyInvocation.MyCommand) has completed"
        if($flag){
            return -1
        }
        switch($PSMon.DefaultOutput){
            "pscustomobject"{
                return [pscustomobject]$results
            }
            "XML"{
                return [pscustomobject]$results | ConvertTo-XML
            }
            "HTML"{
                return [pscustomobject]$results | ConvertTo-Html
            }
            default{
                return $results
            }
        }
    }
}