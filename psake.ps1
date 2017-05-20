# Properties passed from command line
Properties {   
}

# Common variables
$ProjectRoot = $ENV:BHProjectPath
if (-not $ProjectRoot) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}

$Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
$TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
$lines = '----------------------------------------------------------------------'

# Tasks

Task Default -Depends Build

Task Init {
    $lines
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"
}

Task Test -Depends Init  {
    $lines
    
    if (!(Test-Path -Path $ProjectRoot\Tests)) {
      return
    }
    
    $PSVersion = $PSVersionTable.PSVersion.Major
    "Running Pester tests with PowerShell $PSVersion"

    $TestResults = Invoke-Pester -Path $ProjectRoot\Tests -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile"

    if ($ENV:BHBuildSystem -eq 'AppVeyor') {
        (New-Object 'System.Net.WebClient').UploadFile(
            "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
            "$ProjectRoot\$TestFile" )
    }

    Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Build -Depends StaticCodeAnalysis, Test {
    $lines
    
    # Import-Module to check everything's ok
    $buildDetails = Get-BuildVariables
    $projectName = Join-Path ($BuildDetails.ProjectPath) (Get-ProjectName)
    Import-Module -Name $projectName -Force
    
    if ($ENV:BHBuildSystem -eq 'AppVeyor') {
      "Updating module psd1 - FunctionsToExport"
      Set-ModuleFunctions

      # Bump the module version
      if ($ENV:PackageVersion) { 
        "Updating module psd1 version to $($ENV:PackageVersion)"
        Update-Metadata -Path $env:BHPSModuleManifest -Value $ENV:PackageVersion
      } 
      else {
        "Not updating module psd1 version - no env:PackageVersion set"
      }
    #}
}

Task StaticCodeAnalysis {
    if ($ENV:BHBuildSystem -eq 'AppVeyor') {
        Add-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Running
    }
    "Running PSScriptAnalyzer"
    $Results = Invoke-ScriptAnalyzer -Path $ProjectRoot -Recurse -Settings "$PSScriptRoot\PPoShScriptingStyle.psd1"
    if ($Results) {
        $ResultString = $Results | Out-String
        Write-Warning $ResultString
        if ($ENV:BHBuildSystem -eq 'AppVeyor') {
            Add-AppveyorMessage -Message "PSScriptAnalyzer output contained one or more result(s) with 'Error' severity.`
            Check the 'Tests' tab of this build for more details." -Category Error
            Update-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Failed -ErrorMessage $ResultString
        }
         
        throw "Build failed"
    } 
    else {
        If ($ENV:BHBuildSystem -eq 'AppVeyor') {
            Update-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Passed
        }
    }
}