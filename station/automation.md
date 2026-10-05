# Automation contract

All interfaces in this file are **proposed**, not installed commands. They
describe the implementation target for a generic Cora station. Kaiba supplies
policy and approval later; the controller never contacts a fleet service.

## Processes and authority

Run one station service on the Linux host. It alone owns the Pico serial device,
SDWire control interface/card block device, YKUSH HID, UART and JTAG interfaces,
and the Rigol connection. Use persistent identities, restrictive device access,
and an exclusive lock on the complete lane, not a separate lock per tool.
Shared instruments require a station-wide resource lock as well.

Do not expose unrestricted write access to these devices to a build worker.
Separate read-only status, reversible qualification jobs, and privileged
irreversible jobs. Authenticate the caller; journal who requested and authorized
the operation. A lane identifier is an addressing label, not authorization.

Network layout: host management NIC reaches scope and trusted infrastructure;
the DUT NIC/VLAN offers only the DHCP/TFTP/test services required by the job.
Disable routing/bridging between them. Bind services to the appropriate address,
and firewall DUT access to host management, signers and scope. Test this with a
deliberately untrusted DUT image.

Package the host service and Pico firmware reproducibly through Nix in a later
implementation. Suggested adapter boundaries:

| Adapter | Responsibilities |
| --- | --- |
| `fixture` | Pico identity/boot epoch, output states, rail telemetry and guarded sequencing |
| `usb` | YKUSH identity, port state/readback and commissioned startup policy |
| `media` | SDWire route, block-device correlation, write/flush/readback |
| `console` | Stable UART identity, 115200 8N1, timestamped bounded capture |
| `scope` | SCPI identity/setup/arm/status/raw traces/screenshots |
| `zynq` | Qualified JTAG access, read-only lifecycle inspection and separately privileged operations |
| `artifacts` | Public manifest/signature verification; restricted access to personalized images |
| `evidence` | Durable job journal, artifact hashes and secret-free results |

The JTAG backend must be proven with the Cora's onboard bridge and exact part.
Do not assume a generic FTDI configuration or ELF download sequence is enough.
Any AMD programmer dependency must be explicitly packaged or documented as an
unresolved adapter dependency; it must not silently introduce a manual vendor
installation step into the Nix image build. Image building and provisioning are
separate environments.

## Controller protocol v1 proposal

USB CDC, newline-delimited JSON, bounded message size. Each request carries
`protocol`, `request_id`, `controller_boot_id`, `lane_session_id`, and `op`.
Replies echo those values, include a monotonic timestamp, observed outputs and
an outcome (`ok`, `rejected`, `failed`, `uncertain`). Reconnection begins with
read-only `hello`; it does not initialize outputs to a desired host state.

| Operation | Meaning / required precondition |
| --- | --- |
| `hello`, `status`, `sample` | Read identity, firmware digest, reset cause, outputs and measured rails |
| `claim` | Establish a new lane session only after host reconciliation |
| `power_off` | Approved reversible state, no provision hold; perform qualified reset/USB coordination |
| `power_on` | Explicit requested state; media/boot route already settled |
| `set_boot_mode` | `sd` or `jtag`; accepted only after measured off state |
| `pulse_reset`, `pulse_srst` | Bounded duration from qualified profile; rejected during provision hold |
| `provision_hold_enter` | DUT on, reset released, stable telemetry; persist hold state before ACK |
| `provision_hold_status` | Read hold identity and any reset/fault event |
| `provision_hold_release` | Explicit reconciliation and matching completed/aborted operation identity |

The actual Pico cannot directly observe the USB mux/hub state; the host owns
those checks. Firmware guards what it can measure and control, while the
orchestrator enforces the whole-lane invariant. This is an operational interlock,
not a tamper-proof boundary against a compromised trusted host.

Duplicate request IDs within an epoch return the previous result without
repeating a transition. A changed boot epoch invalidates all prior sessions;
the host never resends a state-changing command simply because it missed an
ACK. Persist only infrequent hold transitions with a power-failure-tolerant
journal; do not wear Pico flash by recording every sample or relay action.
An unreadable hold journal requires reconciliation.

On firmware startup, initialize the de-energized defaults described in hardware.md
and prohibit sequencing until claimed. A persisted provision hold forbids power,
boot-strap, reset and firmware-update operations. A watchdog reset must not
start a recovery sequence. Host loss holds outputs; timeout is never a request
to reset a target. Disable bootloader/reboot behavior on USB DTR or baud changes.

## Reversible image/boot transaction

1. Acquire the lane/instrument locks. Identify every device; verify fixture,
   wiring, calibration and software profile hashes. Reject unknown identities.
2. Record input image length/digest and expected boot result. Stop DHCP/TFTP or
   update agents that could introduce an unintended boot path.
3. Stop target software gracefully when possible. Disconnect Cora JTAG/UART
   through YKUSH port 1 and establish the commissioned SDWire off topology.
4. Apply the qualified shutdown sequence. Observe rail decay and require the
   off predicate plus independent scope confirmation of the three critical
   rails; a fixed sleep alone never establishes power-off.
