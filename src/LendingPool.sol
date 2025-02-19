// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

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
        bool isActive;
    }

    LendingOffer[] public lendingOffers;
    BorrowingOffer[] public borrowingOffers;
    Borrowing[] public borrowings;
    uint256 public nextBorrowingId;
    address public collateralToken;
    address public debtToken;

    mapping(address => uint256) public collateralBalances;

    /**
     * @dev emitted on lending offer created
     * @param _user the address of the lender
     * @param _amount the amount to be lended
     * @param _timestamp the timestamp of the action
     **/
    event LendingOfferCreated(
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
    event BorrowingFullyRepaid(uint256 _borrowingId);

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) revert LendingPool__NeedMoreThanZero();
        _;
    }

    /**
     * @dev constructor
     * @param _collateralToken the address of the collateral token
     * @param _debtToken the address of the debt token
     */
    constructor(address _collateralToken, address _debtToken) {
        collateralToken = _collateralToken;
        debtToken = _debtToken;
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
        require(
            IERC20(debtToken).allowance(msg.sender, address(this)) >= _amount,
            "Insufficient allowance"
        );

        // Simpan lending offer
        lendingOffers.push(
            LendingOffer(msg.sender, _amount, _interestRate, true)
        );

        // Transfer dana ke kontrak
        IERC20(debtToken).transferFrom(msg.sender, address(this), _amount);

        emit LendingOfferCreated(
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
        collateralBalances[msg.sender] += _amount;
        IERC20(collateralToken).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(debtToken).transferFrom(msg.sender, address(this), _amount);

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
    function depositCollateral(
        uint256 _amount
    ) external payable moreThanZero(_amount) {
        collateralBalances[msg.sender] += _amount;
        IERC20(collateralToken).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        emit CollateralDeposited(msg.sender, _amount);
    }

    /**
     * @dev withdraw collateral for borrower
     * @param _amount the amount of the collateral
     **/
    function withdrawCollateral(
        uint256 _amount
    ) external moreThanZero(_amount) {
        if (collateralBalances[msg.sender] < _amount)
            revert LendingPool__InsufficientCollateral();

        collateralBalances[msg.sender] -= _amount;
        IERC20(collateralToken).transfer(msg.sender, _amount);

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

        // Update offer
        offer.amount -= _borrowAmount;
        if (offer.amount == 0) {
            offer.isAvailable = false;
        }

        // Borrower menerima debt token
        IERC20(debtToken).transfer(msg.sender, _borrowAmount);

        // Simpan data borrowing
        borrowings.push(Borrowing(msg.sender, _offerId, _borrowAmount, true));

        // Emit event sebelum increment
        emit BorrowingCreated(
            nextBorrowingId,
            msg.sender,
            _offerId,
            _borrowAmount
        );

        // Increment borrowing ID
        unchecked {
            nextBorrowingId++;
        }
    }

    function repay(
        uint256 _borrowingId,
        uint256 _amount
    ) external payable moreThanZero(_amount) {
        if (_borrowingId >= borrowings.length)
            revert LendingPool__InvalidOfferID();

        Borrowing storage borrowing = borrowings[_borrowingId];

        if (!borrowing.isActive) revert LendingPool__BorrowingAlreadyRepaid();
        if (_amount > borrowing.borrowedAmount)
            revert LendingPool__RepaymentExceedsBorrowedAmount();

        borrowing.borrowedAmount -= _amount;

        // Jika sudah lunas, ubah status borrowing
        bool fullyRepaid = false;
        if (borrowing.borrowedAmount == 0) {
            borrowing.isActive = false;
            fullyRepaid = true;
            emit BorrowingFullyRepaid(_borrowingId);
        }

        IERC20(debtToken).transferFrom(msg.sender, address(this), _amount);

        emit Repayment(
            _borrowingId,
            msg.sender,
            _amount,
            block.timestamp,
            fullyRepaid
        );
    }

    /**
     * @dev check isHealthy
     * @param _user the address of the user
     */
    function _isHealthy(address _user) external view {
        uint256 totalBorrowedAmount = 0;

        for (uint256 i = 0; i < borrowings.length; i++) {
            if (borrowings[i].borrower == _user && borrowings[i].isActive) {
                totalBorrowedAmount += borrowings[i].borrowedAmount;
            }
        }

        if (totalBorrowedAmount > collateralBalances[_user]) {
            revert LendingPool__InsufficientCollateral();
        }
    }

    /**
     * @dev get lending offers
     * @return the list of lending offers
     */
    function getLendingOffers() external view returns (LendingOffer[] memory) {
        return lendingOffers;
    }

    /**
     * @dev get borrowing offers
     * @return the list of borrowing offers
     */
    function getBorrowingOffers()
        external
        view
        returns (BorrowingOffer[] memory)
    {
        return borrowingOffers;
    }
}
