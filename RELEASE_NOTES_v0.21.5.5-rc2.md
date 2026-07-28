# Tracercoin Core Wallet — v0.21.5.5-rc2 (pre-release)

> **Status:** Pre-release for testers. The Tracercoin mainnet is **not live yet** —
> this build is for installation, wallet, and interface testing on regtest/testnet.
> Do **not** treat balances as real funds until mainnet launch is announced.

## What's new in rc2
- **Full Tracercoin branding on every tool.** The daemon, CLI, transaction tool, and
  wallet tool now identify themselves as `tracercoind`, `tracercoin-cli`,
  `tracercoin-tx`, and `tracercoin-wallet` in all usage banners, help text, RPC help
  examples, and error messages — matching the actual binary names. No more residual
  "litecoind" strings in the user-facing surface.
- **`getblocktemplate` now publishes the consensus treasury payment.** Mining/pool
  software that builds its own coinbase receives a `treasury` object (`amount`,
  `scriptpubkey`, `address`, `required`) telling it exactly which output the block
  must include. `coinbasevalue` is the miner's share, already net of the treasury.
  This is required for pool software — blocks omitting the treasury output are
  rejected `bad-cb-treasury` from height 1 onward.

Carried forward from rc1: real Win64 binaries + installer (not the Litecoin
brandtest), and the consensus 2% treasury dev fee.

## Downloads
- `tracercoin-0.21.5.5-win64-setup.exe` — Windows installer
- `SHA256SUMS.txt` — verify your download before installing

## ⚠️ Windows SmartScreen / unsigned installer
This installer is **not yet code-signed**, so Windows SmartScreen will show a
**"Windows protected your PC"** warning, and some antivirus may flag it as unknown.
This is expected for an unsigned pre-release build — it does **not** mean the file is
unsafe. To install:

1. Verify the SHA-256 of your download matches `SHA256SUMS.txt`.
2. When SmartScreen appears, click **More info → Run anyway**.

A code-signing certificate will be purchased and applied **before any wide public
launch**, which will remove this warning. (Tracking item.)

## Prerequisites
- 64-bit Windows 10 or later.
- Disk space for the block chain (grows over time; small during testnet).

## Verifying your download
```
CertUtil -hashfile tracercoin-0.21.5.5-win64-setup.exe SHA256
```
Compare the output against the matching line in `SHA256SUMS.txt`.

---
*Pre-release. Superseded by later builds as the chain approaches mainnet launch.*
