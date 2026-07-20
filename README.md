# Tracercoin Wallet (TFX)

The wallet for the **Tracercoin** network — an independent, sovereign Scrypt Proof-of-Work
blockchain. This is the tool community members use to **send and receive TFX**, hold their
coins under their own keys, and **file fingerprints** (permanent on-chain proofs) to the
chain.

> Part of the Tracercoin stack. Chain: `github.com/Tracerfx123/blockchain` · Website:
> https://tracercoin.org

---

## What it does

- **Send / receive TFX** on the Tracercoin network (`tfx1…` addresses).
- **Self-custody** — keys stay with the user; the wallet holds no third-party funds.
- **File fingerprints** — compute a content hash and write a compact proof to the chain
  (fee routes to treasury; Tracercoin never burns tokens).
- Holds the vested dev/treasury allocation via a transparent, time-locked policy.

This wallet is utility software for transacting and recording proofs. It makes no
representation about price, return, yield, or profit.

## Requirements

- A synced `tracercoind` node (see `github.com/Tracerfx123/blockchain`), or a bundled
  light backend, reachable over **localhost RPC (port 9556)**. RPC is never exposed
  publicly.

## Security

- Private keys never leave the user's device.
- Encrypt the wallet and back up your keys/seed. Loss of the passphrase means loss of
  funds — there is no recovery authority.
- Node RPC is bound to localhost only.

## Related repositories

- **Chain / daemon** — `github.com/Tracerfx123/blockchain`
- **Mining pool** — `github.com/TraceRcoin/minerpool`
- **Exchange (non-custodial)** — `github.com/TraceRcoin/exchange`

## License

Released under the terms of the MIT license.
