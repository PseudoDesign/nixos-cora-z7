# SPDX-License-Identifier: MIT
# Build only a freshly recreated project so stale GUI state cannot enter a release.
source [file join $repo_root hw create-project.tcl]
launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}
launch_runs impl_1 -to_step write_bitstream -jobs $jobs
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
    error "Implementation failed: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
set reports [file join $project_dir reports]
file mkdir $reports
report_drc -file [file join $reports drc.rpt]
foreach violation [get_drc_violations] {
    set check [get_drc_checks [get_property CHECK $violation]]
    set severity [string tolower [get_property SEVERITY $check]]
    if {$severity ni {warning advisory info}} {
        error "DRC failed ($violation, $severity); see $reports/drc.rpt"
    }
}
report_timing_summary -file [file join $reports timing.rpt]
# A PS-only design may have no PL timing paths. Check both setup and hold
# whenever paths exist (including after custom PL logic is added).
foreach delay {max min} {
    foreach path [get_timing_paths -delay_type $delay -max_paths 1] {
        if {[get_property SLACK $path] < 0} {
            error "Timing failed ($delay); see $reports/timing.rpt"
        }
    }
}
source [file join $repo_root scripts export-hardware.tcl]
export_cora_release [file join $project_dir cora-z7-07s-hardware.tar.gz]
