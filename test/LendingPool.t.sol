// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Factory} from "../src/Factory.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LendingPoolTest is Test {
    LendingPool public lendingPool;
    Factory public factory;

    address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public lender = makeAddr("lender");
    address public borrower = makeAddr("borrower");

    function setUp() public {
        vm.createSelectFork(
            "https://eth-mainnet.g.alchemy.com/v2/Qspd4Dw10PEYdY817GiO9hcbzMfNDQtf",
            21197642
        );
        factory = new Factory();
        lendingPool = LendingPool(factory.createLendingPool(weth, usdc));

        deal(weth, lender, 2e18);
        deal(weth, borrower, 1e18);
    }

    function test_CreateLendingOffer() public {
        vm.startPrank(lender);
        IERC20(weth).approve(address(lendingPool), 2e18);
        lendingPool.createLendingOffer(2e18, 500); // 5% interest
        vm.stopPrank();

        // Ambil data penawaran langsung menggunakan getter otomatis
        (
            address lenderAddr,
            uint256 amount,
            uint256 interestRate,
            bool isAvailable
        ) = lendingPool.lendingOffers(0);

        assertEq(lenderAddr, lender);
        assertEq(amount, 2e18);
        assertEq(interestRate, 500);
        assertTrue(isAvailable);
    }
}
