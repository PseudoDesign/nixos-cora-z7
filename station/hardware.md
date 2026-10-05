# Hardware and harness

This is a prototype wiring design, not a released PCB or certified instrument.
Reference IDs below resolve in [sources.md](sources.md). Cora net names identify
electrical endpoints; exact solder pads must be matched to the physical Rev B
board before assembly is released. Do not substitute a regulator switch node
for a regulated output/SoC supply net.

## Power distribution

Use two external low-voltage supplies on backed-up AC power:

- `PSU-DUT`: regulated 5 V, 4 A, center-positive 5.5 x 2.1 mm connection.
  Positive goes through a harness fuse, relay 1 COM/NC and then Cora J15 center.
  Negative goes directly to Cora J15 sleeve/common ground.
- `PSU-FIXTURE`: regulated nominal 5 V, 4 A, separate branches to KS0212 and
  YKUSH3, and through a Schottky diode to QT Py 5V pad. YKUSH3 specifies **5.00–5.25 V**
  at its external input; qualify actual loaded voltage and cable drop rather
  than relying on the supply's nominal label. [Y1]

Fuse each supply's positive harness branch at its entry. Select the final fuse
from measured inrush, wire ampacity and supply current-limit behavior; 4 A is
the PSU capacity, not an instruction to fit a 4 A fuse. Keep the power path short
with 18–20 AWG wire and enclosed terminals. Do not switch the ground conductor.

QT Py external power: fixture +5 V to the **anode** of a 1N5817; cathode to
its **5V pad**. Leave the underside USB-host jumper **open**: its existing
protection diode prevents external power feeding USB VBUS. Do not bridge that
diode. USB-C data connects directly to the host, outside YKUSH3. This lets
controller power persist when host USB disappears. [P1]

Power the ADCs and analog switches from the QT Py **3V pad**. Common
ground joins both supplies, QT Py, relay input electronics, sense carrier and
Cora. The Rigol's probe grounds are earth-referenced: all attach to DUT ground,
never to a supply rail. Relay contacts themselves remain dry contacts.

YKUSH3 is set to external/self power (`VEXT`), using its external screw terminal.
Do not confuse its separate switched 5 V output with the power input. [Y1]

## Cora permanent setup

| Item | Assembly setting |
| --- | --- |
| JP3 | EXT; externally supplied through J15 |
| JP2 | Remove jumper; replace with relay 2 COM/NC pair |
| JP1 | Open; prevents USB UART DTR from operating shield/reset circuitry |
| J12 | Micro-USB JTAG/UART, via YKUSH3 port 1 |
| J10 | SDWire target tongue, securely supported |
| RESET pushbutton | Relay 3 COM/NO wired across the two switch nets |
| SRST pushbutton | Relay 4 COM/NO wired across the two switch nets |
| Ethernet | Dedicated host DUT interface or isolated DUT VLAN |
| USB host / shield / Pmod | No unqualified powered peripherals attached |

JP2 closed selects SD; open selects JTAG. Use a complete verified power cycle
when changing the selection. SRST does not resample boot straps. [C1]

For each tactile switch, identify the two different electrical nets with an
unpowered continuity check. Two legs on one side can already be common; do not
choose pads by visual position alone. RESET is not interchangeable with SRST.
Closing RESET must be characterized for its effect on the PMIC and PS_POR_B
before relying on it to hold the processor during USB enumeration. [C1]

## Relay/control harness

Use a keyed adapter with a **2 x 20 male header** mating to the KS0212 female
socket. The table uses Raspberry Pi *physical header numbering*, not the
QT Py's physical pin order. Reference the connector mating face and pin-1 marker;
the underside view is mirrored. The manufacturer's BCM mapping is in [R2].

| Function | QT Py pad / RP2040 GPIO | KS0212 physical pin / BCM | Contacts | GPIO low / de-energized | GPIO high / energized |
| --- | --- | --- | --- | --- | --- |
| `power_cut` | A0 / GP29 | 7 / BCM4 | R1 COM–NC in +5 V feed | DUT power connected | DUT power disconnected |
| `boot_jtag` | A1 / GP28 | 15 / BCM22 | R2 COM–NC across JP2 | SD strap closed | JTAG strap open |
| `reset_hold` | A2 / GP27 | 31 / BCM6 | R3 COM–NO across RESET | Released | Pressed |
| `srst_hold` | A3 / GP26 | 37 / BCM26 | R4 COM–NO across SRST | Released | Pressed |

