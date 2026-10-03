# SPDX-License-Identifier: MIT
# Sourced by entry.tcl. All project products stay in project_dir.
set actual_version [version -short]
if {![regexp {^2026\.1([^0-9]|$)} $actual_version]} {
    error "Expected Vivado 2026.1, found $actual_version"
}
if {[current_project -quiet] ne ""} {
    error "Close the current project before creating a fresh project"
}
if {[file exists $project_dir]} {
    error "Build directory already exists: $project_dir. Choose a new directory to preserve existing GUI work."
}
set_param board.repoPaths [list [file join $repo_root hw boards]]
set board digilentinc.com:cora-z7-07s:part0:1.1
if {[llength [get_board_parts -quiet $board]] != 1} {
    error "Vendored Cora board definition was not found: $board"
}
create_project cora-z7-07s $project_dir -part xc7z007sclg400-1
set_property board_part $board [current_project]
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Keep the file list explicit: add new HDL, memory init and custom IP here.
# Example: add_files -norecurse [file join $repo_root hw rtl my_module.v]
# Example: add_files -fileset constrs_1 -norecurse [file join $repo_root hw constraints pins.xdc]
# Add custom IP repositories and update_ip_catalog before sourcing the BD.
source [file join $repo_root hw bd design.tcl]
set bd [get_files */system.bd]
if {[llength $bd] != 1} { error "Expected exactly one system.bd" }
validate_bd_design
save_bd_design
generate_target all $bd
set wrappers [make_wrapper -files $bd -top]
add_files -norecurse $wrappers
set_property top system_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
puts "Created [file join $project_dir cora-z7-07s.xpr]"
