fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build_and_test

```sh
[bundle exec] fastlane ios build_and_test
```

Build and test the app in simulator

### ios build_and_upload_dsyms

```sh
[bundle exec] fastlane ios build_and_upload_dsyms
```

Build app for release and upload debug symbols to Sentry

### ios build_and_upload_to_sentry

```sh
[bundle exec] fastlane ios build_and_upload_to_sentry
```

Build app and upload complete build to Sentry

### ios test_sentry_config

```sh
[bundle exec] fastlane ios test_sentry_config
```

Test Sentry configuration without building

### ios test_dsym_upload

```sh
[bundle exec] fastlane ios test_dsym_upload
```

Test dSYM upload with existing build

### ios ad_automation

```sh
[bundle exec] fastlane ios ad_automation
```

Run ad performance automation

### ios continuous_ad_testing

```sh
[bundle exec] fastlane ios continuous_ad_testing
```

Run continuous ad testing for Sentry data generation

### ios sentry_report

```sh
[bundle exec] fastlane ios sentry_report
```

Generate Sentry performance report

### ios ci_setup

```sh
[bundle exec] fastlane ios ci_setup
```

Setup for CI/CD

### ios ci_build

```sh
[bundle exec] fastlane ios ci_build
```

CI/CD build with Sentry build upload

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
