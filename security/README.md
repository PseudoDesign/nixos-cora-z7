# Generic Zynq-7000 security foundation

## Direction and current status

Raspberry Pi remains Kaiba's first production-release target. This repository
develops reusable Zynq-7000 security mechanisms, using the Cora Z7-07S as the
first board implementation. A Kaiba provisioning profile will consume those
mechanisms later. No enrollment or fleet-specific policy belongs in this layer.

The current image is a development image: unsigned BOOT.BIN, U-Boot/extlinux,
and an ordinary ext4 system root. The source-driven Vivado hardware workflow
and hashed SDT release importer exist. Actual board boot remains unverified.
Authenticated boot, encrypted storage, fuse operations, and trusted-world
services described below are implementation targets, not existing guarantees.

`capabilities.json` is a versioned, machine-readable description of source
implementation status. `nix build .#security-capabilities` exports the same
file without building a system image or requiring a hardware release. It is
not device evidence, attestation, or permission to provision anything. Consumers
must pin a repository revision and explicitly adopt the draft interface.

## Ownership boundary

| Layer | Responsibility |
| --- | --- |
| Generic Zynq-7000 implementation | Boot artifact formats, authentication/encryption integration, verification, fuse-field interpretation, and low-level device operations |
| Cora board adapter | Exact part, board revision, PS/PL design, SDT, pin/power/debug topology, storage layout, and applicable test results |
| External signer/personalizer | Private-key custody, approved use of signing/encryption keys, device-specific protected material, and private recovery custody |
| Future Kaiba provisioning profile | Select required mechanisms, bind a physical lane and target, authorize operations, retain evidence, and decide qualification |
| Kaiba Fleet / identity services | Assign identity, enroll, activate, issue credentials, authorize workloads, quarantine, revoke, and recover membership |

Reusable family code can initially stay in this repository. Extract a separate
package only when another board actually needs it. A board-specific successful
test must never become an unqualified claim for every Zynq-7000 part or board.

## First implementation: authenticated system boot

Build an opt-in authenticated-boot configuration alongside the development
configuration. It must not silently fall back to development boot on failure.

1. ROM authenticates FSBL against the provisioned RSA trust anchor.
2. FSBL authenticates all subsequent security-critical partitions, including
   FPGA configuration and U-Boot. Embed U-Boot's required FIT verification key
   in its authenticated image, or equally authenticate its control FDT.
3. U-Boot requires signed FIT configurations binding the kernel, initrd and
   Linux device tree. Security-critical boot arguments and the verity root
   digest must come from authenticated content and cannot be overridden by
   mutable environment, extlinux, scripts, or an unrestricted console.
4. Initrd enforces dm-verity for the complete immutable system root. Mutable
   state cannot supply executable startup hooks, modules or configuration that
   bypasses the authenticated system policy.
5. Updates and recovery preserve this chain. Every reachable boot path must
   have an explicit authentication policy. An invalid image can enter only an
   authorized recovery environment or stop.

Each release binds the hardware release digest (including bitstream and SDT),
FSBL, U-Boot, FIT configuration, system root, layout and recovery artifacts.
Hashes identify exact bytes; the appropriate signature establishes authority.
FPGA configuration is security-critical because it can introduce bus masters.
Runtime reconfiguration stays disabled until its own authenticated path exists.

The developer-selected trust roots are inputs. This repository must not ship a
universal production key, select a fleet namespace, contact a fleet authority
to authorize boot, or assume one organization's signer implementation.

## Build, signing and personalization interfaces

Public Nix derivations produce unsigned signing inputs, public manifests,
verification tools, and final image assembly tools. An explicit external step
uses an organization's signing provider; independent verification checks the
result before final assembly. A digest-specific signing request must bind the
artifact kind, algorithm/parameters, public key identity and exact input bytes.
AMD Bootgen and FIT formats need their own validated adapters; do not assume
an existing generic RSA/PIV signing command can sign both formats correctly.

Private keys, AES keys, plaintext unlock secrets, PINs and device personalization
must stay outside Nix expressions, derivations, stores, binary caches, command
arguments and public logs. Private per-device assembly runs in an explicitly
private workspace outside the public build graph. It must produce a public,
secret-free description separately from protected per-device artifacts.

Host verification proves artifact properties under supplied public anchors.
It cannot prove that a device has the expected fuse state or will enforce the
chain. Physical acceptance remains a separate result.