5. Enable SDWire USB, select HOST and recheck that DUT rails remain off. Resolve
   the card's block device by USB ancestry/serial, size and expected identity.
   Refuse mounted devices, host system disks, unexpected capacity or ambiguity.
6. Write the candidate image, flush the device, then read back the complete
   written byte range and verify its digest. Define/sanitize any remaining
   addressable media according to the job's data policy; a successful image
   digest does not establish secure erasure of an SD card's hidden flash.
7. Unmount/eject the reader as required, return the mux to DUT, and establish the
   qualified USB power state. Verify observed routing and off rails again.
8. Select SD or JTAG while off; wait the measured relay settling interval.
   Configure the scope and confirm it is armed before commanding power.
9. Power on and capture the selected boot class. Collect console/network
   observations, scope traces and rail telemetry. Correlate all with this job.
10. Store the result, expected-versus-observed comparisons and evidence hashes.
    Leave the lane in an explicitly recorded state. Do not power-cycle merely
    because the result parser or evidence upload failed.

Two boot classes must remain distinct:

- **Native cold boot:** reset contacts released during power-up. Captures the
  board's native PMIC/POR sequencing. Cora USB may be attached before power only
  if commissioning demonstrated acceptable no-back-power behavior.
- **Instrumented held-reset boot:** only after proving that RESET can hold POR
  with the required rails powered, assert it, power the board, enumerate UART,
  open the console without DTR reset, then release RESET. This can capture early
  boot logs. It does not substitute for native power-sequence qualification.

If neither pre-attached USB nor held-reset startup is acceptable, record the
early-console capture limitation and qualify a separate receive-only UART
attachment before requiring unattended early-boot diagnostics. Never report
missing FSBL output as positive evidence of ROM rejection.

## Rigol capture adapter

Connect over management Ethernet using SCPI (VXI-11 client is a candidate).
Confirm `*IDN?`, model, serial and firmware. Configure channel enable, probe
attenuation, DC coupling, scale/offset, timebase, memory depth and trigger for
every job; do not depend on front-panel settings left by a person. [I1]

Arm a single acquisition and observe the trigger-ready state before toggling
the relay. Network commands schedule the operation; the scope supplies timing
measurements. Fetch all four channels from the same stopped acquisition, with
waveform preambles and any required transfer chunks. Verify lengths, sample
intervals, trigger status, clipping and coverage before analyzing thresholds.

Save raw samples/preambles, acquisition settings, computed measurements and a
screenshot. A timeout, truncated trace, missing pre-trigger interval, disabled
channel or borderline voltage/time margin is an invalid/inconclusive capture.
The Pico's slow ADC readings cannot fill gaps in a transient waveform.

## Irreversible transaction

No fuse addresses, write commands or secret payloads are defined here. A future
qualified operation adapter supplies exact device/field semantics. Required
transaction order:

1. Require completed fixture gates and security implementation gates for this
   exact board/part/tool/profile. Inspect actual lifecycle state read-only.
2. Verify a target-bound authorization covering operation ID, expected prior
   state, intended public post-state, public key/artifact identities and policy.
   A build result or capability manifest is not authorization.
3. Prove the approved recovery path first. Verify power backup, stable rails,
   measurement readiness and any device temperature/voltage requirements from
   the operation's AMD documentation. Obtain protected inputs outside Nix.
4. Write and durably sync intent before dispatch. Enter the Pico provision hold
   and freeze other mutating adapters. Launch the operation exactly once.
5. Persist a returned outcome and independently inspect permitted public
   postconditions. Do not assume secret fuse contents can be read back.
6. If dispatch may have occurred but completion cannot be established, record
   `UNCERTAIN`. Keep power, prohibit automatic retry/recovery/reset, and use a
   separately authorized reconciliation procedure. Host restart resumes here.
7. Release the hold only after reconciled completion/abort. Perform any required
   post-programming power cycle as a new explicitly permitted step, then run
   enforcement tests. Apply final debug restrictions only after recovery and
   post-lock observation paths have passed.

Ordinary power-interruption tests operate on reversible workloads. Interruption
during a real fuse write is a separately authorized destructive experiment on
a designated sacrificial device, never part of generic fault injection.

## Evidence and retention

Each job records: schema/version; operation ID; requesting/authorizing identities;
lane/controller boot IDs; tool/firmware/harness/calibration/profile digests;
target correlation; exact public artifact digests; expected result; observations;
result classification; UTC timestamps and monotonic durations; raw evidence
paths/digests; and reconciliation status. Clock failure must be visible.

Distinguish `passed`, `failed`, `inconclusive`, `unsupported`, `not_run`, and
`uncertain`. A silent UART is an observation, not an authentication result.
The station's signed report is an endorsement by the station, not device
hardware attestation.

Keep public results separate from restricted evidence and personalization.
Serial/JTAG captures can contain secrets: allowlist/redact before publication,
and prevent keys/PINs/plaintext unlock material from entering logs, argv, Nix
stores or binary caches. Store restricted working data outside the repository;
pin and retain authorized recovery material under the organization's policy.

The example lane file contains no live serial numbers, IP addresses, credentials
or enabled programming policy. Implement schema validation and reject missing
required identities/gates before any mutation.
