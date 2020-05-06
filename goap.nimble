# Package

version       = "0.1.0"
author        = "Joris Bontje"
description   = "General Purpose Goal Oriented Action Planning"
license       = "Apache"
srcDir        = "src"
bin           = @["game"]
skipDirs      = @["tests", "benchmarks"]
skipExt       = @["nim"]

# Dependencies

requires "nim >= 1.2.0"