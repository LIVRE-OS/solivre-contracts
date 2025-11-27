// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/SolivreKernel.sol";

contract SolivreKernelTest is Test {
    SolivreKernel kernel;

    function setUp() public {
        kernel = new SolivreKernel();
    }

    function test_RegisterAndRead() public {
        bytes32 id = keccak256("odin.livre");
        bytes32 root1 = keccak256("root-1");

        kernel.register(id, root1);

        (
            bytes32 storedRoot,
            uint64 createdAt,
            uint64 updatedAt,
            address controller
        ) = kernel.anchors(id);

        assertEq(storedRoot, root1);
        assertEq(controller, address(this));
        assertGt(createdAt, 0);
        assertEq(createdAt, updatedAt);
    }

    function test_RevertOnDuplicateRegister() public {
        bytes32 id = keccak256("odin.livre");
        bytes32 root1 = keccak256("root-1");
        bytes32 root2 = keccak256("root-2");

        kernel.register(id, root1);

        vm.expectRevert("SolivreKernel: already registered");
        kernel.register(id, root2);
    }

    function test_UpdateByController() public {
        bytes32 id = keccak256("odin.livre");
        bytes32 root1 = keccak256("root-1");
        bytes32 root2 = keccak256("root-2");

        kernel.register(id, root1);

        // small time jump so updatedAt is different
        vm.warp(block.timestamp + 10);

        kernel.update(id, root2);

        (bytes32 storedRoot,, uint64 updatedAt,) = kernel.anchors(id);

        assertEq(storedRoot, root2);
        assertGt(updatedAt, 0);
    }

    function test_UpdateFailsForNonController() public {
        bytes32 id = keccak256("odin.livre");
        bytes32 root1 = keccak256("root-1");
        bytes32 root2 = keccak256("root-2");

        kernel.register(id, root1);

        // try to update from a different address
        address attacker = address(0xBEEF);
        vm.prank(attacker);
        vm.expectRevert("SolivreKernel: not controller");
        kernel.update(id, root2);
    }
}

