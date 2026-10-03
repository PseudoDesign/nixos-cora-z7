# SPDX-License-Identifier: MIT
# Single CLI entry point; propagate Tcl errors as a failing process exit.
set repo_root [file dirname [file dirname [file normalize [info script]]]]
if {[catch {
    if {$argc != 3} { error "Expected: create|gui|build project-directory jobs" }
    lassign $argv action project_dir jobs
    set project_dir [file normalize $project_dir]
    if {![string is integer -strict $jobs] || $jobs < 1} { error "Jobs must be a positive integer" }
    switch -- $action {
        create - gui { source [file join $repo_root hw create-project.tcl] }
        build { source [file join $repo_root hw build.tcl] }
        default { error "Unknown hardware action: $action" }
    }
} message options]} {
    puts stderr [dict get $options -errorinfo]
    exit 1
}
if {$action ne "gui"} { exit 0 }
