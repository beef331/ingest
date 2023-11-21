# Package

version       = "0.1.0"
author        = "Jason Beetham"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["ingest"]


# Dependencies

requires "nim >= 2.0.0"
requires "owlkettle#head"
requires "frosty >= 3.0.0"
requires "slicerator >= 0.3.3"
