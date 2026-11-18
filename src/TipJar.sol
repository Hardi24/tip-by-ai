// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal interface of the SPACE ID Agent ID contract (ERC-721).
/// @dev Agent ID lives on BNB Chain at 0x60b9262456de011f7d15a54cdd8c48baaa8b022f.
///      Each name is one non-transferable token; tokenId = keccak256(bare name).
interface IAgentID {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title TipJar — tip anyone by their Agent ID (.ai) name
/// @notice Send BNB to a person using only their Agent ID name, e.g. "kobong.ai".
///         The name is resolved on-chain through the Agent ID contract:
///         tokenId = keccak256(bare lowercase name), owner = ownerOf(tokenId).
///         The tip is forwarded to the name owner in the same transaction.
/// @dev Security model (deliberate, hackathon red-line compliant):
///      - The contract holds no funds: every tip is forwarded immediately.
///      - No owner, no pause, no fees, no withdraw function — there is no
///        privileged account and nothing that can move user funds.
///      - No receive()/fallback(): plain transfers revert, so BNB can only
///        enter through tip(), which always forwards it.
///      - A tip to an unclaimed name reverts; a tip to an address that
///        rejects BNB reverts. No funds can get stuck through tip().
contract TipJar {
    /// @notice The Agent ID registry contract (immutable, set at deploy).
    IAgentID public immutable agentId;

    /// @notice Name is not claimed by anyone.
    error NameNotClaimed(string name);
    /// @notice Name fails Agent ID rules (3-15 chars, lowercase letters/digits).
    error InvalidName(string name);
    /// @notice Tip amount is zero.
    error ZeroTip();
    /// @notice The recipient rejected the BNB transfer.
    error TransferFailed(address recipient, uint256 amount);

    /// @notice Emitted for every successful tip (the on-chain tip history).
    event Tip(
        address indexed sender,
        string recipientName,
        address indexed recipient,
        uint256 amount,
        uint256 timestamp
    );

    constructor(address _agentId) {
        agentId = IAgentID(_agentId);
    }

    /// @notice Resolve an Agent ID name (e.g. "kobong.ai" or "kobong") to its
    ///         owner's wallet address. Read-only, costs no gas when called off-chain.
    /// @param name The Agent ID name, with or without the ".ai" suffix, any case.
    /// @return owner The wallet address that holds the name.
    function resolve(string calldata name) public view returns (address) {
        string memory clean = _normalize(name);
        uint256 tokenId = uint256(keccak256(bytes(clean)));
        try agentId.ownerOf(tokenId) returns (address owner) {
            return owner;
        } catch {
            revert NameNotClaimed(name);
        }
    }

    /// @notice Tip the owner of an Agent ID name. The BNB is forwarded to the
    ///         name owner immediately, in this same transaction.
    /// @param name The Agent ID name of the recipient, with or without ".ai".
    function tip(string calldata name) external payable {
        if (msg.value == 0) revert ZeroTip();
        address recipient = resolve(name);
        (bool ok, ) = recipient.call{value: msg.value}("");
        if (!ok) revert TransferFailed(recipient, msg.value);
        emit Tip(msg.sender, _normalize(name), recipient, msg.value, block.timestamp);
    }

    /// @notice Normalize a name to the Agent ID canonical form: lowercase,
    ///         ".ai" suffix stripped, 3-15 chars of [a-z0-9].
    function _normalize(string calldata name) internal pure returns (string memory) {
        bytes memory raw = bytes(name);
        uint256 len = raw.length;

        // Strip a trailing ".ai" suffix (case-insensitive).
        if (len >= 3) {
            bytes1 c0 = _lower(raw[len - 3]);
            bytes1 c1 = _lower(raw[len - 2]);
            bytes1 c2 = _lower(raw[len - 1]);
            if (c0 == bytes1(".") && c1 == bytes1("a") && c2 == bytes1("i")) {
                len -= 3;
            }
        }

        bytes memory clean = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            bytes1 c = _lower(raw[i]);
            bool okChar = (c >= bytes1("a") && c <= bytes1("z")) ||
                (c >= bytes1("0") && c <= bytes1("9"));
            if (!okChar) revert InvalidName(name);
            clean[i] = c;
        }
        if (len < 3 || len > 15) revert InvalidName(name);
        return string(clean);
    }

    function _lower(bytes1 c) internal pure returns (bytes1) {
        if (c >= bytes1("A") && c <= bytes1("Z")) {
            return bytes1(uint8(c) + 32);
        }
        return c;
    }
}
