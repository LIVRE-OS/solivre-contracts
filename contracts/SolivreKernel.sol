// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SolivreKernel
/// @notice Minimal on-chain anchor for LIVRE OS identity commitments.
contract SolivreKernel {
    struct IdentityAnchor {
        bytes32 root;        // commitment / Merkle root for this identity
        uint64 createdAt;    // first registration timestamp
        uint64 updatedAt;    // last update timestamp
        address controller;  // who is allowed to update this anchor
    }

    /// @dev identityId (bytes32) => anchor
    mapping(bytes32 => IdentityAnchor) public anchors;

    event IdentityRegistered(
        bytes32 indexed identityId,
        bytes32 root,
        address indexed controller
    );

    event IdentityUpdated(
        bytes32 indexed identityId,
        bytes32 oldRoot,
        bytes32 newRoot
    );

    /// @notice Register a new identity anchor.
    /// @param identityId Arbitrary 32-byte id (e.g. hash of LivreID / internal id)
    /// @param root Commitment / Merkle root for this identity's state.
    function register(bytes32 identityId, bytes32 root) external {
        IdentityAnchor storage existing = anchors[identityId];
        require(existing.createdAt == 0, "SolivreKernel: already registered");

        anchors[identityId] = IdentityAnchor({
            root: root,
            createdAt: uint64(block.timestamp),
            updatedAt: uint64(block.timestamp),
            controller: msg.sender
        });

        emit IdentityRegistered(identityId, root, msg.sender);
    }

    /// @notice Update an existing identity's commitment.
    /// @param identityId Previously registered id.
    /// @param newRoot New commitment / Merkle root.
    function update(bytes32 identityId, bytes32 newRoot) external {
        IdentityAnchor storage anchor = anchors[identityId];
        require(anchor.createdAt != 0, "SolivreKernel: unknown id");
        require(anchor.controller == msg.sender, "SolivreKernel: not controller");

        bytes32 oldRoot = anchor.root;
        anchor.root = newRoot;
        anchor.updatedAt = uint64(block.timestamp);

        emit IdentityUpdated(identityId, oldRoot, newRoot);
    }
}
