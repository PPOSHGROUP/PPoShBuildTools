$Global:ErrorActionPreference = 'Stop'
$Global:VerbosePreference = 'SilentlyContinue'

"Installing NuGet"
Install-PackageProvider -Name NuGet -force | Out-Null
Import-PackageProvider -Name NuGet -force | Out-Null
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

"Installing PSDepend"
Install-Module PSDepend
"Installing build dependencies"
Invoke-PSDepend -Force -Verbose

$projectRequirementsFile = "$PSScriptRoot\..\requirements.psd1"
if (Test-Path -Path $projectRequirementsFile) {
  "Installing additional dependencies"
  Invoke-PSDepend -Path $projectRequirementsFile -Force
}

"Setting build environment"
Set-BuildEnvironment -Path "$PSScriptRoot\.." -Force

"Starting psake build"
Invoke-psake -buildFile "$PSScriptRoot\psake.ps1" -nologo -Verbose:$VerbosePreference
exit ( [int]( -not $psake.build_success ) )