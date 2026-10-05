# Bill of materials — one lane

Reuse the Cora Z7-07S Rev B, Inland KS0212, Rigol DS1054Z with four probes, Linux
host, Adafruit QT Py RP2040, suitable network ports and backed-up AC power. Do not buy another scope,
relay module, Uno, Uno 9 V supply, or full Raspberry Pi for this design.

Prices below are planning figures from the research, not a checkout quote.
Shipping, import fees and local stock are not committed. Product links identify
the required variants; supplier substitutions must preserve the specified
interfaces. See [hardware.md](hardware.md) before choosing harness parts.

| Qty | Item | Purpose / purchasing note |
| --- | --- | --- |
| 1 | [3mdeb SDWire](https://shop.3mdeb.com/product/sdwire/) | Micro-USB version; EUR89 excluding VAT in research; supports host-side card writing and DUT routing |
| 1 | [Yepkit YKUSH3](https://www.yepkit.com/product/300110/YKUSH3) | Three independently switched USB ports, power **and** data; EUR124.99 in research |
| 2 | [Adafruit ADS1115 #1085](https://www.adafruit.com/product/1085) | 8 telemetry inputs total; USD14.95 each in research |
| 2 | [5 V / 4 A regulated supplies, e.g. Adafruit #1466](https://www.adafruit.com/product/1466) | One DUT, one fixture. Confirm fixture branch meets YKUSH3's loaded 5.00–5.25 V requirement; USD14.95 each in research |
| 2 | Reliable 32 GB microSD cards | One installed, one spare; the spare is not remotely selectable |
| 2 | Short USB-A to micro-B **data** cables | Cora, SDWire; reuse suitable existing cables |
| 1 | USB-A to USB-C data cable | Owned QT Py RP2040; add headers/socket as needed |
| 1 | USB-A to USB 3 micro-B upstream cable | YKUSH3; different connector from ordinary micro-B |
| 2–3 | Ethernet patch cables | Host management, scope, dedicated DUT link |
| 1 if needed | Linux-supported second host NIC / USB Gigabit adapter | Dedicated direct DUT network; an existing isolated VLAN arrangement can replace it |
| 1 if needed | Small Ethernet switch and supply | Management network for host/scope, if no existing ports |
| 1 | 2 x 20 male-header breakout/adapter | Mates to the relay board's female Pi socket; not a QT Py-to-Pi pin-for-pin cable |
| 2 | [TI TMUX1511PWR](https://www.ti.com/product/TMUX1511) | Powered-off isolation for divided analog inputs; 14-pin TSSOP |
| 2 | TSSOP-14 to through-hole adapters | For the TMUX devices in a perfboard prototype |
| 1 | 1N5817 Schottky diode | External 5 V to QT Py 5V pad (USB-host jumper open) power OR-ing |
| 16 | 10 kOhm 0.1% resistors | Eight potential divider channels, one spare channel can remain unpopulated |
| 5 | 10 kOhm pull-down resistors | Four relay inputs and sense-enable |
| 8 each | 1 kOhm resistors, 1 nF capacitors, BAT54S clamp pairs | ADC input stages; spare included |
| 8 | SparkFun BOB-00717 SOT-23 to DIP adapters | One BAT54S per board; purchase quantity 10 includes two spare boards |
| 2 + 1 | 100 nF ceramic capacitors + 10 uF capacitor | Analog-switch decoupling and carrier bulk capacitance |
| 1 set | Barrel breakouts/pigtails, fuse holders and selected fuses | Cora uses center-positive 5.5 x 2.1 mm; confirm mating fit |
| 1 set | Perfboard, keyed connectors, terminals and wire | 18–20 AWG power; smaller signal wire; strain relief and heat shrink |
| 1 set | Permanent probe/test-point hardware | Four signal and nearby ground attachments, mechanically secured |
| 1 | Insulating mounting plate and standoffs | Mount Cora, relay board, mux and carrier; support the SDWire independently |

For commissioning, reuse or arrange a suitable DC reference meter/source and
temperature measurement appropriate to the eventual programming procedure.
The oscilloscope covers transient measurements, but its presence does not
establish all DC calibration or programming-temperature prerequisites.

Allow roughly **EUR214 plus USD155–235** for the remaining components and
harness, before shipping/tax, assuming host, scope, network and backup power
are reused. This is an estimate, especially for small-quantity carrier parts.

3mdeb's [shipping FAQ](https://3mdeb.com/faq-shop/) includes US deliveries; obtain
the actual delivery charge at checkout. The Linux Automation mux is not the
baseline because US delivery was unavailable in the user's checkout.

## Procurement baseline — 2026-10-05

The operator reports the SDWire, YKUSH3, Adafruit parts and remaining parts
ordered. Receipt, quantities and assembly still need to be checked against the
orders. Procurement does not constitute electrical qualification.

The final adapter selection is **SparkFun BOB-00717**, Mouser
[474-BOB-00717](https://www.mouser.com/c/?q=474-BOB-00717), quantity 10.
It replaces the unavailable Adafruit #1230 assortment. Its footprint supports
SOT-23-3; fit one BAT54S per board and use the purchased breakaway headers.
Eight boards cover the eight possible ADC stages; two boards are spares.
Follow the adapter pad mapping when wiring the three diode terminals.

The remaining-parts order list was consolidated at Mouser:

| Purchase qty | Mouser part number | Item |
| --- | --- | --- |
| 3 | 595-TMUX1511PWR | TSSOP-14 analog switches; two required |
| 10 | 621-BAT54S-F | BAT54S-7-F clamp pairs |
| 25 | 279-YR1B10KCC | 10 kOhm 0.1% axial divider resistors; 16 required |
| 10 | 80-C315C102K5G | C315C102K5G5TA, 1 nF 50 V C0G radial capacitors |
| 3 | 621-1N5817 | 1N5817-T controller power OR-ing diode; one required |
| 10 | 474-BOB-00717 | Individual SOT-23 breakout boards |
| 2 | 576-01500274Z | Inline 5 x 20 mm fuse holders |
| 5 | 576-0218002.MXP | 2 A slow-blow commissioning fuse candidates |
| 5 | 576-02183.15MXP | 3.15 A slow-blow commissioning fuse candidates |
| 1 each | 548-WI-M-18-10-2 / 548-WI-M-18-10-0 | Red / black 18 AWG silicone wire, 10 ft each |
| 6 | 485-578 | Four-pin plug/socket cable sets for signal harnesses |
| 6 | 651-1715721 | Two-position 5.08 mm PCB screw terminals |
| 5 each | 534-5000 / 534-5001 | Red / black probe test points |
| 1 if absent from hub package | 562-3023005-01M | USB-A to USB 3 micro-B upstream cable |

Use the precision 0.1% resistors for the dividers; the Adafruit 5% resistors
are for pull-downs. Choose the fitted fuse ratings after measuring operating
current and startup behavior. Use 18 AWG wiring for the main power branches.
Confirm terminal pin fit on the carrier before assembly, and mechanically
secure the probe attachments close to their measurement points.

Cards and additional network hardware were conditional purchases: reuse
suitable existing parts or verify them against the order receipts. The suggested
Mouser options were 524-SDCE/32GB (two 32 GB microSD cards) and Tripp Lite
U336-000-GB-AL (one USB Ethernet adapter if a dedicated host port is needed).
The mounting plate can be printed; use the selected standoffs.

Supplier stock counts and prices are intentionally not acceptance criteria.

## Mechanical arrangement

Mount the Cora on standoffs with access under J10, the QT Py/sense carrier beside
it, and the relay board far enough away to route coil/power wiring away from
sense leads. Put SDWire immediately beside its socket support. Mount the
YKUSH3 at the cable-entry edge. Use labeled removable harness connectors so
replacement is possible without reproducing the wiring from memory.

A printed mounting plate/brackets are suitable for the low-voltage fixture.
Keep enclosed mains supplies outside the signal harness. Leave the scope on the
bench with its four probes permanently routed to the plate; no automated probe
switching is required for the one-lane rail/POR tests.

## Second lane

To test copied media on another device without moving hardware, add a second
Cora, SDWire, four relay channels, controller/sense carrier and DUT power branch.
Provide enough independently switched USB ports and another isolated DUT link.
Software clone tests can use the second lane without a second scope; simultaneous
or unattended electrical qualification of both lanes needs another scope or a
separately engineered/qualified measurement switch. Do not assume one loose
spare board satisfies the no-rewiring requirement.
