#!/usr/bin/env tclsh
package require Tk;

set CONFIG_FILE "system_monitor.conf" ;#Configuration file

#Configuration: Set Thresholds for alerts
set CPU_THRESHOLD 80; #CPU usage threshold in percentage
set MEMORY_THRESHOLD 90;# Memory usage threshold in percentage
set DISK_THRESHOLD 90; #Disk usage threshold in percentagge


# Log file
set LOG_FILE "system_monitor.log"

# Load configuration fromfile
proc load_config {} {
	global CONFIG_FILE CPU_THRESHOLD MEMORY_THRESHOLD DISK_THRESHOLD
	if {[file exists $CONFIG_FILE]} {
		source $CONFIG_FILE
	} else {
		puts "Config file not found. Using default settings."
	}
}

# Procedure to get CPU usage
proc get_cpu_usage {} {
	set total_usage 0
	if {[catch {exec cat /proc/stat} cpu_info]} {
		puts "Error reading /proc/stat"
		return 0
	}
	set lines [split $cpu_info "\n"]
	foreach line $lines {
		if {[string match "cpu *" $line]} {
			set values [regexp -all -inline {\d+} $line]
			set user [lindex $values 0]
			set nice [lindex $values 1]
			set system [lindex $values 2]
			set idle [lindex $values 3]
			set total [expr {$user + $nice + $system + $idle}]
			set usage [expr {100 - ($idle * 100.0 / $total)}]
			return [format "%.2f" $usage]
		}
	}
	return 0
}

# Procedure to get memory usage
proc get_memory_usage {} {
	if {[catch {exec cat /proc/meminfo} mem_info]} {
		puts "Error reading /proc/meminfo"
		return 0
	}
	# set mem_info [exec cat /proc/meminfo]
	set total_memory [lindex [regexp -inline {MemTotal:\s+(\d+)} $mem_info] 1]
	set available_memory [lindex [regexp -inline {MemAvailable:\s+(\d+)} $mem_info] 1]
	set used_memory [expr {$total_memory - $available_memory}]
	set memory_usage [expr {($used_memory * 100.0) / $total_memory}]
	return [format "%.2f" $memory_usage]
}

#Procedure to get disk usage
proc get_disk_usage {} {
	if {[catch {exec df -h /} disk_info]} {
		puts "Error running df command"
		return 0
	}
	# set disk_info [exec df -h /]
	set usage_line [lindex [split $disk_info "\n"] 1]
	set usage [lindex [regexp -inline {\d+%} $usage_line] 0]
	return [string trim $usage "%"]
}

# Function to log data 
proc log_data {cpu_usage memory_usage disk_usage} {
	global LOG_FILE
	set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
	set log_entry "Stimestamp - CPU: $cpu_usage%, Memory: $memory_usage%, Disk: $disk_usage%"
	if {[catch {open $LOG_FILE a} log_fd]} {
		puts "Error opening log file: $log_fd"
	} else {
		puts $log_fd $log_entry
		close $log_fd
	}
}

# Procedure to check thresholds and trigger alerts
proc check_thresholds {cpu_usage memory_usage disk_usage} {
	global CPU_THRESHOLD MEMORY_THRESHOLD DISK_THRESHOLD

	if {$cpu_usage >= $CPU_THRESHOLD} {
		puts "ALERT: CPU usage is above threshold: $cpu_usage%"
	}
	if {$memory_usage >= $MEMORY_THRESHOLD} {
		puts "ALERT: Memory usage is above threshold:$memory_usage%"
	}
	if {$disk_usage >= $DISK_THRESHOLD} {
		puts "ALERT: Disk usage is above threshold:$disk_usage%"
	}
}

#Graphical Interface
proc create_gui {} {
	global cpu_label memory_label disk_label
	puts "Creating GUI..."
	toplevel .monitor
	wm geometry .monitor 400x200; #Set Window size
	wm title .monitor "System Monitor"
	label .monitor.cpu_label -text "CPU Usage: 0.00%" -font {Arial 12} -foreground black -background white
	label .monitor.memory_label -text "Memory Usage: 0.00%" -font {Arial 12} -foreground black -background white
	label .monitor.disk_label -text "Disk Usage: 0.00%" -font {Arial 12} -foreground black -background white
	puts "Label widgets created."
	pack .monitor.cpu_label .monitor.memory_label .monitor.disk_label -side top -padx 20 -pady 10
	puts "GUI created successfully."
	update;#Force the event loop to update
}

#Update GUI with current usage
proc update_gui {cpu_usage memory_usage disk_usage} {
	global cpu_label memory_label disk_label
	.monitor.cpu_label configure -text "CPU Usage: $cpu_usage%"
	.monitor.memory_label configure -text "Memory Usage: $memory_usage%"
	.monitor.disk_label configure -text "Disk Usage: $disk_usage%"
}

# Main monitoring procedure loop
proc monitor_system {} {
	create_gui
	update_gui  0 0 0;#Initializing with dummy values
	after 1000 update_monitor;#Start the monitoring loop after 1 second
}

proc update_monitor {} {
	set cpu_usage [get_cpu_usage]
	set memory_usage [get_memory_usage]
	set disk_usage [get_disk_usage]

	puts "CPU Usage: $cpu_usage%"
	puts "Memory Usage: $memory_usage%"
	puts "Disk Usage: $disk_usage%"
	puts "------------------------"

	log_data $cpu_usage $memory_usage $disk_usage
	check_thresholds $cpu_usage $memory_usage $disk_usage
	update_gui $cpu_usage $memory_usage $disk_usage

	after 5000 update_monitor; #Wait for 5 seconds before the next iteration
}


load_config
monitor_system
