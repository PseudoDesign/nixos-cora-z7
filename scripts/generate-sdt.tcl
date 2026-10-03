# SPDX-License-Identifier: MIT
# Run with XSCT 2024.1. No legacy device-tree-xlnx generation is performed.
if {$argc != 3} {
    puts stderr "Usage: xsct generate-sdt.tcl <xsa> <output-directory> <board-dtsi>"
    exit 2
}
lassign $argv xsa outdir board
set tool_version [version]
if {![regexp {2024\.1([^0-9]|$)} $tool_version]} {
    puts stderr "Expected XSCT 2024.1, found $tool_version. Use matching AMD tools."
    exit 1
}

# Apply board corrections after the generated root/PCW content. In 2024.1,
# -include_dts puts the custom include before root properties, which can then
# overwrite compatible, chosen settings, and single-core corrections.
sdtgen set_dt_param -xsa [file normalize $xsa] -dir [file normalize $outdir]
sdtgen generate_sdt
if {![file exists "$outdir/system-top.dts"]} {
    puts stderr "SDTGen did not produce system-top.dts"
    exit 1
}
set board_name [file tail $board]
file copy -force $board "$outdir/$board_name"
set top [open "$outdir/system-top.dts" a]
puts $top "\n// Cora wiring and 07S corrections must take precedence."
puts $top "#include \"$board_name\""
close $top
