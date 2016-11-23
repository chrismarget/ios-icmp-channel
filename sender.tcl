proc usage {} {
  global argv0
  puts "Usage: $argv0 \[-v <vrf> | -i <interface>\] <target> some message goes here"
}

# Takes string input (vrf) specifying the name of a VRF. Returns
# a string like "vrf foo" for use as argument to the ping command
# if the VRF exists, otherwise empty string.
proc get_ping_vrf_arg {vrf} {
  set cmd [concat "show running-config | include ^ip vrf " "$vrf$"]
  set result [string trimleft [exec $cmd]]
  if {![string length $result] } {
    return
  }
  set args [concat "vrf" $vrf]
  return $args
}

# Takes string input (i) specifying an interface. Shorthand names
# (gi1/0/3.275) okay. Returns a string like
# "interface GigabitEthernet 0/1/3.275" if the interface exists
# otherwise empty an string.
proc get_ping_int_arg {i} {
  set cmd "show running-config interface $i"
  set result [exec $cmd]
  foreach line [split $result "\n"] {
    if {[regexp {^interface } $line]} {
      set int [lindex $line 1]
    }
  }
  if {![info exists int]} {
    return
  }
  return [concat "source" $int]
}

# Returns 1 if the cli arguments are okay, otherwise 0
proc validate_cli_args {} {
  global argc
  global argv
  if {![llength $argv]} {
    return 0
  }
  if {[string range [lindex $argv 0] 0 0] == "-"} {
    set minargs 4
  } else {
    set minargs 2
  }
  if {$argc < 4} {
    return 0
  }
  return 1
}

# Takes as input a string (cmd) which is a ping command. Sends pings
# over and over until max_loops or until ping says "Success rate
# is 100 percent" Returns 1 on success, 0 on failure.
proc ping_until_reply {cmd} {
  set keep_going 1
  set loop_count 0
  set max_loops 10
  while {$keep_going} {
    incr loop_count
    set result [exec $cmd]
    if {[regexp {Success rate is 100 percent} $result]} {
      set keep_going 0
      return 1
    }
    if {$loop_count >= $max_loops} {
      set keep_going 0
      return 0
    }
  }
}

# Takes string input (int) specifying the name of an interface. Returns
# a string like "vrf foo" for use as argument to the ping command
# if the VRF exists, otherwise empty string.
proc find_interface_vrf {int} {
  set cmd "show running-config interface $int"
  set result [exec $cmd]
  foreach line [split $result "\n"] {
    if {[regexp {^ ip vrf forwarding } $line]} {
      return [concat "vrf" [lindex $line 3]]
    }
  }
}

if {![validate_cli_args]} {
  usage
  return
}

# Did user say "-i" to specify an interface?
if {[lindex $argv 0] == "-i"} {
  set int [lindex $argv 1]
  set int_arg [get_ping_int_arg $int]
  if {![string length $int_arg]} {
    usage
    return
  }
  set vrf_arg [find_interface_vrf $int]
  set target [lindex $argv 2]
  set message [lreplace $argv 0 2]
# Did user say "-v" to specify a VRF?
} elseif {[lindex $argv 0] == "-v"} {
  set vrf [lindex $argv 1]
  set int_arg ""
  set vrf_arg [get_ping_vrf_arg $vrf]
  if {![string length $vrf_arg]} {
    usage
    return
  }
  set target [lindex $argv 2]
  set message [lreplace $argv 0 2]
# User specified no extra ping arguments
} else {
  set ping_options ""
  set target [lindex $argv 0]
  set message [lreplace $argv 0 0]
}

# Send the pings. One byte of payload in each ping, but send two bytes.
# First byte is zero-indexed sequence number. Second byte is ASCII value
# of the payload.
set i 0
while {$i < [string length $message]} {
  set b1 [format %02X $i]
  set b2 [format %02X [scan [string index $message $i] %c]]
  incr i
  exec [concat "ping" $vrf_arg $target $int_arg "repeat 1 size 38 data" $b1$b2]
}

# Send EOM (ASCII 4) as the last ping.
set b1 [format %02X $i]
set b2 [format %02X 4]
exec [concat "ping" $vrf_arg $target $int_arg "repeat 1 size 38 data" $b1$b2]