KS0212 receives fixture +5 V on the Pi power positions 2/4 and ground on position
6 through the adapter. Before first power, verify these contacts against the
board's supply/ground planes and confirm channel order. The module is intended
for Pi GPIO and its example indicates active-high inputs; verify this once with
no DUT attached. Do not infer a complete input circuit from the relay-can label.

Fit a 10 kOhm pull-down at each of the four relay inputs. Select QT Py output
latches low *before* enabling the pins as outputs. Do not add pull-ups to Cora
reset/strap nets or drive them from QT Py GPIO; only the dry contacts touch them.

The KS0212's large load ratings do not specify minimum reliable switching load.
Acceptance includes repeated low-current RESET/SRST/JP2 operation and observed
contact closure. If it proves intermittent, replace those three channels with
qualified signal relays; do not add arbitrary wetting current to SoC signals.

Firmware must hold outputs on host loss. A hardware/controller reset drops the
coils: DUT power connects, both resets release and the strap returns to SD. A
reset during an SD imaging job invalidates the off-state guarantee. A reset
during an irreversible job must not initiate a new power/reset sequence.

## USB and SD routing

| Connection | Host path | Startup policy |
| --- | --- | --- |
| QT Py | Direct host USB | Always available; no USB-reset-on-close behavior |
| Cora JTAG/UART | YKUSH3 port 1 | Default OFF; enabled only by the lane owner |
| SDWire reader/control | YKUSH3 port 2 | Default OFF; enabled during media operations |
| Spare | YKUSH3 port 3 | OFF and unused |

Default OFF is for a hub power-up/reset. It is **not** a promise that hub/host
disconnect preserves ports. Commission the actual hub firmware, host reboot
behavior and SDWire routing before irreversible jobs. Freeze hub changes during
such jobs. YKUSH3 switches both power and data, but leaves ground connected. [Y1]

SDWire gives one physical card either to its USB reader or to the Cora. Use its
documented CLI by unique device identity; never choose the first detected mux.
The following behavior is a required measured acceptance result, not assumed
from the product name: host/DUT exclusivity, card-power source in each route,
route after USB loss, persistence across USB power cycling, and absence of
back-power into the unpowered Cora. [S1, S2]

The preferred boot topology is SD routed to DUT and SDWire USB disconnected.
Enable that profile only if routing and card operation survive removal of USB
power. Otherwise qualify USB-connected DUT routing for back-power and reset
behavior. If neither passes, this SDWire revision/topology is not accepted;
select a different mux or an engineered isolation adapter. Do not treat a delay
as a substitute for resolving a powered back-feed path.

Attach SDWire to a support bracket so its mass and USB cable do not load J10.
Avoid a long generic microSD extender. If an extender is mechanically necessary,
qualify it at the actual SD clock with repeated full image readback and boot.

## Persistent rail sensing

Two Adafruit ADS1115 #1085 breakouts provide eight slow telemetry channels.
Power both at 3.3 V. QT Py edge pad SDA = GP24 (I2C0 SDA); SCL = GP25 (I2C0 SCL).
These are separate from STEMMA QT (GP22/GP23, I2C1), which is unused. [P1, P2]
Set U1 ADDR to GND (0x48), U2 ADDR to 3.3 V (0x49). Pull-ups must terminate at
3.3 V; account for the breakouts' existing pull-ups before adding more. [A1, A2]

| ADC | Input | Sense endpoint | Nominal source voltage |
| --- | --- | --- | --- |
| U1, 0x48 | A0 | Cora rail feeding VCCPINT | 1.00 V |
| U1, 0x48 | A1 | Cora rail feeding VCCPAUX | 1.80 V |
| U1, 0x48 | A2 | Cora rail feeding VCCO_MIO0 | 3.30 V; confirm net |
| U1, 0x48 | A3 | Cora VCC5V0 downstream of relay/input circuitry | 5.00 V |
| U2, 0x49 | A0 | Cora DDR supply | 1.35 V |
| U2, 0x49 | A1 | Fixture +5 V at distribution point | 5 V nominal |
| U2, 0x49 | A2 | DUT +5 V upstream of relay | 5.00 V |
| U2, 0x49 | A3 | Spare | Terminate to ground; excluded from decisions |

Prototype input stage, repeated for each used input:

