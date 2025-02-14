// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LendingPool} from "./LendingPool.sol";

contract Factory {
    function createLendingPool(
        address _collateralToken,
        address _debtToken
    ) external returns (address) {
        LendingPool lendingPool = new LendingPool(_collateralToken, _debtToken);
        return address(lendingPool);
    }
}
