# Package

version = "0.2.0"
author = "Christine Dodrill"
description = ".i le mi nundambysince"
license = "0BSD"
srcDir = "src"
binDir = "bin"
bin = @["since"]

let testFiles = @[
  "battlesnake",
  "pathing",
]

# Dependencies

requires "nim >= 1.6.0", "jester >= 0.5.0", "astar >= 0.6.0"

task test, "run tests":
  echo "running tests..."
  withDir "src/sincePkg":
    for tf in testFiles:
      exec "nim c --hints:off --verbosity:0 -r " & tf
      rmFile tf.toExe
