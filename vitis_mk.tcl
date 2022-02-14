################################################################################
## vitis_mk.tcl                                                               ##
## Helper script for using makefiles with Xilinx Vitis.                       ##
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

package require fileutil

proc error_exit {msgs} {
    puts stderr "********************************************************************************"
    puts stderr "vitis_mk.tcl: ERROR - details to follow..."
    foreach msg $msgs {
        puts stderr $msg
    }
    exit 1
}

set args $argv
set proj_dir [lindex $args 0]
set app_name [lindex $args 1]
set cmd [lindex $args 2]
set args [lrange $args 3 end]
switch $cmd {

    create {
        # create xsa_file proc [cat: cat_items]
        set xsa_file [lindex $args 1]
        set proc [lindex $args 2]
        set args [lrange $args 3 end]
        set d [dict create]
        while (1) {
            while (1) {
                set key [lindex $args 0]
                set c [string index $key end]
                if {$c == ""} {
                    break
                }
                set args [lrange $args 1 end]
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
                set c [string index [lindex $args 0] end]
                if {$c == "" || $c == ":"} {
                    break
                } else {
                    lappend values [lindex $args 0]
                    set args [lrange $args 1 end]
                }
            }
            if {[llength $values] > 0} {
                foreach value $values {
                    dict lappend d $key $value
                }
            }
        }
        file mkdir $proj_dir
        setws ./$proj_dir
        cd ./$proj_dir
        app create -name $app_name -hw $xsa_file -os standalone -proc $proc -template {Empty Application(C)}
        if {[dict exist $d src]} {
            # importsources does not handle remote sources, so hack linked resources into .project as follows:
            set x [list "	<linkedResources>"]
            foreach filename [dict get $d src] {
                set basename [file tail $filename]
                set relpath [fileutil::relative [file normalize ./$app_name] $filename]
                set n 0
                while {[string range $relpath 0 2] == "../"} {
                    set relpath [string range $relpath 3 end]
                    incr n
                }
                if {n > 0} {
                    set relpath "PARENT-$n-PROJECT_LOC/$relpath"
                }
                set s [list "		<link>"]
                lappend s "			<name>src/$basename</name>"
                lappend s "			<type>1</type>"
                lappend s "			<locationURI>$relpath</locationURI>"
                lappend s "		</link>"
                set x [concat $x $s]
            }
            lappend x "	</linkedResources>"
            set f [open "./${app_name}/.project" "r"]
            set lines [split [read $f] "\n"]
            close $f
            set i [lsearch $lines "	</natures>"]
            if {$i < 0} {
                error "did not find insertion point"
            }
            set lines [linsert $lines 1+$i {*}$x]
            set f [open "./${app_name}/.project" "w"]
            puts $f [join $lines "\n"]
            close $f
            set d [dict remove $d src]
        }
        if {[dict exist $d inc]} {
            foreach path [dict get $d inc] {
                app config -name $app_name build-config release
                app config -name $app_name include-path $path
                app config -name $app_name build-config debug
                app config -name $app_name include-path $path
            }
            set d [dict remove $d inc]
        }
        if {[dict exist $d inc_rls]} {
            foreach path [dict get $d inc_rls] {
                app config -name $app_name build-config release
                app config -name $app_name include-path $path
            }
            set d [dict remove $d inc_rls]
        }
        if {[dict exist $d inc_dbg]} {
            foreach path [dict get $d inc_dbg] {
                app config -name $app_name build-config debug
                app config -name $app_name include-path $path
            }
            set d [dict remove $d inc_dbg]
        }
        if {[dict exist $d sym]} {
            foreach sym [dict get $d sym] {
                app config -name $app_name build-config release
                app config -name $app_name define-compiler-symbols $sym
                app config -name $app_name build-config debug
                app config -name $app_name define-compiler-symbols $sym
            }
            set d [dict remove $d sym]
        }
        if {[dict exist $d sym_rls]} {
            foreach sym [dict get $d sym_rls] {
                app config -name $app_name build-config release
                app config -name $app_name define-compiler-symbols $sym
            }
            set d [dict remove $d sym_rls]
        }
        if {[dict exist $d sym_dbg]} {
            foreach sym [dict get $d sym_dbg] {
                app config -name $app_name build-config debug
                app config -name $app_name define-compiler-symbols $sym
            }
            set d [dict remove $d sym_dbg]
        }
        if {[llength [dict keys $d]]} {
            error_exit {"create - leftovers: $d"}
            exit 1
        }
    }

    build {
        set cfg [lindex $args 0]
        setws ./$proj_dir
        cd ./$proj_dir
        app config -name $app_name build-config $cfg
        app build -name $app_name
    }

    default {
        error_exit {"unknown cmd ($cmd)"}
    }
}
