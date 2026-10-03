# AMD 2026.1 release sources. Hashes are unpacked NAR hashes.
{ fetchFromGitHub }:
let
  fetch = repo: rev: hash: fetchFromGitHub {
    owner = "Xilinx";
    inherit repo rev hash;
  };
in {
  embeddedsw = fetch "embeddedsw" "2fb454742f9d42e23a46a13c0eb09e29dc52c6d1"
    "sha256-Mjmv/y4cy6AdMeMXzmqF2kZtMsNIJslujaDoLb9aoMo=";
  libmetal = fetch "libmetal" "ba381ae6281b70d91b42a39ce6b9d5fb46259098"
    "sha256-7NtTDy6mRvU7ZmTlfHXGHjyJW3AxVSUUUWK8CXFbX+Y=";
  bootgen = fetch "bootgen" "e576e5e1e227a74c31e54607623c1bb7f38eec12"
    "sha256-gz15FkMQ5aQahGVLe0k6KDA/1WhTVIZUA4qCq2iWTFM=";
  lopper = fetch "lopper" "05dc7e4bf359b60f1e6f7ed7074740afd7955a63"
    "sha256-nGFA8/6GP7/jTFVqNjwE+tukyMGXhOdy4DPl/etMstA=";
  # AMD's 2026.1 Yocto recipe pins the LTS tree at 6.18.10; the
  # xilinx-v2026.1 tag itself is 6.18.0. Use the recipe's exact revision.
  linux = fetch "linux-xlnx" "4f7afe14f7246986ca858d9a0880f5db6ba02a4b"
    "sha256-VVlhEDcf+K9yAedmWa/dwba7kuVC0KHHURqooqw8gx4=";
  uboot = fetch "u-boot-xlnx" "9a86d4351c5e29db068a2a0e230b74d4fbd55997"
    "sha256-0C3ZK6MYcJxSSHSe4gNrh2lozPR8xedmxkTwt+Q5/AM=";
}
