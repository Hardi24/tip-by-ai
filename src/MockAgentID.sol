// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice TESTNET-ONLY mock of the SPACE ID Agent ID registry.
/// @dev The real Agent ID contract (0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F)
///      exists on BNB Chain MAINNET only — there is no deployment on BSC
///      testnet (verified: no code at that address on chain 97). This mock
///      reproduces the exact interface TipJar depends on (ownerOf with
///      ERC-721-style revert for unclaimed names) so the full tipping flow
///      can be demonstrated on testnet. NEVER use this mock on mainnet:
///      mainnet deployments must point TipJar at the real Agent ID contract.
contract MockAgentID {
    mapping(uint256 => address) public owners;

    error ERC721NonexistentToken(uint256 tokenId);

    function mint(string calldata name, address to) external {
        owners[uint256(keccak256(bytes(name)))] = to;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = owners[tokenId];
        if (owner == address(0)) revert ERC721NonexistentToken(tokenId);
        return owner;
    }
}
