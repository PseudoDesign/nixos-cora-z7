# Bill of materials — one lane

Reuse the Cora Z7-07S Rev B, Inland KS0212, Rigol DS1054Z with four probes, Linux
host, suitable network ports and backed-up AC power. Do not buy another scope,
relay module, Uno, Uno 9 V supply, or full Raspberry Pi for this design.

Prices below are planning figures from the research, not a checkout quote.
Shipping, import fees and local stock are not committed. Product links identify
the required variants; supplier substitutions must preserve the specified
interfaces. See [hardware.md](hardware.md) before choosing harness parts.

| Qty | Item | Purpose / purchasing note |
| --- | --- | --- |
| 1 | [3mdeb SDWire](https://shop.3mdeb.com/product/sdwire/) | Micro-USB version; EUR89 excluding VAT in research; supports host-side card writing and DUT routing |
| 1 | [Yepkit YKUSH3](https://www.yepkit.com/product/300110/YKUSH3) | Three independently switched USB ports, power **and** data; EUR124.99 in research |
| 1 | [Raspberry Pi Pico H](https://www.raspberrypi.com/products/raspberry-pi-pico/) | Original RP2040 version with soldered headers; allow USD5–10 |
| 2 | [Adafruit ADS1115 #1085](https://www.adafruit.com/product/1085) | 8 telemetry inputs total; USD14.95 each in research |
| 2 | [5 V / 4 A regulated supplies, e.g. Adafruit #1466](https://www.adafruit.com/product/1466) | One DUT, one fixture. Confirm fixture branch meets YKUSH3's loaded 5.00–5.25 V requirement; USD14.95 each in research |
| 2 | Reliable 32 GB microSD cards | One installed, one spare; the spare is not remotely selectable |
| 3 | Short USB-A to micro-B **data** cables | Cora, SDWire, Pico; reuse suitable existing cables |
| 1 | USB-A to USB 3 micro-B upstream cable | YKUSH3; different connector from ordinary micro-B |
| 2–3 | Ethernet patch cables | Host management, scope, dedicated DUT link |
| 1 if needed | Linux-supported second host NIC / USB Gigabit adapter | Dedicated direct DUT network; an existing isolated VLAN arrangement can replace it |
| 1 if needed | Small Ethernet switch and supply | Management network for host/scope, if no existing ports |
| 1 | 2 x 20 male-header breakout/adapter | Mates to the relay board's female Pi socket; not a Pico-to-Pi pin-for-pin cable |
| 2 | [TI TMUX1511PWR](https://www.ti.com/product/TMUX1511) | Powered-off isolation for divided analog inputs; 14-pin TSSOP |
| 2 | TSSOP-14 to through-hole adapters | For the TMUX devices in a perfboard prototype |
| 1 | 1N5817 Schottky diode | External 5 V to Pico VSYS power OR-ing |
| 16 | 10 kOhm 0.1% resistors | Eight potential divider channels, one spare channel can remain unpopulated |
| 5 | 10 kOhm pull-down resistors | Four relay inputs and sense-enable |
| 8 each | 1 kOhm resistors, 1 nF capacitors, BAT54S clamp pairs | ADC input stages; spare included |
| 8 | SOT-23 adapters, if using perfboard | For the clamp diode pairs |
| 2 + 1 | 100 nF ceramic capacitors + 10 uF capacitor | Analog-switch decoupling and carrier bulk capacitance |
| 1 set | Barrel breakouts/pigtails, fuse holders and selected fuses | Cora uses center-positive 5.5 x 2.1 mm; confirm mating fit |
| 1 set | Perfboard, keyed connectors, terminals and wire | 18–20 AWG power; smaller signal wire; strain relief and heat shrink |
| 1 set | Permanent probe/test-point hardware | Four signal and nearby ground attachments, mechanically secured |
| 1 | Insulating mounting plate and standoffs | Mount Cora, relay board, mux and carrier; support the SDWire independently |

For commissioning, reuse or arrange a suitable DC reference meter/source and
temperature measurement appropriate to the eventual programming procedure.
The oscilloscope covers transient measurements, but its presence does not
establish all DC calibration or programming-temperature prerequisites.

Allow roughly **EUR214 plus USD160–240** for the remaining components and
harness, before shipping/tax, assuming host, scope, network and backup power
are reused. This is an estimate, especially for small-quantity carrier parts.

3mdeb's [shipping FAQ](https://3mdeb.com/faq-shop/) includes US deliveries; obtain
the actual delivery charge at checkout. The Linux Automation mux is not the
baseline because US delivery was unavailable in the user's checkout.

## Mechanical arrangement

Mount the Cora on standoffs with access under J10, the Pico/sense carrier beside
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
