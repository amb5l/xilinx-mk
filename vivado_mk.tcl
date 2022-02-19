################################################################################
## vivado_mk.tcl                                                              ##
## Helper script for using makefiles with Xilinx Vivado.                      ##
################################################################################
## (C) Copyright 2022 Adam Barnes <ambarnes@gmail.com>                        ##
## This file is part of xilinx-mk. xilinx-mk is free software: you can        ##
## redistribute it and/or modify it under the terms of the GNU Lesser General ##
## Public License as published by the Free Software Foundation, either        ##
## version 3 of the License, or (at your option) any later version.           ##
## xilinx-mk is distributed in the hope that it will be useful, but WITHOUT   ##
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or      ##
## FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public        ##
## License for more details. You should have received a copy of the GNU       ##
## Lesser General Public License along with xilinx-mk. If not, see            ##
## https://www.gnu.org/licenses/.                                             ##
################################################################################

proc error_exit {msgs} {
    puts stderr "********************************************************************************"
    puts stderr "vivado_mk.tcl: ERROR - details to follow..."
    foreach msg $msgs {
        puts stderr $msg
    }
    exit 1
}

proc attempt {cmd} {
    if {[catch {eval $cmd} msg]} {
        error_exit $cmd $msg
    }
}

proc params_to_dict {p} {
    set d [dict create]
    while (1) {
        while (1) {
            set key [lindex $p 0]
            set c [string index $key end]
            if {$c == ""} {
                break
            }
            set p [lrange $p 1 end]
            if {$c == ":"} {
                set key [string range $key 0 end-1]
                break
            }
        }
        if {$key == ""} {
            break
        }
        set values []
        while (1) {
            set c [string index [lindex $p 0] end]
            if {$c == "" || $c == ":"} {
                break
            } else {
                lappend values [lindex $p 0]
                set p [lrange $p 1 end]
            }
        }
        if {[llength $values] > 0} {
            foreach value $values {
                dict lappend d $key $value
            }
        }
    }
    return $d
}

