// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title LendingPool contract
 * @notice Implements the actions of the LendingPool,
 * @author Eindrasap
 **/
contract LendingPool {
    error LendingPool__NeedMoreThanZero();
    error LendingPool__InvalidOfferID();
    error LendingPool__OfferNotAvailable();
    error LendingPool__InsufficientCollateral();
    error LendingPool__InvalidBorrowAmount();
    error LendingPool__BorrowingAlreadyRepaid();
    error LendingPool__RepaymentExceedsBorrowedAmount();

    /**
     * @dev the structure of lending offer
     **/
    struct LendingOffer {
        address lender;
        uint256 amount;
        uint256 interestRate; // in basis points (bps)
        bool isAvailable;
    }

    /**
     * @dev the structure of borrowing offer
     **/
    struct BorrowingOffer {
        address borrower;
        uint256 amount;
        uint256 interestRate;
        bool isAvailable;
    }
    /**
     * @dev the structure of borrowing
     **/
    struct Borrowing {
        address borrower;
        uint256 offerId;
        uint256 borrowedAmount;
        uint256 collateralAmount;
        bool isActive;
    }

    LendingOffer[] public lendingOffers;
    BorrowingOffer[] public borrowingOffers;
    Borrowing[] public borrowings;
    uint256 public nextBorrowingId;

    mapping(address => uint256) public collateralBalances;

    /**
     * @dev emitted on lending offer created
     * @param _reserve the address of the reserve
     * @param _user the address of the lender
     * @param _amount the amount to be lended
     * @param _timestamp the timestamp of the action
     **/
    event LendingOfferCreated(
        address indexed _reserve,
        address indexed _user,
        uint256 _amount,
        uint256 _interestRate,
        uint256 _timestamp
    );

    /**
     * @dev emited on repayment
     * @param _user the address of the lender
     * @param _amount the amount of the repayment
     */
    event LenderPaid(address indexed _user, uint256 _amount);

    /**
     * @dev emitted on make borrowing
     * @param _borrowingId the id of borrowing
     * @param _user the address of the borrower
     * @param _offerId the id of the offer
     * @param _amount the amount of the borrowing
     */
    event BorrowingCreated(
        uint256 _borrowingId,
        address indexed _user,
        uint256 _offerId,
        uint256 _amount
    );

    /**
     * @dev emitted on borrowing offer created
     * @param _reserve the address of the reserve
     * @param _user the address of the borrower
     * @param _amount the amount to be borrowed
     * @param _interestRate the interest rate of the borrowing
     * @param _timestamp the timestamp of the action
     **/
    event BorrowingOfferCreated(
        address indexed _reserve,
        address indexed _user,
        uint256 _amount,
        uint256 _interestRate,
        uint256 _timestamp
    );

    /**
     * @dev emitted on repayment
     * @param _borrowingId the id of borrowing
     * @param _user the address of the borrower
     * @param _amount the amount to be repaid
     * @param _timestamp the timestamp of the action
     * @param _isFullyRepaid the status is fully repaid
     **/
    event Repayment(
        uint256 indexed _borrowingId,
        address indexed _user,
        uint256 _amount,
        uint256 _timestamp,
        bool _isFullyRepaid
    );

    /**
     * @dev emitted on deposit collateral for borrower
     * @param _user the address of the borrower
     * @param _amount the amount of the collateral
     **/
    event CollateralDeposited(address indexed _user, uint256 _amount);

    /**
     * @dev emitted on withdraw collateral for borrower
     * @param _user the address of the borrower
     * @param _amount the amount of the collateral
     **/
    event CollateralWithdrawn(address indexed _user, uint256 _amount);

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) revert LendingPool__NeedMoreThanZero();
        _;
    }

    /**
     * @dev create lending offer
     * @param _amount the amount of the offer
     * @param _interestRate the interest rate of the offer
     **/
    function createLendingOffer(
        uint256 _amount,
        uint256 _interestRate
    ) external moreThanZero(_amount) moreThanZero(_interestRate) {
        lendingOffers.push(
            LendingOffer(msg.sender, _amount, _interestRate, true)
        );

        emit LendingOfferCreated(
            address(this),
            msg.sender,
            _amount,
            _interestRate,
            block.timestamp
        );
    }

    /**
     * @dev create borrowing offer
     * @param _amount the amount of the offer
     * @param _interestRate the interest rate of the offer
     **/
    function createBorrowingOffer(
        uint256 _amount,
        uint256 _interestRate
    ) external moreThanZero(_amount) moreThanZero(_interestRate) {
        borrowingOffers.push(
            BorrowingOffer(msg.sender, _amount, _interestRate, true)
        );

        emit BorrowingOfferCreated(
            address(this),
            msg.sender,
            _amount,
            _interestRate,
            block.timestamp
        );
    }

    /**
     * @dev deposit collateral for borrower
     * @param _amount the amount of the collateral
     **/
    function depositCollateral(uint256 _amount) external moreThanZero(_amount) {
        collateralBalances[msg.sender] += _amount;

        emit CollateralDeposited(msg.sender, _amount);
    }

    /**
     * @dev withdraw collateral for borrower
     * @param _amount the amount of the collateral
     **/
    function withdrawCollateral(
        uint256 _amount
    ) external moreThanZero(_amount) {
        collateralBalances[msg.sender] -= _amount;
        emit CollateralWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev borrow from the offer
     * @param _offerId the id of the offer
     * @param _borrowAmount the amount of the borrowing
     **/
    function borrow(
        uint256 _offerId,
        uint256 _borrowAmount
    ) external moreThanZero(_borrowAmount) {
        if (_offerId >= lendingOffers.length)
            revert LendingPool__InvalidOfferID();

        LendingOffer storage offer = lendingOffers[_offerId];

        if (!offer.isAvailable) revert LendingPool__OfferNotAvailable();
        if (_borrowAmount == 0 || _borrowAmount > offer.amount)
            revert LendingPool__InvalidBorrowAmount();

        if (collateralBalances[msg.sender] < _borrowAmount)
            revert LendingPool__InsufficientCollateral();

        offer.amount -= _borrowAmount;
        if (offer.amount == 0) {
            offer.isAvailable = false;
        }

        borrowings.push(
            Borrowing(msg.sender, _offerId, _borrowAmount, _borrowAmount, true)
        );
        unchecked {
            nextBorrowingId++;
        }

        emit BorrowingCreated(
            nextBorrowingId - 1,
            msg.sender,
            _offerId,
            _borrowAmount
        );
    }

    /**
     * @dev repay borrowing
     * @param _borrowingId the id of borrowing
     * @param _amount the amount of the repayment
     **/
    function repay(
        uint256 _borrowingId,
        uint256 _amount
    ) external moreThanZero(_amount) {
        if (_borrowingId >= borrowings.length)
            revert LendingPool__InvalidOfferID();

        Borrowing storage borrowing = borrowings[_borrowingId];

        if (!borrowing.isActive) revert LendingPool__BorrowingAlreadyRepaid();
        if (_amount > borrowing.borrowedAmount)
            revert LendingPool__RepaymentExceedsBorrowedAmount();

        borrowing.borrowedAmount -= _amount;
        if (borrowing.borrowedAmount == 0) {
            borrowing.isActive = false;
        }

        address lender = lendingOffers[borrowing.offerId].lender;
        payable(lender).transfer(_amount);
        emit Repayment(
            _borrowingId,
            msg.sender,
            _amount,
            block.timestamp,
            !borrowing.isActive
        );
        emit LenderPaid(lender, _amount);
    }
}
