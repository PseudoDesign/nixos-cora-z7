# Commissioning and qualification

This procedure produces evidence for one fixture revision and one board. None
of these gates has passed yet. A software dry run cannot substitute for a
physical result. Work through the gates in order; later tests must not silently
relax a failed earlier requirement.

## G0 — assembly and identity

With DUT power absent, verify the Rev B board, connector orientations, center
polarity, contact COM/NC/NO assignment, button net pairs and the relay's 5 V/GND
connections. Record serials/USB topology and the physical pad/photo map for all
sense wires. Do not reuse an unverified Rev B.1 pad map for this board.

Verify supply regulation under load, QT Py power OR-ing, fuse/wire selection,
common-ground connections and probe earth reference. Confirm JP3 EXT and JP1
open. Record firmware and all jumpers. Label each removable harness connector.

Before connecting a DUT signal, test controller startup, USB open/close, host
disconnect, host reboot, watchdog reset and fixture-power removal with dummy
loads. Check actual contact states against the proposed truth table. Confirm
the host's USB reconnect does not reboot QT Py firmware or pulse any relay.

**Pass:** recorded build matches the harness design; defaults and identities are
unambiguous. Otherwise fix the harness/profile before connecting the target.

## G1 — measurements and electrical isolation

Calibrate each populated ADC channel at zero and representative voltages using
an appropriate reference meter/source. Record divider ratio, gain, offset,
uncertainty and valid range. Exercise input-switch enable/disable and stale-data
handling. The scope is for waveforms; it does not automatically replace the
reference needed for accurate DC calibration.

Verify no appreciable back-feed into an unpowered ADC/fixture with the DUT on.
Then measure all monitored DUT rails with its main input disconnected under
each combination of:

| Variable | States to exercise |
| --- | --- |
| Cora USB | Disconnected; connected/enumerated; host restarted |
| SDWire | HOST route; DUT route; USB off; USB restored |
| Sense carrier | Enabled; isolated; fixture power absent |
| Other attachments | Ethernet/scope installed; each permitted accessory |

Do not connect an unqualified supply to a DUT net to perform this matrix.
Observe the actual final harness. Record residual voltages and rail decay with
scope probes attached; validate the proposed 0.10 V / 1 second off predicate.

Include known-powered plausibility checks and disconnected-sense-wire tests.
Passive dividers cannot distinguish every open wire from a real zero. Require
independent scope confirmation of the three critical rails before accepting
an off state for media switching; commission and periodically recheck both
measurement paths. Do not claim comprehensive automatic open-wire detection.

Prove SDWire host/DUT exclusivity and behavior after power loss/reset. Demonstrate
that a QT Py reset turning the DUT on during HOST routing does not connect the
card to both masters. Test loss and restoration of hub power and upstream USB.

**Pass:** a recorded media-write/off topology and a recorded boot topology both
work without unacceptable back-power or contention. If not, hardware/routing
must change; the station is not ready for unattended operation.

## G2 — reversible control and recovery

Start with the development image and no irreversible changes. Confirm:

- SD and JTAG mode selection across actual cold cycles.
- RESET and SRST operate as intended; JP1-open UART reconnect causes no reset.
- A valid image boots; a deliberately invalid image is recovered by external
  card rewrite even when no bootloader runs.
- Full written-image readback succeeds; the service refuses a mounted/wrong disk.
- Host loss holds outputs; a controller epoch change aborts the old transaction.
- Relay defaults are observed physically, rather than inferred from GPIO values.
- Early-console behavior is characterized for both boot classes in automation.md.

Initial repeatability target: 100 reversible boot/control cycles without an
unexplained failure, including at least 20 invalid-image recovery cycles. These
counts are project acceptance targets, not a statistical reliability claim.
Include repeated low-current strap/reset contact tests; replace unsuitable
signal contacts if failures occur.

**Pass:** ordinary boot/recovery requires no cable, jumper, SD or probe handling.

## G3 — power sequencing and PS eFUSE integrity

Before programming any fuses, evaluate AMD advisory **65240**, applicable device
data-sheet limits (DS187 for this part), and the programming library's voltage,
temperature and lifecycle prerequisites. Fuse integrity through power cycling
and correct fuse programming conditions are separate requirements. [Z1–Z3]

Use the four-channel capture of VCCPINT, VCCPAUX, VCCO_MIO0 and PS_POR_B. Proposed
acceptance strategy:

- **Power-on:** evaluate advisory power-on test 1, including the applicable POR
  timing/level requirements and release only after the three rails reach their
  specified minima. Do not replace data-sheet minima with nominal values.
- **Power-off:** first evaluate advisory power-off test 1: POR goes low before
  VCCPINT crosses 0.80 V and remains low until at least one specified terminal
  condition occurs (VCCPINT below 0.40 V, VCCPAUX below 0.70 V, or VCCO_MIO0
  below 0.90 V). [Z1, Z2]

The advisory provides alternative sufficient conditions. If the chosen condition
does not pass, report it accurately and explicitly select/qualify a supported
alternative. Do not claim that every listed alternative must pass, or silently
switch criteria after seeing results. Clock-based alternatives cannot be proven
with this fixed four-probe assignment.

