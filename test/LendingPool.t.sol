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
        string memory rpcUrl = vm.envString("MAINNET_RPC_URL");
        uint256 forkBlock = vm.envUint("FORK_BLOCK");
        vm.createSelectFork(rpcUrl, forkBlock);
        factory = new Factory();
        lendingPool = LendingPool(factory.createLendingPool(weth, usdc));

        deal(usdc, lender, 3000e6);
        deal(weth, borrower, 2e18);
    }

    function test_CreateLendingOffer() public {
        vm.startPrank(lender);
        IERC20(usdc).approve(address(lendingPool), 2000e6);
        lendingPool.createLendingOffer(2000e6, 500); // 5% interest
        vm.stopPrank();

        // Ambil data penawaran langsung menggunakan getter otomatis
        (
            address lenderAddr,
            uint256 amount,
            uint256 interestRate,
            bool isAvailable
        ) = lendingPool.lendingOffers(0);

        assertEq(lenderAddr, lender);
        assertEq(amount, 2000e6);
        assertEq(interestRate, 500);
        assertTrue(isAvailable);
    }

    function test_DepositCollateral() public {
        // Simulasi deposit collateral
        vm.startPrank(borrower);
        IERC20(weth).approve(address(lendingPool), 1e18);
        lendingPool.depositCollateral(1e18);
        console.log(
            "ETH balance in contract:",
            IERC20(weth).balanceOf(address(lendingPool))
        );

        vm.stopPrank();
        assertEq(lendingPool.collateralBalances(borrower), 1e18);
    }

    function test_Borrow() public {
        // Simulasi borrow
        vm.startPrank(lender);
        IERC20(usdc).approve(address(lendingPool), 2000e6);
        lendingPool.createLendingOffer(2000e6, 500);
        vm.stopPrank();

        vm.startPrank(borrower);
        IERC20(weth).approve(address(lendingPool), 1e18);
        lendingPool.depositCollateral(1e18);
        lendingPool.borrow(0, 1500e6);
        vm.stopPrank();
        assertEq(lendingPool.collateralBalances(borrower), 1e18);
        // Ambil data penawaran langsung menggunakan getter otomatis
        (
            address borrowAddr,
            uint256 offerId,
            uint256 borrowedAmount,

        ) = lendingPool.borrowings(0);
        console.log(
            "ETH balance in contract:",
            IERC20(weth).balanceOf(address(lendingPool))
        );
        console.log(
            "USDC balance in contract:",
            IERC20(usdc).balanceOf(address(lendingPool))
        );
        console.log(
            "USDC balance in borrower:",
            IERC20(usdc).balanceOf(address(borrower))
        );
        assertEq(borrowAddr, borrower);
        assertEq(offerId, 0);
        assertEq(borrowedAmount, 1500e6);
    }

    function test_repay() public {
        // Simulasi borrow
        vm.startPrank(lender);
        IERC20(usdc).approve(address(lendingPool), 2000e6);
        lendingPool.createLendingOffer(2000e6, 500);
        console.log(
            "USDC balance in contract:",
            IERC20(usdc).balanceOf(address(lendingPool))
        );
        vm.stopPrank();

        vm.startPrank(borrower);
        IERC20(weth).approve(address(lendingPool), 1e18);
        lendingPool.depositCollateral(1e18);
        console.log(
            "WETH balance in contract:",
            IERC20(weth).balanceOf(address(lendingPool))
        );
        lendingPool.borrow(0, 1000e6);
        console.log(
            "USDC balance in contract: after borrow",
            IERC20(usdc).balanceOf(address(lendingPool))
        );
        console.log(
            "WETH balance in contract: after borrow",
            IERC20(weth).balanceOf(address(lendingPool))
        );
        vm.stopPrank();

        vm.startPrank(borrower);
        console.log(
            "USDC balance in borrower: before repay",
            IERC20(usdc).balanceOf(address(borrower))
        );
        IERC20(usdc).approve(address(lendingPool), 1000e6);
        lendingPool.repay(0, 1000e6);
        console.log(
            "USDC balance in contract: after repay",
            IERC20(usdc).balanceOf(address(lendingPool))
        );
        vm.stopPrank();
    }
}