1. Sense source through 10 kOhm, 0.1% to divider node.
2. Another 10 kOhm, 0.1% from that node to ground: nominal source/2.
3. Divider node through one channel of a **TMUX1511PWR** powered at 3.3 V.
4. Switch output through 1 kOhm to ADC input; 1 nF from ADC input to ground.
5. Low-leakage Schottky clamps at ADC input to ground and ADC VDD; BAT54S is
   a prototype candidate. Account for leakage in calibration.

Use two TMUX1511PWR devices (14-pin TSSOP), with suitable adapters if building on
perfboard. Tie all SEL inputs to QT Py TX pad / GP20 with a 10 kOhm pull-down. HIGH
connects sensing; LOW isolates it. The switches' powered-off protection applies
up to 3.6 V on signal pins when VDD is zero; the divider limits a 5.5 V source to
2.75 V. It prevents a still-powered DUT from feeding an unpowered ADC through
its protection diodes. This is protection for the specified low-voltage nets,
not arbitrary overvoltage protection. [A3]

Local 100 nF decoupling at each switch, plus 10 uF at the carrier supply entry.
Route sense returns separately from relay-coil current. The 20 kOhm divider
loads each source by V/20 kOhm; measure its effect on power decay. Scope probes
connect directly to the DUT nets, ahead of divider/filter circuitry.

Suggested initial ADC setup: +/-4.096 V range, 128 samples/s, single-shot
conversion, full scan at 10 Hz. Discard unsettled readings after enabling the
switches; calibrate offset/gain at multiple known inputs including near zero.
Stale, saturated or unpowered readings are **invalid**, never zero. A passive
divider cannot identify every broken sense wire; use known-on plausibility
checks and independent scope confirmation of critical-rail power-off. Detected
sensor faults invalidate the measurement rather than being converted to zero.
The PGA range does not permit input voltage beyond the ADC supply. [A1]

The initial off-state predicate is all monitored DUT rails below 0.10 V for
1 second, with fresh calibrated data. It is a fixture heuristic to qualify,
not an AMD fuse-integrity threshold or proof that every SoC domain is unpowered.
Validate it against scope captures and document residual/back-powered domains.

## Scope harness

| Rigol channel | Permanent endpoint |
| --- | --- |
| CH1 | VCCPINT supply net |
| CH2 | VCCPAUX supply net |
| CH3 | VCCO_MIO0 supply net |
| CH4 | PS_POR_B at the SoC-side net |

Use compensated passive probes, configured attenuation matching their physical
switches, DC coupling, short ground connections and secure test points.
Keep signal stubs short. Recheck the waveform with the final ADC/probe harness
attached; the harness itself changes discharge behavior.

These four channels target AMD advisory 65240's POR/rail conditions. They do
not observe PS_CLK, every power rail or BBRAM retention. Select a documented
rail/POR criterion; a clock-based alternative would need different probes and
a separate qualified configuration. [Z1, Z2]

The eight-bit DS1054Z needs appropriate per-channel scale/offset and a recorded
uncertainty allowance. A trace near a threshold is inconclusive, not a pass.
Use full waveform samples and preambles, not only screenshots. Confirm the
actual record length and sample interval when all four channels are active.

## One-time physical record

Record pad/component references and close-up photographs for each attached
sense wire, both button pairs, JP2, and ground. Store these with the private
fixture record and its harness revision. This design deliberately does not
invent Rev B component-pad numbers from a B.1 schematic or an unreadable photo.

BBRAM/VCCBATT retention and deliberate zeroization are outside this harness
release until that board-specific circuit is traced. Electrical fault injection
and temperature-corner qualification are also separate extensions.

## Raspberry Pi 5 host ports as an alternative

YKUSH3 is the selected baseline, not a requirement for that particular brand.
An alternative must qualify independent Cora/SDWire power and data control.
Pi 5 onboard USB VBUS is ganged across all four sockets. Turning any port on
restores VBUS to all four; logical port disable is not proof of electrical
isolation. Bus identifiers vary with the installed OS/hardware. [H1]

A lower-cost shared-power variant is possible to investigate, but is not a
qualified drop-in replacement. It must tolerate losing all USB devices together,
use non-USB host storage/network for uninterrupted operation, and keep the
externally powered QT Py controllable (for example with separately engineered
3.3 V UART firmware/wiring). It must establish that powered SDWire access with
Cora USB also powered does not back-feed the off DUT, and qualify data-path
behavior and host-reboot defaults. If that state fails, independent switching
is required. Do not enable this variant in the lane template before G1/G2 pass.