Record comparison uncertainty and margin, crossing times, bounce/re-crossings,
POR assertion/release, extrema and observation windows. Near-threshold/noisy,
clipped or undersampled captures are inconclusive. Do not copy the advisory's
numeric limits into an enabled automated policy until its board/part-specific
interpretation and measurement margin are reviewed.

Test at least these distinct sequences, repeated under idle and representative
load with the final bitstream and harness:

| Sequence | Purpose |
| --- | --- |
| Native cold power-on | Board's unassisted PMIC/POR behavior |
| Normal commanded shutdown | Chosen firmware/relay shutdown sequence |
| Unexpected loss of DUT input power | Behavior without a prior software reset |
| Immediate supply restoration / bounce | Detect unsafe partial discharge or reset behavior |
| Host, hub and controller reset | Ensure external connections do not corrupt the intended sequence |
| Fixture supply failure while DUT supply persists | Confirm continuity/defaults and sense isolation |

The relay provides coarse power interruptions, not calibrated fast glitches.
Characterize actual edge/contact timing. Do not infer SoC voltage-fault-injection
resistance from these tests. Requalify materially different workloads, supply
models, probe setups or wiring. Room-temperature testing does not cover every
production temperature/supply corner.

**Pass:** selected power-on/off criteria pass with documented margins, including
required failure cases, and the operation-specific programming prerequisites
are satisfied. If native hardware fails a required case, keep irreversible
operations disabled; a normal shutdown script cannot repair unsafe abrupt loss.
Any added reset supervisor or power-sequence modification is a new harness revision.

## G4 — authenticated boot and storage

Requires implementation of the [security foundation](../security/README.md).
The current development image cannot pass this gate. Execute from externally
written media so the test is not dependent on a cooperative running DUT.

| Test | Expected observation / evidence |
| --- | --- |
| Approved complete image | Offline boot, expected release manifest and usable approved private state |
| Corrupted FSBL / wrong ROM trust anchor | Enforced rejection at the ROM boundary once hardware policy is provisioned |
| Altered bitstream or U-Boot partition | Authenticated stage rejects it; no unrestricted fallback |
| Modified kernel, initrd, DTB or FIT configuration | Required FIT verification rejects it |
| Modified boot arguments / verity digest | No mutable path can substitute accepted security parameters |
| Modified immutable root block | Verity detects corruption; no unauthorized executable startup path |
| Unauthorized recovery image | Rejected through every reachable recovery/boot mode |
| Approved recovery | Boots and repairs/restores only within authorized policy |
| Older correctly signed image | Record accepted/rejected behavior against explicit rollback policy |
| Debug access before/after planned restrictions | Matches lifecycle expectations; working physical transport is independently established |

Mutation cases must identify exact input differences and the expected rejection
boundary. A no-boot result without corroboration is inconclusive: check a
known-good control image, transport health and capture validity. In particular,
an unfused device does not demonstrate enforcement by an immutable trust anchor.

For copied-media tests, install another working board in a second lane. A copy
of device-specific protected media should fail only where binding is claimed;
prove the second board still boots its own approved image. Public device IDs
are correlation aids, not secrets. Test signed update, interrupted update and
authorized recovery separately from enrollment or credential issuance.

## G5 — irreversible operation rehearsal and execution

Before any real programming operation:

1. Exercise intent journaling, authorization, duplicate dispatch rejection,
   controller hold and process-restart reconciliation against a non-writing
   adapter. Inject failures before dispatch, after dispatch and before recording
   completion; every ambiguous case must become uncertain, never a repeat write.
2. Qualify read-only lifecycle inspection on this exact part and validate which
   observations remain possible after each planned debug restriction.
3. Qualify the actual programmer/key path, algorithm and constraints using
   applicable AMD documentation. Keep secrets outside Nix and public logs.
4. Require target-specific authorization and qualified backup power. Record
   the verified signed recovery path before tightening debug access.
5. Program once, reconcile/verify permitted postconditions, and then run the
   explicitly approved post-write reboot/enforcement tests.

Do not test a programming interruption on the only development board as part
of routine qualification. Fresh-state and destructive experiments consume
devices; use designated sacrificial units and distinct authorizations.

**Pass:** evidence establishes the intended lifecycle transition and actual
enforcement, including the post-lock recovery path. No station gate automatically
grants Kaiba membership or turns a generic Zynq claim into fleet policy.

## Release record and remaining engineering checks

The commissioned lane record must bind device identities, Rev B pad map,
assembled harness photographs/revision, controller/adapter/tool versions,
SDWire and hub power-loss behavior, supply/fuse selection, calibration,
scope/probe setup, accepted timing margins, test results and restricted evidence.
The example JSON remains uncommissioned until this record exists.

Currently unresolved by desk research:

- Exact Rev B solder-pad selections and the board's VCCBATT circuit.
- Relay minimum-load reliability and physical input/COM/NC/NO verification.
- SDWire routing/card-power behavior with USB removed; early-UART topology.
- Actual instrument identities, probe condition/calibration and regulator behavior.
- A packaged/qualified Cora JTAG and eFUSE adapter; authenticated image support.

These are explicit commissioning/implementation work items, not requests to
approve guessed wiring or evidence that the station is already production-ready.
