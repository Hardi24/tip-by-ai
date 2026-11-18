# Hackathon Submission Draft — TipJar

**Status: DRAFT — do not submit yet.** Testnet deploy is blocked on
testnet BNB (faucet needs a browser captcha solve); mainnet deploy
needs the wallet owner's confirmation. The project-submission form
URL has not been published in the announcement yet — check
@BinanceWallet on X or web3.binance.com before the deadline.

## Project

- **Name:** TipJar
- **Tagline:** Tip anyone by their Agent ID (.ai) name — no wallet address needed.
- **Website (live demo):** https://hardi24.github.io/tip-by-ai/
- **Source code:** https://github.com/Hardi24/tip-by-ai (MIT, public)
- **Team:** solo — Hardi24 (Agent ID: kobong.ai)
- **Category:** Agent Application Innovation Award (and Pioneer Award metrics if applicable)

## Contracts

| Network | Contract | Address |
|---|---|---|
| BNB Smart Chain (56) | TipJar | _TODO after mainnet deploy_ |
| BNB Smart Chain (56) | Agent ID registry (used) | `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` |
| BSC testnet (97) | TipJar | _TODO after testnet deploy_ |
| BSC testnet (97) | MockAgentID (testnet-only) | _TODO after testnet deploy_ |

## How TipJar uses Agent ID

Agent ID is the core of the product, not an add-on:

1. **Identity as the address.** A user tips by typing a name (`kobong.ai`).
   TipJar resolves it on-chain: `tokenId = keccak256("kobong")`, then
   `ownerOf(tokenId)` on the SPACE ID Agent ID contract returns the
   recipient's wallet. The name *is* the payment address.
2. **Access control by ownership.** Only the wallet holding the name
   receives the tip — the contract enforces it on-chain; there is no
   off-chain mapping to tamper with.
3. **No other identity system exists in the product.** There are no
   usernames, no accounts, no database. Agent ID is the only identity.

## What it does (one paragraph for the form)

TipJar lets anyone send BNB to any Agent ID holder by typing their
`.ai` name. The smart contract resolves the name to a wallet through
the Agent ID registry and forwards the tip in the same transaction.
The contract holds no funds, has no owner, no fees and no withdraw
function — the name owner is the only one who can ever receive the
money, and only as the direct result of a tip someone chose to send.

## Red-line compliance

- No web-based QR-code login for Agentic Wallet; no stored login sessions.
- No prompts that bypass user transaction confirmation — the user confirms
  the tip in their own wallet.
- No scheduled/automatic transfers, no transfers to fixed addresses.
- No promises of returns or passive income anywhere in the product.
- Contracts are open-source; TipJar has no owner permissions at all
  (no mint, pause, freeze, or withdraw).
- No collection of seed phrases, private keys, API secrets, or pairing codes.
- Project name contains no "Binance"/"BNB" branding.

## Reward receiving address

_TODO — to be confirmed by the project owner at submission time._

## Checklist before submitting

- [ ] Testnet deploy done + source verified (BscScan testnet / Sourcify)
- [ ] Mainnet deploy done + source verified on BscScan
- [ ] Frontend `app.js` points at the MAINNET contract, demoed end-to-end
- [ ] Submission form URL found (announcement / @BinanceWallet)
- [ ] Reward receiving address confirmed by owner
- [ ] 30+ Agent ID addresses interacting with the contract during the
      submission period (Innovation Award eligibility) — needs promotion
