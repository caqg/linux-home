### -*- GDB-Script -*-

add-auto-load-safe-path /verifysys/SystemC-engine/BOM/.gdbinit

define ps
  set $i = 0
  while ($i < $argc)
    eval "print $arg%d.c_str()", $i
    set $i = $i + 1
  end
end
document ps
The arguments must be C++ strings; they are printed one to a line.
end

### end
