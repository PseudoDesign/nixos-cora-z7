# SPDX-License-Identifier: MIT
# Source this file in the Tcl console of an open Vivado 2026.1 project:
#   source /path/to/nixos-cora-z7/scripts/export-hardware.tcl
#   export_cora_release /path/to/cora-z7-07s-hardware.tar.gz
# An optional second argument selects an implementation run other than impl_1.

namespace eval ::cora_release {
    variable script_dir [file dirname [file normalize [info script]]]
}

proc export_cora_release {output {implementation_run impl_1}} {
    set tool_version [version -short]
    if {![regexp {^2026\.1([^0-9]|$)} $tool_version]} {
        error "Expected Vivado 2026.1, found $tool_version."
    }
    set project [current_project -quiet]
    if {$project eq ""} {
        error "Open the completed Cora Z7-07S Vivado project before exporting."
    }
    set part [get_property PART $project]
    if {$part ne "xc7z007sclg400-1"} {
        error "Expected Cora Z7-07S part xc7z007sclg400-1, found $part."
    }
    if {![info exists ::env(XILINX_VIVADO)] || $::env(XILINX_VIVADO) eq ""} {
        error "XILINX_VIVADO must identify the running Vivado 2026.1 installation."
    }
    set sdtgen [file join $::env(XILINX_VIVADO) bin sdtgen]
    if {![file executable $sdtgen]} {
        error "Standalone SDTGen is missing or not executable: $sdtgen"
    }
    if {[info exists ::env(CUSTOM_SDT_REPO)] && $::env(CUSTOM_SDT_REPO) ne ""} {
        error "Unset CUSTOM_SDT_REPO to use the SDT repository shipped with Vivado 2026.1."
    }
    set python [auto_execok python3]
    if {$python eq ""} {
        error "Python 3 is required to package the release; launch Vivado from nix develop or add python3 to PATH."
    }
    set script_dir $::cora_release::script_dir
    foreach helper {generate-sdt.tcl pack-hardware.py} {
        if {![file isfile [file join $script_dir $helper]]} {
            error "Missing release helper: [file join $script_dir $helper]"
        }
    }
    set archive [file normalize $output]
    if {[file isdirectory $archive]} {
        error "The release output must be a .tar.gz file, not a directory: $archive"
    }
    if {![string match *.tar.gz $archive]} {
        error "The release output filename must end in .tar.gz."
    }
    set parent [file dirname $archive]
    file mkdir $parent
    set work [file join $parent ".cora-release-[pid]-[clock clicks]"]
    if {[file exists $work]} {
        error "Temporary export directory already exists: $work"
    }
    file mkdir $work

    # Keep generation isolated and let the packer replace the archive atomically.
    # Tcl catch/return -options also works in Tcl 8.5.
    set failed [catch {
        set xsa [file join $work hardware.xsa]
        set sdt [file join $work sdt]
        open_run $implementation_run -quiet
        write_hw_platform -fixed -include_bit -force -file $xsa
        exec $sdtgen [file join $script_dir generate-sdt.tcl] $xsa $sdt >@stdout 2>@stderr
        # Vivado's libraries/Python environment must not leak into the host
        # Python used for packaging. Restore the GUI environment afterwards.
        set saved_python_env [dict create]
        foreach name {LD_LIBRARY_PATH PYTHONHOME PYTHONPATH} {
            if {[info exists ::env($name)]} {
                dict set saved_python_env $name $::env($name)
                unset ::env($name)
            }
        }
        set python_failed [catch {
            exec {*}$python [file join $script_dir pack-hardware.py] $sdt $xsa $archive >@stdout 2>@stderr
        } python_result python_options]
        dict for {name value} $saved_python_env {
            set ::env($name) $value
        }
        if {$python_failed} {
            return -options $python_options $python_result
        }
    } result options]
    # This path was created by this call and never points at the user's output.
    catch {file delete -force $work}
    if {$failed} {
        return -options $options $result
    }
    puts "Release exported: $archive"
    return $archive
}
