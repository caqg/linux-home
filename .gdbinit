### -*- GDB-Script -*-

set auto-load safe-path /
set print pretty
set print array
set print array-indexes
set print union
set print null-stop

define ps
  print ($arg0).c_str()
end
document ps
Prints (with newline) the argument, which must be a C++ string.
end

### end
