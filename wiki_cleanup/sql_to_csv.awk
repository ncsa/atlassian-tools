# data lines from mysql
/^[0-9]/ {gsub("\t", ","); print;}

# /^$/ {next;}
# /rows?\)/ {next;}
# /number of/ {next;}
# /^-----/ {next;}

# data lines from postgres
/\|/ {$2=","; print; next}