set args $argv
set proj_dir [lindex $args 0]
set proj_name [lindex $args 1]
set cmd [lindex $args 2]
set args [lrange $args 3 end]
switch $cmd {

    create {
        # create proj_lang fpga_part [[cat: cat_items] [cat: cat_items]...]
        set proj_lang [lindex $args 0]
        set fpga_part [lindex $args 1]
        set args [lrange $args 2 end]
        set d [params_to_dict $args]
        file mkdir $proj_dir
        cd ./$proj_dir
        attempt "create_project -part $fpga_part -force $proj_name"
        attempt "set_property target_language $proj_lang \[get_projects $proj_name\]"
        set_property -name "target_language" -value "VHDL" -objects [current_project]
        if {[dict exist $d dsn_vhdl]} {
            attempt "add_files -norecurse -fileset \[get_filesets sources_1\] [dict get $d dsn_vhdl]"
            set d [dict remove $d dsn_vhdl]
        }
        if {[dict exist $d dsn_vhdl_2008]} {
            set_property -name "enable_vhdl_2008" -value "1" -objects [current_project]
            attempt "add_files -norecurse -fileset \[get_filesets sources_1\] [dict get $d dsn_vhdl_2008]"
            attempt "set_property file_type \"VHDL 2008\" \[get_files -of_objects \[get_filesets sources_1\] {[dict get $d dsn_vhdl_2008]}\]"
            set d [dict remove $d dsn_vhdl_2008]
        }
        if {[dict exist $d dsn_xdc]} {
            attempt "add_files -norecurse -fileset \[get_filesets constrs_1\] [dict get $d dsn_xdc]"
            attempt "set_property used_in_synthesis true \[get_files -of_objects \[get_filesets constrs_1\] {[dict get $d dsn_xdc]}\]"
            attempt "set_property used_in_implementation true \[get_files -of_objects \[get_filesets constrs_1\] {[dict get $d dsn_xdc]}\]"
            set d [dict remove $d dsn_xdc]
        }
        if {[dict exist $d dsn_xdc_synth]} {
            attempt "add_files -norecurse -fileset \[get_filesets constrs_1\] [dict get $d dsn_xdc_synth]"
            attempt "set_property used_in_synthesis true \[get_files -of_objects \[get_filesets constrs_1\] {[dict get $d dsn_xdc_synth]}\]"
            attempt "set_property used_in_implementation false \[get_files -of_objects \[get_filesets constrs_1\] {[dict get $d dsn_xdc_synth]}\]"
            set d [dict remove $d dsn_xdc_synth]
        }
        if {[dict exist $d dsn_xdc_impl]} {
            attempt "add_files -norecurse -fileset \[get_filesets constrs_1\] [dict get $d dsn_xdc_impl]"
            attempt "set_property used_in_synthesis false \[get_files -of_objects \[get_filesets constrs_1\] {[dict get $d dsn_xdc_impl]}\]"
            attempt "set_property used_in_implementation true \[get_files -of_objects \[get_filesets constrs_1\] {[dict get $d dsn_xdc_impl]}\]"
            set d [dict remove $d dsn_xdc_impl]
        }
        if {[dict exist $d dsn_top]} {
            attempt "set_property top [lindex [dict get $d dsn_top] 0] \[get_filesets sources_1\]"
            set d [dict remove $d dsn_top]
        }
        if {[dict exist $d dsn_gen]} {
            set g [dict get $d dsn_gen]
            set s "set_property generic {"
            while {[llength $g] >= 2} {
                append s "[lindex $g 0]=[lindex $g 1] "
                set g [lrange $g 2 end]
            }
            append s "} \[get_filesets sources_1\]"
            attempt $s
            set d [dict remove $d dsn_gen]
        }        
        if {[dict exist $d sim_vhdl]} {
            attempt "add_files -norecurse -fileset \[get_filesets sim_1\] [dict get $d sim_vhdl]"
            set d [dict remove $d sim_vhdl]
        }
        if {[dict exist $d sim_vhdl_2008]} {
            attempt "add_files -norecurse -fileset \[get_filesets sim_1\] [dict get $d sim_vhdl_2008]"
            attempt "set_property file_type \"VHDL 2008\" \[get_files -of_objects \[get_filesets sim_1\] {[dict get $d sim_vhdl_2008]}\]"
            set d [dict remove $d sim_vhdl_2008]
        }
        if {[dict exist $d sim_top]} {
            attempt "set_property top [lindex [dict get $d sim_top] 0] \[get_filesets sim_1\]"
            set d [dict remove $d sim_top]
        }
        if {[dict exist $d sim_gen]} {
            set g [dict get $d sim_gen]
            set s "set_property generic {"
            while {[llength $g] >= 2} {
                append s "[lindex $g 0]=[lindex $g 1] "
                set g [lrange $g 2 end]
            }
            append s "} \[get_filesets sim_1\]"
            attempt $s
            set d [dict remove $d sim_gen]
        }                
        if {[llength [dict keys $d]]} {
            error_exit "create - leftovers: $d"
        }
    }

    build {
        # build target ...
        set target [lindex $args 0]
        cd ./$proj_dir
        open_project $proj_name
        switch $target {
            ip {
                # build ip tcl_file [simulation models]
                set xci_file [lindex $args 1]
                set tcl_file [lindex $args 2]
                set args [lrange $args 3 end]
                if {$xci_file in [get_files $xci_file]} {
                    remove_files $xci_file
                }
                source $tcl_file
                if {[llength $args] > 0} {
                    attempt "add_files -norecurse -fileset \[get_filesets sim_1\] $args"
                }
            }
            bd {
                # build bd bd_file tcl_file
                set bd_file [lindex $args 1]
                set tcl_file [lindex $args 2]
                if {$bd_file in [get_files $bd_file]} {
                    remove_files $bd_file
                }
                source $tcl_file
            }
            hwdef {
                # build hwdef filename
                set filename [lindex $args 1]
                attempt "generate_target all \[get_files -of_objects \[get_filesets sources_1\] $filename\]"
            }
            xsa {
                # build xsa
                set top [get_property top [get_filesets sources_1]]
                attempt "write_hw_platform -fixed -force -file $top.xsa"
            }
            synth {
                # build synth jobs
                set jobs [lindex $args 1]
                attempt "reset_run synth_1"
                attempt "launch_runs synth_1 -jobs $jobs"
                attempt "wait_on_run synth_1"
                if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
                    error_exit {"synthesis did not complete"}
                }
            }
            impl {
                # build impl jobs [proc_inst proc_ref proc_elf]
                set jobs [lindex $args 1]
                if {[llength $args] >= 3} {
                    set proc_inst [lindex $args 2]
                }
                if {[llength $args] >= 4} {
                    set proc_ref [lindex $args 3]
                }
                if {[llength $args] >= 5} {
                    set proc_elf [lindex $args 4]
                    if {[llength [get_files -all -of_objects [get_fileset sources_1] $proc_elf]] == 0} {
                        attempt "add_files -norecurse -fileset \[get_filesets sources_1\] $proc_elf"
                        attempt "set_property SCOPED_TO_REF $proc_ref \[get_files -of_objects \[get_filesets sources_1\] $proc_elf\]"
                        attempt "set_property SCOPED_TO_CELLS $proc_inst \[get_files -of_objects \[get_filesets sources_1\] $proc_elf\]"
                    }
                }
                attempt "reset_run impl_1"
                attempt "launch_runs impl_1 -jobs $jobs"
                attempt "wait_on_run impl_1"
                if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
                    error_exit {"implementation did not complete"}
                }
            }
            bit {
                # build bit filename
                set filename [lindex $args 1]
                attempt "open_run impl_1"
                attempt "write_bitstream -force \"$filename\""
            }
            bd_tcl {
                # update bd_tcl tcl_file bd_file
                set tcl_file [lindex $args 1]
                set bd_file [lindex $args 2]
                open_bd_design $bd_file
                attempt "write_bd_tcl -force -include_layout $tcl_file"
            }
            bd_svg {
                # update bd_svg svg_file bd_file
                set svg_file [lindex $args 1]
                set bd_file [lindex $args 2]
                open_bd_design $bd_file
                attempt "write_bd_layout -force -format svg $svg_file"
            }
            default {
                error_exit {"build - unknown target ($target)"}
            }
        }
    }

    prog {
        # prog file
        set file [lindex $args 0]
        open_hw
        connect_hw_server
        current_hw_target [lindex [get_hw_targets] 0]
        open_hw_target
        current_hw_device [lindex [get_hw_devices] 0]
        set_property PROGRAM.FILE $file [current_hw_device]
        program_hw_devices [current_hw_device]
    }

    simulate {
        # simulate [gen: generic value] [elf: proc_inst proc_ref proc_elf]
        set d [params_to_dict $args]
        cd ./$proj_dir
        open_project $proj_name
        if {[dict exist $d gen]} {
            set g [dict get $d gen]
            set s "set_property generic {"
            while {[llength $g] >= 2} {
                append s "[lindex $g 0]=[lindex $g 1] "
                set g [lrange $g 2 end]
            }
            append s "} \[get_filesets sim_1\]"
            attempt $s
        }
        if {[dict exist $d elf]} {
            set proc_inst [lindex [dict get $d elf] 0]
            set proc_ref [lindex [dict get $d elf] 1]
            set proc_elf [lindex [dict get $d elf] 2]
            if {[llength [get_files -all -of_objects [get_fileset sim_1] $proc_elf]] == 0} {
                add_files -norecurse -fileset \[get_filesets sim_1\] $proc_elf
                set_property SCOPED_TO_REF $proc_ref [get_files -all -of_objects [get_fileset sim_1] $proc_elf]
                set_property SCOPED_TO_CELLS { $proc_inst } [get_files -all -of_objects [get_fileset sim_1] $proc_elf]
            }
        }
        attempt "launch_simulation"
        set t_start [clock seconds]
        attempt "run all"
        set t_end [clock seconds]
        set elapsed_time [expr {$t_end-$t_start}]
        puts "elapsed time == $elapsed_time"
    }

    default {
        error_exit "unknown command: $cmd"
    }

}
exit
