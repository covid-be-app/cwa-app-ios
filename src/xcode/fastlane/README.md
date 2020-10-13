fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios update_licenses
```
fastlane ios update_licenses
```
Update license file
### ios build
```
fastlane ios build
```
Build project
### ios build_community
```
fastlane ios build_community
```
Build project (Community)
### ios lint
```
fastlane ios lint
```
Lint
### ios test
```
fastlane ios test
```
Run tests
### ios betaRelease
```
fastlane ios betaRelease
```
Build and upload for testing
### ios screenshots
```
fastlane ios screenshots
```

### ios productionRelease
```
fastlane ios productionRelease
```
Build and upload for App Store

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
