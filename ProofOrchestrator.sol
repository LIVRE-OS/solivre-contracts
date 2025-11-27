// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ProofOrchestrator {
    enum RequestStatus {
        None,
        Pending,
        Fulfilled,
        Cancelled
    }

    struct ProofRequest {
        address requester;
        bytes32 identityCommitment;
        bytes32 templateId;
        uint64 createdAt;
        uint64 expiresAt;
        RequestStatus status;
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

    function requestProof(
        bytes32 identityCommitment,
        bytes32 templateId,
        uint64 expiresAt,
        string calldata context
    ) external returns (uint256 requestId) {
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

        // TODO: access control (e.g. only approved verifiers or requester)
        // For now, anyone can submit; your Node will decide who actually calls it.

        req.status = RequestStatus.Fulfilled;

        emit ProofSubmitted(
            requestId,
            msg.sender,
            proofHash,
            valid
        );
    }

    // Simple getter (optional but handy for debugging from Node)
    function getRequest(uint256 requestId) external view returns (ProofRequest memory) {
        return _requests[requestId];
    }
}
