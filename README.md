# PPoShBuildTools
Common PPoSh build scripts based on PSDepend, PSake and AppVeyor

## Using build tools in a new repository

1. Create a repository with single Powershell module (YourModuleName) and following structure:
```
Build <-- submodule (see point 2)
YourModuleName
  YourModuleName.psd1
  YourModuleName.psm1
  ...
Tests <-- optional, put your Pester tests here
```
2. Add a git submodule in folder `Build` pointing to `PPoshBuildTools` repository (`https://github.com/PPOSHGROUP/PPoShBuildTools.git`).
3. Create a new AppVeyor project pointing to your repository and change following settings:
    * Build version format -> change it from `1.0.0.{build}` to `{build}`
    * Custom configuration .yml file name -> put `https://raw.githubusercontent.com/PPOSHGROUP/PPoShBuildTools/master/appveyor.yml`
4. That's it, every commit to your repository will trigger a build that packages your module and runs tests and static code analysis. When you create a tag, it will also be published to Powershell Gallery (with version = tag name). 
5. Remember to check `Include tags` during push (after tagging) and 'Recursive' during first pull.

If you have any issues, look at a working example at [PPoShTools repository](https://github.com/PPOSHGROUP/PPoShTools).
