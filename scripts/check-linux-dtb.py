#!/usr/bin/env python3
"""Check essential 07S topology in the actual Lopper-derived Linux DTB."""
import subprocess
import sys

dtb = sys.argv[1]


def prop(node, name, kind="s"):
    result = subprocess.run(["fdtget", "-t", kind, dtb, node, name],
                            capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def nodes(node="/"):
    yield node
    names = subprocess.check_output(["fdtget", "-l", dtb, node], text=True).splitlines()
    for name in names:
        yield from nodes(node.rstrip("/") + "/" + name)


def require(condition, message):
    if not condition:
        sys.exit("Invalid Cora Z7-07S Linux DTB: " + message)


all_nodes = list(nodes())
cpus = [n for n in all_nodes if prop(n, "device_type") == "cpu"]
require(len(cpus) == 1 and prop(cpus[0], "reg", "x") == "0", "expected only CPU0")
require("xlnx,zynq-7000" in (prop("/", "compatible") or ""), "wrong SoC")
require(prop("/chosen", "stdout-path") == "serial0:115200n8", "wrong serial console")
for alias in ["serial0", "mmc0", "ethernet0"]:
    path = prop("/aliases", alias)
    require(path in all_nodes, f"missing {alias}")
    require(prop(path, "status") in [None, "okay", "ok"], f"{alias} is disabled")
ethernet = prop("/aliases", "ethernet0")
require(prop(ethernet + "/ethernet-phy@1", "reg", "x") == "1", "PHY must be at MDIO address 1")
require(not any("ptm@f889d000" in n for n in all_nodes), "CPU1 trace unit still present")
require(not any(n.endswith("/funnel@f8804000/in-ports/port@1") for n in all_nodes), "CPU1 trace endpoint still present")
memory = [n for n in all_nodes if prop(n, "device_type") == "memory"]
require(bool(memory), "missing RAM")
address_cells = int(prop("/", "#address-cells", "x"), 16)
size_cells = int(prop("/", "#size-cells", "x"), 16)
require(address_cells in [1, 2] and size_cells in [1, 2], "unexpected memory cell sizes")
ranges = []
for node in memory:
    cells = [int(v, 16) for v in (prop(node, "reg", "x") or "").split()]
    stride = address_cells + size_cells
    require(len(cells) % stride == 0, "malformed RAM range")
    for start in range(0, len(cells), stride):
        base = size = 0
        for cell in cells[start:start + address_cells]:
            base = (base << 32) | cell
        for cell in cells[start + address_cells:start + stride]:
            size = (size << 32) | cell
        ranges.append((base, base + size))
require(ranges == [(0, 0x20000000)], f"expected 512 MiB RAM at 0, found {ranges}")
print("Validated Linux DTB: one Cortex-A9, 512 MiB RAM, UART0, SD0, GEM0/PHY1")
