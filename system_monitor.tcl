package require Tclx;

#Configuration: Set Thresholds for alerts
set CPU_THRESHOLD 80; #CPU usage threshold in percentage
set MEMORY_THRESHOLD 90;# Memory usage threshold in percentage
set DISK_THRESHOLD 90; #Disk usage threshold in percentagge

# Procedure to get CPU usage
proc get_cpu_usuage {} {
	set total_usage 0
	set cpu_info [exec cat /proc/stat]
	set lines [split $cpu_info "\n"]
	foreach line $lines {
		if {[string match "cpu *" $line]} {
			set values [regexp -all -inline {\d+} $line]
			set user [lindex $values 0]
			set nice [lindex $values 1]
			set system [lindex $values 2]
			set idle [lindex $values 3]
			set total [expr {$user + $nice + $system + $idele}]
			set usage [expr {100 - ($idle * 100.0 / $total)}]
			return [format "%.2f" $usage]
		}
	}
	return 0
}

# Procedure to get memory usage
proc get_memory_usage {} {
	set mem_info [exec cat /proc/meminfo]
	set total_memory [lindex [regexp -inline {MemTotal:\s+(\d+)} $mem_info] 1]
	set available_memory [lindex [regexp -inline {MemAvailable:\s+(\d+)} $mem_info] 1]
	set used_memory [expr {$total_memory - $available_memory}]
	set memory_usage [expr {($used_memory * 100.0) / $total_memory}]
	return [format "%.2f" $memory_usage]
}
