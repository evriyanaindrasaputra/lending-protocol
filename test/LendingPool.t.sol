// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";

contract LendingPoolTest is Test {
    LendingPool lendingPool;
    address lender = address(0x1);
    address borrower = address(0x2);

    function setUp() public {
        lendingPool = new LendingPool();
    }

    function testOfferLoan() public {
        vm.prank(lender);
        lendingPool.offerLoan(1000, 5);

        (
            address offerLender,
            uint256 amount,
            uint256 interestRate,
            bool active
        ) = lendingPool.offers(0);

        assertEq(offerLender, lender);
        assertEq(amount, 1000);
        assertEq(interestRate, 5);
        assertEq(active, true);
    }

    function testRequestLoan() public {
        vm.prank(borrower);
        lendingPool.requestLoan(500, 10);

        (
            address requestBorrower,
            uint256 amount,
            uint256 maxInterestRate,
            bool fulfilled
        ) = lendingPool.requests(0);

        assertEq(requestBorrower, borrower);
        assertEq(amount, 500);
        assertEq(maxInterestRate, 10);
        assertEq(fulfilled, false);
    }

    function testFulfillLoan() public {
        vm.prank(lender);
        lendingPool.offerLoan(1000, 5);

        vm.prank(borrower);
        lendingPool.requestLoan(500, 6);

        vm.prank(borrower);
        lendingPool.fulfillLoan(0, 0);

        (, , , bool active) = lendingPool.offers(0);
        (, , , bool fulfilled) = lendingPool.requests(0);

        assertEq(active, false);
        assertEq(fulfilled, true);
    }

    function testCannotFulfillLoan_IfInterestRateTooHigh() public {
        vm.prank(lender);
        lendingPool.offerLoan(1000, 7); // Lender memberikan bunga 7%

        vm.prank(borrower);
        lendingPool.requestLoan(500, 6); // Borrower hanya ingin max 6%

        vm.expectRevert(LendingPool.InterestRateTooHigh.selector);
        lendingPool.fulfillLoan(0, 0);
    }

    function testCannotOfferLoan_IfAmountZero() public {
        vm.expectRevert(LendingPool.InvalidAmount.selector);
        lendingPool.offerLoan(0, 5);
    }

    function testCannotRequestLoan_IfAmountZero() public {
        vm.expectRevert(LendingPool.InvalidAmount.selector);
        lendingPool.requestLoan(0, 5);
    }
}
