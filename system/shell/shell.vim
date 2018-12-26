history | cut -c 8-
history | awk '{$1="";print substr($0,2)}'
history | sed 's/^[ ]*[0-9]\+[ ]*//'

alias history="history | sed 's/^[ ]*[0-9]\+[ ]*//'"
history | cut -d' ' -f4- | sed 's/^ \(.*$\)/\1/g'

