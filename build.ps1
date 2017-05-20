$Global:ErrorActionPreference = 'Stop'
$Global:VerbosePreference = 'SilentlyContinue'

### Prepare NuGet / PSGallery
if (!(Get-PackageProvider | Where-Object { $_.Name -eq 'NuGet' })) {
    "Installing NuGet"
    Install-PackageProvider -Name NuGet -force | Out-Null
}
"Preparing PSGallery repository"
Import-PackageProvider -Name NuGet -force | Out-Null
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
}

### Install PSDepend
$psDepend = Get-Module -Name PSDepend -ListAvailable
if (!$psDepend) { 
    "Installing PSDepend"
    Install-Module PSDepend
} 
else {
    "Using PSDepend $($psDepend.Version)"
}

### Install build dependencies if required
$dependencies = Get-Dependency
$needInvokePSDepend = $false
foreach ($dep in $dependencies) {
    $moduleVersions = Get-Module -Name $dep.DependencyName -ListAvailable | `
        Select-Object -ExpandProperty Version | `
        Foreach-Object { "$($_.Major).$($_.Minor).$($_.Build)" }
    if (!($moduleVersions -contains $dep.Version)) {
        $needInvokePSDepend = $true
        break
    }
}
if ($needInvokePSDepend) { 
    "Installing build dependencies"
    Invoke-PSDepend -Force -Verbose
}

### Install project dependencies
$projectRequirementsFile = "$PSScriptRoot\..\requirements.psd1"
if (Test-Path -Path $projectRequirementsFile) {
  "Installing project dependencies"
  Invoke-PSDepend -Path $projectRequirementsFile -Force
}

### Run psake
"Setting build environment"
Set-BuildEnvironment -Path "$PSScriptRoot\.." -Force
"Starting psake build"
Invoke-psake -buildFile "$PSScriptRoot\psake.ps1" -nologo
exit ( [int]( -not $psake.build_success ) )