## Storage and identity primitives

Qualify local offline unlock first. A candidate is a per-device encrypted,
authenticated early-boot payload protecting an independent storage-unlock
secret. Validate the supported AMD container/decryption path, device binding,
confidential transfer, lifetime and erasure of plaintext, and recovery before
selecting it. This is a feasibility target, not an existing sealed-key API.

The Zynq eFUSE/BBRAM AES key is consumed by the hardened decryptor; it is not a
Linux-readable root key or a general HMAC/TLS signing service. Do not derive an
unlock key from a public serial, MAC address or device identifier. Keep boot
signing, image encryption, storage unlocking and operational identity purposes
separate. Device-unique keys are required wherever clone resistance is claimed.

Encrypted storage with software operational keys can protect against copied
media while still trusting the running kernel. Label that boundary explicitly.
A later TrustZone service could isolate keys from Linux, but needs a qualified
secure monitor, protected memory/peripheral/PL access, restricted operations,
entropy, lifecycle and update/recovery design. Key isolation does not itself
prevent compromised callers from abusing authorized signing operations.

Remote attestation requires protected measurement collection, an endorsed key,
freshness and an independent appraisal policy. A signed version string or TLS
handshake is not sufficient. Neither remote attestation nor offline rollback
protection is implied by ordinary authenticated boot. Provide these as distinct
future capabilities rather than inventing guarantees in a capability manifest.

## Hardware operations and evidence boundary

The [station design](../station/README.md) specifies the physical lane,
interlocks, evidence capture and commissioning needed to exercise these
interfaces. It keeps irreversible operations disabled until both the fixture
and the relevant Zynq operation adapter are qualified.

Keep read-only inspection separate from state-changing operations. The eventual
low-level interface should describe an exact target-bound operation and its
expected preconditions/postconditions. Fuse programming, debug lock changes and
key injection must never run as an image build, boot-time default, package
installation hook, or an implicit part of an inspection command.

External orchestration owns approval, exclusive access, intent journaling,
execute-once behavior and reconciliation. A low-level timeout or interrupted
fuse operation returns an uncertain outcome; it must not automatically repeat
the write. A matching existing state is an observation, not evidence that a
new programming operation succeeded. Already-owned devices need an explicit
maintenance/recovery path rather than replaying initial ownership.

Evidence adapters should retain expected and observed public values, target
correlation, tool/artifact/profile digests, outcome, and raw-evidence references.
Never export secret fuse contents, private keys, unlock data, or unfiltered
debug output. Distinguish unavailable, unknown, unsupported and failed results.
The orchestrator can endorse observations; a target self-report is not thereby
hardware attestation. Preserve an observation path that still works after the
approved debug restrictions are applied.

## Qualification and implementation order

1. Boot the existing development image and establish a hardware test baseline.
2. Implement and host-test required FIT verification and verity-root assembly.
3. Add ROM/FSBL authentication and signer integration, then physically test the
   full chain and every alternate boot/recovery path on development hardware.
4. Qualify device-bound offline storage and per-device personalization.
5. Implement read-only security-state inspection, explicit provisioning/debug
   operations and interruption/reconciliation tests for the board adapter.
6. Qualify signed update/recovery and record the complete supported threat model.
7. Build the Kaiba profile around version-pinned interfaces and retained results.
   Stronger isolation and attestation remain separate qualification work.

Required negative tests include altered boot stages/bitstreams/FIT components,
substituted boot arguments or verity roots, modified system data, unauthorized
recovery, reachable debug bypasses, copied media on a second functioning device,
and interrupted updates/provisioning. A denied boot must not expose secrets or
an unrestricted fallback shell. Positive tests include cold offline boot, local
private-data access and authorized recovery. Record older-signed-image behavior;
rejecting those images is a profile choice, not an implicit test requirement.

Software tests and host signature checks do not close physical qualification.
No Kaiba enrollment or production approval is implied by completing an artifact
build. Pi remains the first production path while this platform matures.

## References

- [AMD Zynq-7000 device secure boot (UG585)](https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Device-Secure-Boot)
- [AMD secure boot support (UG821)](https://docs.amd.com/r/en-US/ug821-zynq-7000-swdev/Secure-Boot-Support)
- [U-Boot signed FIT configurations](https://docs.u-boot.org/en/latest/usage/fit/signature.html)
- [Linux dm-verity](https://docs.kernel.org/admin-guide/device-mapper/verity.html)
