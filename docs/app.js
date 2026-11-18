// TipJar frontend — plain static JS, ethers v6 via CDN.
// ---------------------------------------------------------------------------
// DEPLOYMENT CONFIG — update after each deployment.
// Testnet (BSC testnet, chain 97): fill in after the testnet deploy.
// Mainnet (BNB Smart Chain, chain 56): fill in after the mainnet deploy.
// Set ACTIVE to "testnet" or "mainnet".
// ---------------------------------------------------------------------------
const ACTIVE = "testnet";

const CONFIG = {
  testnet: {
    chainId: 97,
    chainName: "BNB Smart Chain Testnet",
    rpcUrl: "https://bsc-testnet.publicnode.com",
    explorer: "https://testnet.bscscan.com",
    tipJar: "0x0000000000000000000000000000000000000000", // TODO: testnet deploy
    agentId: "0x0000000000000000000000000000000000000000", // TODO: MockAgentID on testnet
  },
  mainnet: {
    chainId: 56,
    chainName: "BNB Smart Chain",
    rpcUrl: "https://bsc.publicnode.com",
    explorer: "https://bscscan.com",
    tipJar: "0x0000000000000000000000000000000000000000", // TODO: mainnet deploy
    agentId: "0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F", // SPACE ID Agent ID (real)
  },
};

const TIPJAR_ABI = [
  "function resolve(string name) view returns (address)",
  "function tip(string name) payable",
  "event Tip(address indexed sender, string recipientName, address indexed recipient, uint256 amount, uint256 timestamp)",
];

const cfg = CONFIG[ACTIVE];
let provider, signer, jar, account = null;

const $ = (id) => document.getElementById(id);

function setStatus(msg, isError) {
  const el = $("status");
  el.textContent = msg;
  el.style.color = isError ? "#b00020" : "#1a7a1a";
}

function renderConfig() {
  $("contractAddr").textContent = cfg.tipJar;
  $("networkName").textContent = cfg.chainName + " (chain " + cfg.chainId + ")";
  $("registryAddr").textContent = cfg.agentId;
}

async function refreshTips() {
  const box = $("tips");
  try {
    const p = new ethers.JsonRpcProvider(cfg.rpcUrl);
    const c = new ethers.Contract(cfg.tipJar, TIPJAR_ABI, p);
    const events = await c.queryFilter(c.filters.Tip, -5000);
    if (!events.length) {
      box.innerHTML = '<span class="muted">No tips yet — be the first.</span>';
      return;
    }
    box.innerHTML = events.slice(-10).reverse().map((e) => {
      const date = new Date(Number(e.args.timestamp) * 1000).toLocaleString();
      const amount = ethers.formatEther(e.args.amount);
      return `<div class="tip"><b>${e.args.recipientName}</b> received <b>${amount} BNB</b><br>` +
        `<span class="muted">from ${e.args.sender} · ${date} · ` +
        `<a href="${cfg.explorer}/tx/${e.transactionHash}" target="_blank" rel="noopener">tx</a></span></div>`;
    }).join("");
  } catch (err) {
    box.innerHTML = '<span class="muted">Could not load tips (contract not deployed on this network yet).</span>';
  }
}

$("connectBtn").addEventListener("click", async () => {
  if (!window.ethereum) {
    setStatus("No wallet found. Install Binance Wallet or another injected wallet.", true);
    return;
  }
  try {
    provider = new ethers.BrowserProvider(window.ethereum);
    const net = await provider.getNetwork();
    if (Number(net.chainId) !== cfg.chainId) {
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: "0x" + cfg.chainId.toString(16) }],
      });
    }
    const accounts = await provider.send("eth_requestAccounts", []);
    account = accounts[0];
    signer = await provider.getSigner();
    jar = new ethers.Contract(cfg.tipJar, TIPJAR_ABI, signer);
    $("account").textContent = "Connected: " + account;
    $("tipBtn").disabled = false;
    setStatus("Wallet connected on " + cfg.chainName + ".");
  } catch (err) {
    setStatus("Connection failed: " + (err.shortMessage || err.message), true);
  }
});

$("nameInput").addEventListener("input", async () => {
  const name = $("nameInput").value.trim();
  const preview = $("preview");
  if (!name) { preview.textContent = ""; return; }
  try {
    const p = new ethers.JsonRpcProvider(cfg.rpcUrl);
    const c = new ethers.Contract(cfg.tipJar, TIPJAR_ABI, p);
    const owner = await c.resolve(name);
    preview.textContent = "Resolves to: " + owner;
  } catch (err) {
    preview.textContent = "This name is not claimed (or the contract is not deployed yet).";
  }
});

$("tipBtn").addEventListener("click", async () => {
  const name = $("nameInput").value.trim();
  const amount = $("amountInput").value;
  if (!name || !amount || Number(amount) <= 0) {
    setStatus("Enter a name and an amount above zero.", true);
    return;
  }
  if (!jar) { setStatus("Connect your wallet first.", true); return; }
  try {
    setStatus("Confirm the tip in your wallet…");
    const tx = await jar.tip(name, { value: ethers.parseEther(amount) });
    setStatus("Sent! Waiting for confirmation… " + tx.hash);
    await tx.wait();
    setStatus("Tip confirmed. Thank you!");
    refreshTips();
  } catch (err) {
    setStatus("Tip failed: " + (err.shortMessage || err.message), true);
  }
});

renderConfig();
refreshTips();
