// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract LendingPoolCopy {

}

// pragma solidity ^0.8.19;

// /**
//  * @title LendingPool
//  * @dev Smart contract untuk CLOB lending dan borrowing dengan collateral.
//  */
// contract LendingPoolDummy {
//     error InvalidAmount();
//     error InvalidInterestRate();
//     error InvalidDuration();
//     error InvalidOfferID();
//     error OfferNotAvailable();
//     error InsufficientCollateral();
//     error BorrowingAlreadyRepaid();
//     error RepaymentExceedsBorrowedAmount();

//     /// @notice Struktur untuk menyimpan penawaran pinjaman oleh lender.
//     struct LendingOffer {
//         address lender;
//         uint256 amount;
//         uint256 interestRate; // in basis points (bps)
//         uint256 duration; // in seconds
//         bool isAvailable;
//     }

//     /// @notice Struktur untuk menyimpan penawaran peminjaman oleh borrower.
//     struct BorrowingOffer {
//         address borrower;
//         uint256 amount;
//         uint256 interestRate;
//         uint256 duration;
//         bool isAvailable;
//     }

//     /// @notice Struktur untuk menyimpan informasi tentang transaksi peminjaman yang sedang berlangsung.
//     struct Borrowing {
//         address borrower;
//         uint256 offerId;
//         uint256 borrowedAmount;
//         uint256 collateralAmount;
//         bool isActive;
//     }

//     LendingOffer[] public lendingOffers;
//     BorrowingOffer[] public borrowingOffers;
//     Borrowing[] public borrowings;
//     mapping(address => uint256) public collateralBalances;
//     uint256 public nextBorrowingId;

//     event LendingOfferCreated(
//         uint256 offerId,
//         address lender,
//         uint256 amount,
//         uint256 interestRate,
//         uint256 duration
//     );
//     event BorrowingOfferCreated(
//         uint256 offerId,
//         address borrower,
//         uint256 amount,
//         uint256 interestRate,
//         uint256 duration
//     );
//     event BorrowingCreated(
//         uint256 borrowingId,
//         address borrower,
//         uint256 offerId,
//         uint256 borrowedAmount,
//         uint256 collateralAmount
//     );
//     event CollateralDeposited(address indexed borrower, uint256 amount);
//     event RepaymentMade(
//         uint256 borrowingId,
//         address borrower,
//         uint256 amountRepaid,
//         bool isFullyRepaid
//     );
//     event LenderPaid(address lender, uint256 amount);

//     /**
//      * @notice Membuat penawaran pinjaman oleh lender.
//      */
//     function createLendingOffer(
//         uint256 amount,
//         uint256 interestRate,
//         uint256 duration
//     ) external {
//         if (amount == 0) revert InvalidAmount();
//         if (interestRate == 0) revert InvalidInterestRate();
//         if (duration == 0) revert InvalidDuration();

//         lendingOffers.push(
//             LendingOffer(msg.sender, amount, interestRate, duration, true)
//         );
//         emit LendingOfferCreated(
//             lendingOffers.length - 1,
//             msg.sender,
//             amount,
//             interestRate,
//             duration
//         );
//     }

//     /**
//      * @notice Membuat penawaran peminjaman oleh borrower.
//      */
//     function createBorrowingOffer(
//         uint256 amount,
//         uint256 interestRate,
//         uint256 duration
//     ) external {
//         if (amount == 0) revert InvalidAmount();
//         if (interestRate == 0) revert InvalidInterestRate();
//         if (duration == 0) revert InvalidDuration();

//         borrowingOffers.push(
//             BorrowingOffer(msg.sender, amount, interestRate, duration, true)
//         );
//         emit BorrowingOfferCreated(
//             borrowingOffers.length - 1,
//             msg.sender,
//             amount,
//             interestRate,
//             duration
//         );
//     }

//     /**
//      * @notice Menyetorkan ETH sebagai jaminan sebelum meminjam.
//      */
//     function depositCollateral() external payable {
//         if (msg.value == 0) revert InvalidAmount();
//         collateralBalances[msg.sender] += msg.value;
//         emit CollateralDeposited(msg.sender, msg.value);
//     }

//     /**
//      * @notice Borrower mengambil pinjaman dari penawaran yang tersedia.
//      */
//     function borrow(uint256 offerId, uint256 borrowAmount) external {
//         if (offerId >= lendingOffers.length) revert InvalidOfferID();
//         LendingOffer storage offer = lendingOffers[offerId];
//         if (!offer.isAvailable) revert OfferNotAvailable();
//         if (borrowAmount == 0 || borrowAmount > offer.amount)
//             revert InvalidAmount();
//         if (collateralBalances[msg.sender] < borrowAmount)
//             revert InsufficientCollateral();

//         offer.amount -= borrowAmount;
//         if (offer.amount == 0) {
//             offer.isAvailable = false;
//         }

//         borrowings.push(
//             Borrowing(msg.sender, offerId, borrowAmount, borrowAmount, true)
//         );
//         unchecked {
//             nextBorrowingId++;
//         }

//         payable(msg.sender).transfer(borrowAmount);
//         emit BorrowingCreated(
//             nextBorrowingId - 1,
//             msg.sender,
//             offerId,
//             borrowAmount,
//             borrowAmount
//         );
//     }

//     /**
//      * @notice Borrower melakukan pembayaran kembali sebagian atau seluruh pinjaman.
//      */
//     function repay(uint256 borrowingId) external payable {
//         if (borrowingId >= borrowings.length) revert InvalidOfferID();
//         Borrowing storage borrowing = borrowings[borrowingId];
//         if (!borrowing.isActive) revert BorrowingAlreadyRepaid();
//         if (msg.value == 0) revert InvalidAmount();
//         if (msg.value > borrowing.borrowedAmount)
//             revert RepaymentExceedsBorrowedAmount();

//         borrowing.borrowedAmount -= msg.value;
//         if (borrowing.borrowedAmount == 0) {
//             borrowing.isActive = false;
//         }

//         address lender = lendingOffers[borrowing.offerId].lender;
//         payable(lender).transfer(msg.value);
//         emit RepaymentMade(
//             borrowingId,
//             msg.sender,
//             msg.value,
//             !borrowing.isActive
//         );
//         emit LenderPaid(lender, msg.value);
//     }

//     /**
//      * @notice Mengambil daftar semua lending offers.
//      */
//     function getLendingOffers() external view returns (LendingOffer[] memory) {
//         return lendingOffers;
//     }

//     /**
//      * @notice Mengambil daftar semua borrowing offers.
//      */
//     function getBorrowingOffers()
//         external
//         view
//         returns (BorrowingOffer[] memory)
//     {
//         return borrowingOffers;
//     }
// }
