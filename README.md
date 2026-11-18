# TipJar — Tip anyone by their .ai name

**TipJar** is a tiny dApp for the [Binance Agent ID Hackathon](https://www.binance.com/en/support/announcement/detail/95f5dbe0ea674a48a739b59e046648bf): send BNB to someone using only their Agent ID name (e.g. `kobong.ai`) — no wallet address needed.

## How it works

1. You type a name (`kobong.ai`) and an amount of BNB.
2. The TipJar contract resolves the name **on-chain** through the SPACE ID Agent ID contract (ERC-721, `tokenId = keccak256(bare name)` → `ownerOf(tokenId)`).
3. Your BNB is forwarded to the name owner **in the same transaction**.

No address book, no off-chain database, no middleman.

## Security model (deliberate)

- **The contract holds no funds.** Every tip is forwarded immediately.
- **No owner, no pause, no fees, no withdraw function.** There is no privileged account and nothing that can move user funds.
- **No `receive()`/`fallback()`.** Plain transfers revert, so BNB can only enter through `tip()`, which always forwards it.
- **A tip to an unclaimed name reverts; a tip to an address that rejects BNB reverts.** No funds can get stuck through `tip()`.
- **No QR-code login, no session storage, no transaction-confirmation bypass.** The frontend only asks your wallet to confirm the tip transaction — nothing else. Your seed phrase / private key never leave your wallet.

## Contracts

| Network | TipJar | Agent ID registry |
|---|---|---|
| BNB Smart Chain (mainnet, 56) | _to be deployed_ | `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` (SPACE ID Agent ID, real) |
| BSC testnet (97) | _to be deployed_ | MockAgentID (testnet-only mock — the real Agent ID contract is mainnet-only; verified: no code at that address on chain 97) |

## Try it

Live demo: **https://hardi24.github.io/tip-by-ai/** (after the testnet deploy)

1. Connect your wallet (Binance Wallet / any injected wallet).
2. Enter a name and an amount, check the resolved address preview.
3. Confirm the tip in your wallet. The tip appears in "Recent tips".

## Development

Requires [Foundry](https://getfoundry.sh/).

```bash
forge build
forge test                                    # unit tests (mock registry)
forge test --match-contract TipJarForkTest \
  --fork-url https://bsc.publicnode.com       # fork tests vs the REAL Agent ID contract
```

### Deploy (testnet)

```bash
# 1. Get testnet BNB for a throwaway deployer from
#    https://www.bnbchain.org/en/testnet-faucet
# 2. Deploy mock registry + TipJar:
forge script script/DeployTestnet.s.sol \
  --rpc-url https://bsc-testnet.publicnode.com \
  --private-key <throwaway-testnet-key> --broadcast
# 3. Verify on Sourcify (no API key needed):
forge verify-contract --verifier sourcify <address> src/TipJar.sol:TipJar \
  --chain-id 97
```

### Deploy (mainnet)

```bash
forge script script/Deploy.s.sol \
  --rpc-url https://bsc.publicnode.com \
  --private-key <mainnet-deployer-key> --broadcast
```

Mainnet deploy cost (measured by dry run): **~1,106,218 gas** for the TipJar deployment — under 0.002 BNB at any normal gas price. A `tip()` call costs ~70k gas (measured on a mainnet fork). The deployer key must be funded and confirmed by the wallet owner; never commit a private key.

## Project status

- [x] Contract written + unit tests (10/10) + mainnet fork tests (3/3)
- [x] Name resolution verified on-chain: `ownerOf(keccak256("kobong"))` = the kobong.ai wallet
- [x] Frontend (static, GitHub Pages)
- [ ] Testnet deploy (blocked: testnet BNB faucet needs a captcha solve in a browser)
- [ ] Source verification on BscScan testnet
- [ ] Mainnet deploy (needs wallet owner confirmation + ~0.002 BNB)
- [ ] Hackathon submission (project name, website, contract addresses, Agent ID usage description) — submission closes 9 Dec 2026 08:00 UTC

## License

MIT
