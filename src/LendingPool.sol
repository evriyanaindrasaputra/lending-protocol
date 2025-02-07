// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendingPool {
    struct LoanOffer {
        address lender;
        uint256 amount;
        uint256 interestRate; // APY
        bool active;
    }

    struct LoanRequest {
        address borrower;
        uint256 amount;
        uint256 maxInterestRate; // APY
        bool fulfilled;
    }

    LoanOffer[] public offers;
    LoanRequest[] public requests;

    mapping(address => uint256) public balances;

    event LoanOffered(
        address indexed lender,
        uint256 amount,
        uint256 interestRate
    );
    event LoanRequested(
        address indexed borrower,
        uint256 amount,
        uint256 maxInterestRate
    );
    event LoanAccepted(
        address indexed lender,
        address indexed borrower,
        uint256 amount,
        uint256 interestRate
    );

    // ✅ Custom Errors
    error InvalidAmount();
    error InvalidInterestRate();
    error OfferNotActive();
    error RequestAlreadyFulfilled();
    error NotEnoughLiquidity();
    error InterestRateTooHigh();

    function offerLoan(uint256 _amount, uint256 _interestRate) external {
        if (_amount == 0) revert InvalidAmount();
        if (_interestRate == 0) revert InvalidInterestRate();

        offers.push(LoanOffer(msg.sender, _amount, _interestRate, true));
        emit LoanOffered(msg.sender, _amount, _interestRate);
    }

    function requestLoan(uint256 _amount, uint256 _maxInterestRate) external {
        if (_amount == 0) revert InvalidAmount();
        if (_maxInterestRate == 0) revert InvalidInterestRate();

        requests.push(
            LoanRequest(msg.sender, _amount, _maxInterestRate, false)
        );
        emit LoanRequested(msg.sender, _amount, _maxInterestRate);
    }

    function fulfillLoan(uint256 offerIndex, uint256 requestIndex) external {
        LoanOffer storage offer = offers[offerIndex];
        LoanRequest storage request = requests[requestIndex];

        if (!offer.active) revert OfferNotActive();
        if (request.fulfilled) revert RequestAlreadyFulfilled();
        if (offer.amount < request.amount) revert NotEnoughLiquidity();
        if (offer.interestRate > request.maxInterestRate)
            revert InterestRateTooHigh();

        offer.active = false;
        request.fulfilled = true;

        balances[request.borrower] += request.amount;
        emit LoanAccepted(
            offer.lender,
            request.borrower,
            request.amount,
            offer.interestRate
        );
    }

    function getOffers() external view returns (LoanOffer[] memory) {
        return offers;
    }

    function getRequests() external view returns (LoanRequest[] memory) {
        return requests;
    }
}
