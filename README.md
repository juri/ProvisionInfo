# provision-info

![Swift build status](https://github.com/juri/provision-info/actions/workflows/build.yml/badge.svg)

A Swift library and a tool for viewing provisioning profiles.

## Overview

`provision-info` is a Swift package. It provides two parts:

- The `ProvisionInfoKit` library
- The `provision-info` command line tool

Their purpose is parsing and displaying info about provisioning profiles used in development on the Apple platforms.
They use the [Security][security-framework] framework which means they don't work on non-Apple platforms.

[security-framework]: https://developer.apple.com/documentation/Security

## License

Licensed under the Apache License, Version 2.0. You can find a copy
of the license in this repository in the file LICENSE.
