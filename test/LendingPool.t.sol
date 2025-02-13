// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";

contract LendingPoolTest is Test {
    LendingPool public lendingPool;
    address public lender = address(0x1);
    address public borrower = address(0x2);

    function setUp() public {
        lendingPool = new LendingPool();
    }

    function testCreateLendingOffer() public {
        vm.prank(lender);
        lendingPool.createLendingOffer(100 ether, 500); // 5% interest

        // Ambil data penawaran langsung menggunakan getter otomatis
        (
            address lenderAddr,
            uint256 amount,
            uint256 interestRate,
            bool isAvailable
        ) = lendingPool.lendingOffers(0);

        assertEq(lenderAddr, lender);
        assertEq(amount, 100 ether);
        assertEq(interestRate, 500);
        assertTrue(isAvailable);
    }

    function testDepositCollateral() public {
        vm.prank(borrower);
        lendingPool.depositCollateral(50 ether);
        assertEq(lendingPool.collateralBalances(borrower), 50 ether);
    }

    function testBorrow() public {
        vm.prank(lender);
        lendingPool.createLendingOffer(100 ether, 500);

        vm.prank(borrower);
        lendingPool.depositCollateral(50 ether);

        vm.prank(borrower);
        lendingPool.borrow(0, 50 ether);

        // Ambil data peminjaman menggunakan getter otomatis
        (
            address borrowerAddr,
            ,
            uint256 borrowedAmount,
            ,
            bool isActive
        ) = lendingPool.borrowings(0);

        assertEq(borrowerAddr, borrower);
        assertEq(borrowedAmount, 50 ether);
        assertTrue(isActive);
    }

    function testRepay() public {
        vm.prank(lender);
        lendingPool.createLendingOffer(100 ether, 500);

        vm.prank(borrower);
        lendingPool.depositCollateral(50 ether);

        vm.prank(borrower);
        lendingPool.borrow(0, 50 ether);

        vm.prank(borrower);
        lendingPool.repay(0, 50 ether);

        // Ambil data peminjaman setelah repayment
        (, , uint256 remainingBorrowedAmount, , bool isActive) = lendingPool
            .borrowings(0);

        assertFalse(isActive);
        assertEq(remainingBorrowedAmount, 0);
    }
}
