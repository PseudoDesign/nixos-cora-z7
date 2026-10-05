# Source register

Reviewed 2026-10-04. URLs are references, not pinned build dependencies.
Before releasing the assembled fixture, record applicable document revisions,
local document hashes and the exact board/firmware variants in its private
qualification record. The design contains original engineering choices as well
as manufacturer facts; a product specification alone does not qualify a fixture.

| ID | Source | Used for |
| --- | --- | --- |
| C1 | [Digilent Cora reference manual, manufacturer-authored PDF hosted by DigiKey](https://media.digikey.com/pdf/Data%20Sheets/Digilent%20PDFs/Cora_Z7_RM_Web.pdf) | Power, JP1/JP2/JP3, USB, boot and reset behavior |
| C2 | [Digilent Cora product/resource links](https://digilent.com/shop/cora-z7-zynq-7000-single-core-for-arm-fpga-soc-development/) | Part/variant and schematic entry point; matching Rev B schematic/pad map remains to be resolved |
| R1 | [Micro Center Inland KS0212 listing](https://www.microcenter.com/product/643966/inland-rpi-4-channel-relay-5v-shield-for-raspberry-pi-ce-certification) | Manufacturer part KS0212, SKU 350892 |
| R2 | [Keyestudio KS0212 documentation](https://docs.keyestudio.com/projects/KS0212/en/latest/docs/KS0212%20keyestudio%20RPI%204-channel%20Relay%20Shield.html) | 5 V supply, relay ratings, GPIO mapping and example code |
| P1 | [Adafruit QT Py RP2040 pinouts](https://learn.adafruit.com/adafruit-qt-py-2040/pinouts) | Power diode, USB-host jumper, pad functions and separate I2C buses |
| P2 | [Adafruit board pin definitions](https://github.com/adafruit/circuitpython/blob/main/ports/raspberrypi/boards/adafruit_qtpy_rp2040/pins.c) | Exact pad-to-RP2040-GPIO mapping |
| S1 | [3mdeb SDWire](https://shop.3mdeb.com/product/sdwire/) | USB card reader/control and microSD mux |
| S2 | [Dasharo SDWire specification](https://docs.dasharo.com/transparent-validation/sd-wire/specification/) | Architecture; no integrated DUT power switch |
| S3 | [3mdeb shipping FAQ](https://3mdeb.com/faq-shop/) | US shipping policy; freight/import costs remain checkout-dependent |
| Y1 | [YKUSH3 v1.2.1 datasheet](https://www.yepkit.com/uploads/documents/9f39a_ykush3-datasheet.pdf) | External supply, connectors, power/data switching, control and default states |
| Y2 | [YKUSH3 product page](https://www.yepkit.com/product/300110/YKUSH3) | Current board offering; supplied hardware/firmware revision must be recorded |
| H1 | [uhubctl upstream documentation](https://github.com/mvp/uhubctl#raspberry-pi-5) | Pi 5 ganged USB power; topology-dependent bus identifiers |
| A1 | [TI ADS1115 datasheet](https://www.ti.com/lit/ds/symlink/ads1115.pdf) | Supply/input limits, conversion timing, PGA and I2C addresses |
| A2 | [Adafruit ADS1115 breakout #1085](https://www.adafruit.com/product/1085) | Selected ADC assembly |
| A3 | [TI TMUX1511 datasheet](https://www.ti.com/lit/ds/symlink/tmux1511.pdf) | Powered-off protection, signal limits, active-high selects and TSSOP-14 package |
| I1 | [Rigol DS1000Z programming guide, manufacturer-authored mirror](https://manualzz.com/doc/61496036/rigol-ds1054z--ds1104z-plus--mso1074z-s-programming-manual) | USB/LAN SCPI, single acquisition, waveform transfer, screenshot commands |
| I2 | [Rigol DS1000Z product and official document links](https://www.rigolna.com/products/digital-oscilloscopes/1000z/) | DS1054Z four-channel/50 MHz model and manuals |
| Z1 | [AMD advisory 65240: power-on evaluation](https://docs.amd.com/r/en-US/65240/How-do-I-evaluate-if-my-design-is-impacted-during-power-on?contentId=2v8gMtI_u3siG9cVhUi9ug) | Alternative sufficient conditions for PS eFUSE integrity during power-on |
| Z2 | [AMD advisory 65240: power-off evaluation](https://docs.amd.com/r/en-US/65240/How-do-I-evaluate-if-my-design-is-impacted-during-power-off?contentId=4t4iGXvrF3jSnO51INLw9Q) | Alternative sufficient conditions during power-off |
| Z3 | [AMD DS187](https://docs.amd.com/v/u/en-US/ds187-XC7Z007S-XC7Z010-XC7Z014S-XC7Z020-Data-Sheet) | Applicable part electrical/timing limits; exact acceptance values still require review before enabling a profile |

The relay mapping is supported by the product part number and manufacturer's
example. The material retrieved is not a full KS0212 circuit schematic and
does not establish power-up glitches, floating-input behavior or a minimum
contact load. Those properties remain physical acceptance checks.

Likewise, a datasheet describing a switch is not proof that a particular SDWire,
hub, cable and Cora combination has no back-power path. Preserve that distinction
when consuming this design in future provisioning profiles.
