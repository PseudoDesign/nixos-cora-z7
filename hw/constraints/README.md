Put hand-maintained XDC constraints here and explicitly add them to `constrs_1`
in `hw/create-project.tcl`. The initial PS-only design exposes only dedicated
DDR and FIXED_IO signals and needs no user PL pin assignments. When adding PL
ports, supply their package pins, I/O standards and timing constraints.
