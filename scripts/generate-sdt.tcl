# SPDX-License-Identifier: MIT
# Run with the standalone sdtgen supplied by Vivado 2026.1.
if {$argc != 2 && $argc != 3} {
    puts stderr "Usage: sdtgen generate-sdt.tcl <xsa> <output-directory> ?board-dtsi?"
    exit 2
}
lassign $argv xsa outdir board
set tool_version [hsi version -short]
if {![regexp {^2026\.1([^0-9]|$)} $tool_version]} {
    puts stderr "Expected Vivado/SDTGen 2026.1, found $tool_version. Use matching AMD tools."
    exit 1
}

# Apply board corrections after generated root/PCW content.
set_dt_param -xsa [file normalize $xsa] -dir [file normalize $outdir]
generate_sdt
if {![file exists "$outdir/system-top.dts"]} {
    puts stderr "SDTGen did not produce system-top.dts"
    exit 1
}
if {$board ne ""} {
    set board_name [file tail $board]
    file copy -force $board "$outdir/$board_name"
    set top [open "$outdir/system-top.dts" a]
    puts $top "\n// Cora wiring and 07S corrections must take precedence."
    puts $top "#include \"$board_name\""
    close $top
}
set provenance [open "$outdir/sdtgen-version.txt" w]
puts $provenance $tool_version
close $provenance
