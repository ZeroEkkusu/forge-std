// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.0 <0.9.0;

import "../Test.sol";

contract StdCheatsTest is Test {
    Contract test;

    function setUp() public {
        test = new Contract();
    }

    function testSkip() public {
        vm.warp(100);

        skip(25);

        assertEq(block.timestamp, 125);
    }

    function testRewind() public {
        vm.warp(100);

        rewind(25);

        assertEq(block.timestamp, 75);
    }

    function testHoax() public {
        hoax(address(1337));

        assertEq(address(1337).balance, 1 << 128);
        test.sender(address(1337));
    }

    function testHoax_CustomBalance() public {
        hoax(address(1337), 123 ether);

        assertEq(address(1337).balance, 123 ether);
        test.sender(address(1337));
    }

    function testHoax_Origin() public {
        hoax(address(1337), address(1337));

        assertEq(address(1337).balance, 1 << 128);
        test.origin(address(1337));
    }

    function testHoax_Origin_CustomBalance() public {
        hoax(address(1337), address(1337), 123 ether);

        assertEq(address(1337).balance, 123 ether);
        test.origin(address(1337));
    }

    function testHoax_DifferentAddresses() public {
        hoax(address(1337), address(7331));

        test.origin(address(1337), address(7331));
    }

    function testStartHoax() public {
        startHoax(address(1337));

        assertEq(address(1337).balance, 1 << 128);
        test.sender(address(1337));
        test.sender(address(1337));
        vm.stopPrank();
        test.sender(address(this));
    }

    function testStartHoax_CustomBalance() public {
        startHoax(address(1337), 123 ether);

        assertEq(address(1337).balance, 123 ether);
        test.sender(address(1337));
        test.sender(address(1337));
        vm.stopPrank();
        test.sender(address(this));
    }

    function testStartHoax_Origin() public {
        startHoax(address(1337), address(1337));

        assertEq(address(1337).balance, 1 << 128);
        test.origin(address(1337));
        test.origin(address(1337));
        vm.stopPrank();
        test.sender(address(this));
    }

    function testStartHoax_Origin_CustomBalance() public {
        startHoax(address(1337), address(1337), 123 ether);

        assertEq(address(1337).balance, 123 ether);
        test.origin(address(1337));
        test.origin(address(1337));
        vm.stopPrank();
        test.sender(address(this));
    }

    function testChangePrank() public {
        vm.startPrank(address(1337));
        test.sender(address(1337));
        test.sender(address(1337));

        changePrank(address(7331));

        test.sender(address(7331));
        test.sender(address(7331));
    }

    function testDeal() public {
        deal(address(1337), 123 ether);

        assertEq(address(1337).balance, 123 ether);
    }

    function testDeal_Token() public {
        Contract token = new Contract();
        uint256 totalSupply = token.totalSupply();

        deal(address(token), address(1337), 123e18);

        assertEq(token.balanceOf(address(1337)), 123e18);
        assertEq(token.totalSupply(), totalSupply);
    }

    function testDeal_Token_Adjust_Add() public {
        Contract token = new Contract();
        uint256 prevTotalSupply = token.totalSupply();

        deal(address(token), address(1337), 123e18, true);

        assertEq(token.balanceOf(address(1337)), 123e18);
        assertEq(token.totalSupply(), prevTotalSupply + 123e18);
    }

    function testDeal_Token_Adjust_Sub() public {
        Contract token = new Contract();
        uint256 prevTotalSupply = token.totalSupply();

        deal(address(token), address(1337), 123e18, true);
        deal(address(token), address(this), 123e18, true);

        assertEq(token.balanceOf(address(this)), 123e18);
        assertEq(token.totalSupply(), prevTotalSupply + 123e18 - (prevTotalSupply - 123e18));
    }

    function testBound() public {
        vm.expectEmit(false, false, false, true);
        emit log_named_uint("Bound Result", 0);
        assertEq(bound(5, 0, 4), 0);

        vm.expectEmit(false, false, false, true);
        emit log_named_uint("Bound Result", 69);
        assertEq(bound(0, 69, 69), 69);

        vm.expectEmit(false, false, false, true);
        emit log_named_uint("Bound Result", 68);
        assertEq(bound(0, 68, 69), 68);

        vm.expectEmit(false, false, false, true);
        emit log_named_uint("Bound Result", 160);
        assertEq(bound(10, 150, 190), 160);

        vm.expectEmit(false, false, false, true);
        emit log_named_uint("Bound Result", 3100);
        assertEq(bound(300, 2800, 3200), 3100);
        
        vm.expectEmit(false, false, false, true);
        emit log_named_uint("Bound Result", 6006);
        assertEq(bound(9999, 1337, 6666), 6006);
    }

    function testBound_Uint256Max() public {
        assertEq(bound(0, type(uint256).max - 6, type(uint256).max), type(uint256).max - 6);
        assertEq(bound(6, type(uint256).max - 6, type(uint256).max), type(uint256).max);
    }

    function testBound(
        uint256 num,
        uint256 min,
        uint256 max
    ) public {
        if (min > max) (min, max) = (max, min);

        uint256 result = bound(num, min, max);

        assertGe(result, min);
        assertLe(result, max);
    }

    function testBound_Fail() public {
        vm.expectRevert(bytes("Test bound(uint256,uint256,uint256): Max is less than min."));
        bound(0, 1, 0);
    }

    function testBound_Fail(
        uint256 num,
        uint256 min,
        uint256 max
    ) public {
        vm.assume(min != max);
        if (min < max) (min, max) = (max, min);

        vm.expectRevert(bytes("Test bound(uint256,uint256,uint256): Max is less than min."));
        bound(num, min, max);
    }

    function testDeployCode() public {
        address deployedAt = deployCode("StdCheats.t.sol:ContractWithArgs", abi.encode(123e18));

        assertEq(getCode(deployedAt), getCode(address(new ContractWithArgs(0))));
        assertEq(ContractWithArgs(deployedAt).arg(), 123e18);
    }

    function testDeployCode_NoArgs() public {
        address deployed = deployCode("StdCheats.t.sol:StdCheatsTest");

        assertEq(string(getCode(deployed)), string(getCode(address(this))));
    }

    function testDeployCode_Fail() public {
        vm.expectRevert(bytes("Test deployCode(string): Deployment failed."));
        this.deployCode("StdCheats.t.sol:RevertingContract");
    }

    function getCode(address who) internal view returns (bytes memory o_code) {
        /// @solidity memory-safe-assembly
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(who)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(who, add(o_code, 0x20), 0, size)
        }
    }
}

contract Contract {
    // `DEAL` STD-CHEAT
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;

    constructor() {
        // `DEAL` STD-CHEAT
        totalSupply = 100000e18;
        balanceOf[msg.sender] = totalSupply;
    }

    // `HOAX` STD-CHEATS
    function sender(address expectedSender) public {
        require(msg.sender == expectedSender, "Wrong sender");
    }
    function origin(address expectedSender) public {
        require(msg.sender == expectedSender, "Wrong sender");
        require(tx.origin == expectedSender, "Wrong origin");
    }
    function origin(address expectedSender, address expectedOrigin) public {
        require(msg.sender == expectedSender, "Wrong sender");
        require(tx.origin == expectedOrigin, "Wrong origin");
    }
}

contract ContractWithArgs {
    uint256 public arg;

    constructor(uint256 _arg) {
        arg = _arg;
    }
}

contract RevertingContract {
    constructor() {
        revert();
    }
}