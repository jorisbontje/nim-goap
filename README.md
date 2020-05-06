# General Purpose Goal Oriented Action Planning

[![License: Apache](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![Stability: experimental](https://img.shields.io/badge/stability-experimental-orange.svg)

## Rationale
* NIM port of General Purpose Goal Oriented Action Planning: https://github.com/stolk/GPGOAP
* More about Goal-Oriented Action Planning (GOAP): http://alumni.media.mit.edu/~jorkin/goap.html

## Building & Testing

### Prerequisites

* A recent version of Nim
  * We use version 1.20 of https://nim-lang.org/
  * Follow the Nim installation instructions or use [choosenim](https://github.com/dom96/choosenim) to manage your Nim versions

### Build & Install

We use [Nimble](https://github.com/nim-lang/nimble) to manage dependencies and run tests.

To build and install GOAP in your home folder, just execute:

```bash
nimble install
```

After a succesful installation, running `game` will start the test game.

To execute all tests:
```bash
nimble test
```


## License

Licensed under the following:

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
