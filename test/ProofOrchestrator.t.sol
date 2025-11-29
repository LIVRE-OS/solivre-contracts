// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ProofOrchestrator} from "../contracts/ProofOrchestrator.sol";

contract ProofOrchestratorTest is Test {
    ProofOrchestrator orchestrator;

    function setUp() public {
        orchestrator = new ProofOrchestrator();
    }

    function test_RequestAndRead() public {
        bytes32 identityCommitment = keccak256("demo-identity");
        bytes32 templateId = keccak256("age_over_18_and_resident_pt");
        uint64 expiresAt = uint64(block.timestamp + 1 hours);
        string memory context = "test-request";

        uint256 requestId = orchestrator.requestProof(
            identityCommitment,
            templateId,
            expiresAt,
            context
        );

        ProofOrchestrator.ProofRequest memory req = orchestrator.getRequest(requestId);

        assertEq(req.requester, address(this), "requester mismatch");
        assertEq(req.identityCommitment, identityCommitment, "identityCommitment mismatch");
        assertEq(req.templateId, templateId, "templateId mismatch");
        assertEq(req.expiresAt, expiresAt, "expiresAt mismatch");
        assertTrue(req.createdAt > 0, "createdAt should be set");
        assertEq(
            uint256(req.status),
            uint256(ProofOrchestrator.RequestStatus.Pending),
            "status should be Pending"
        );
    }

    function test_SubmitProofMarksFulfilled() public {
        bytes32 identityCommitment = keccak256("demo-identity");
        bytes32 templateId = keccak256("age_over_18_and_resident_pt");
        uint64 expiresAt = uint64(block.timestamp + 1 hours);

        uint256 requestId = orchestrator.requestProof(
            identityCommitment,
            templateId,
            expiresAt,
            "ctx"
        );

        bytes32 proofHash = keccak256("fake-proof-hash");

        orchestrator.submitProof(requestId, proofHash, true);

        ProofOrchestrator.ProofRequest memory req = orchestrator.getRequest(requestId);

        assertEq(
            uint256(req.status),
            uint256(ProofOrchestrator.RequestStatus.Fulfilled),
            "status should be Fulfilled"
        );
    }

    function test_RevertOnExpiredRequest() public {
        bytes32 identityCommitment = keccak256("demo-identity");
        bytes32 templateId = keccak256("age_over_18_and_resident_pt");

        // Create a request that expires very soon
        uint64 expiresAt = uint64(block.timestamp + 1);
        uint256 requestId = orchestrator.requestProof(
            identityCommitment,
            templateId,
            expiresAt,
            "ctx"
        );

        // Move time forward past expiry
        vm.warp(block.timestamp + 3600);

        vm.expectRevert(bytes("Request expired"));
        orchestrator.submitProof(requestId, keccak256("late-proof"), true);
    }
}
