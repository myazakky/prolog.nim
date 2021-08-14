# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import interpreter

when isMainModule:
  echo "Prolog.nim"
  var i: Interpreter
  i.run
