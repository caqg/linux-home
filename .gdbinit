### -*- GDB-Script -*-

set auto-load safe-path /
set print pretty
set print array
set print array-indexes
set print union
set print null-stop

# define ps
#   set $i = 0
#   while ($i < $argc)
#     print $i
#     eval "echo print ($arg%d).c_str()", $i
#     set $i = $i + 1
#   end
# end
# document ps
# The arguments must be C++ strings; they are printed one to a line.
# end

define ps
  print ($arg0).c_str()
end
document ps
Prints (with newline) the argument, which must be a C++ string.
end

### end
