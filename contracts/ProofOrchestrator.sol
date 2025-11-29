// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ProofOrchestrator
/// @notice Minimal on-chain anchor for Solivre proof requests + results.
/// @dev The heavy crypto lives off-chain in the Identity Node. This contract
///      only anchors who asked what, for which identity/template, and what
///      proof result (hash + valid flag) was finally recorded.

contract ProofOrchestrator {
    enum RequestStatus {
        None,
        Pending,
        Fulfilled,
        Cancelled
    }

    struct ProofRequest {
        address requester;           // who asked for the proof
        address prover;              // who submitted the proof on-chain (optional)
        bytes32 identityCommitment;  // commitment the Node is working against
        bytes32 templateId;          // e.g. keccak256("age_over_18_and_resident_pt")
        uint64 createdAt;
        uint64 expiresAt;            // 0 = no expiry
        RequestStatus status;
        bytes32 proofHash;           // hash of the proof payload (Node-defined)
        bool proofValid;             // what the Node concluded for this request
    }

    uint256 private _nextRequestId = 1;
    mapping(uint256 => ProofRequest) private _requests;

    event ProofRequested(
        uint256 indexed requestId,
        address indexed requester,
        bytes32 indexed identityCommitment,
        bytes32 templateId,
        uint64 expiresAt,
        string context
    );

    event ProofSubmitted(
        uint256 indexed requestId,
        address indexed submitter,
        bytes32 proofHash,
        bool valid
    );

    event ProofCancelled(
        uint256 indexed requestId,
        address indexed requester
    );

    /// @notice Create a new proof request for a given identity + template.
    /// @param identityCommitment Commitment the Node will resolve against.
    /// @param templateId Logical proof template identifier.
    /// @param expiresAt Unix timestamp when this request expires. 0 = never.
    /// @param context Free-form string for off-chain context (URL, session, etc.).
    function requestProof(
        bytes32 identityCommitment,
        bytes32 templateId,
        uint64 expiresAt,
        string calldata context
    ) external returns (uint256 requestId) {
        // Either no expiry, or in the future.
        require(expiresAt == 0 || expiresAt > block.timestamp, "Invalid expiry");

        requestId = _nextRequestId++;
        ProofRequest storage req = _requests[requestId];

        req.requester = msg.sender;
        req.identityCommitment = identityCommitment;
        req.templateId = templateId;
        req.createdAt = uint64(block.timestamp);
        req.expiresAt = expiresAt;
        req.status = RequestStatus.Pending;

        emit ProofRequested(
            requestId,
            msg.sender,
            identityCommitment,
            templateId,
            expiresAt,
            context
        );
    }

    /// @notice Submit the final proof result for a request.
    /// @dev For now, anyone can submit; the Identity Node decides who *actually*
    ///      calls this (e.g. an orchestrator account). Later we can add roles.
    function submitProof(
        uint256 requestId,
        bytes32 proofHash,
        bool valid
    ) external {
        ProofRequest storage req = _requests[requestId];
        require(req.status == RequestStatus.Pending, "Not pending");

        if (req.expiresAt != 0) {
            require(block.timestamp <= req.expiresAt, "Request expired");
        }

        req.status = RequestStatus.Fulfilled;
        req.prover = msg.sender;
        req.proofHash = proofHash;
        req.proofValid = valid;

        emit ProofSubmitted(requestId, msg.sender, proofHash, valid);
    }

    /// @notice Allow the original requester to cancel a pending request.
    function cancelRequest(uint256 requestId) external {
        ProofRequest storage req = _requests[requestId];
        require(req.status == RequestStatus.Pending, "Not pending");
        require(req.requester == msg.sender, "Not requester");

        req.status = RequestStatus.Cancelled;

        emit ProofCancelled(requestId, msg.sender);
    }

    /// @notice Read full request info (for your Node / UIs).
    function getRequest(uint256 requestId)
        external
        view
        returns (ProofRequest memory)
    {
        return _requests[requestId];
    }

    /// @notice Current status only (cheaper view for front-ends).
    function getStatus(uint256 requestId) external view returns (RequestStatus) {
        return _requests[requestId].status;
    }
}
