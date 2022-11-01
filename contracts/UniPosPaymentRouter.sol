// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UniPosPaymentRouter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address payable internal feeBeneficiary;

    constructor(address payable beneficiary) {
        feeBeneficiary = beneficiary;
    }

    function receiveNative(
        uint256 amount,
        uint256 feeRate,
        address payable receiver
    ) external payable nonReentrant {
        uint256 fee = (amount * feeRate) / 100;

        require(amount + fee == msg.value);

        feeBeneficiary.transfer(fee);
        receiver.transfer(msg.value - fee);
    }

    function receiveToken(
        address token,
        uint256 amount,
        uint256 feeRate,
        address receiver
    ) external {
        uint256 fee = (amount * feeRate) / 100;

        IERC20(token).safeTransferFrom(msg.sender, feeBeneficiary, fee);
        IERC20(token).safeTransferFrom(msg.sender, receiver, amount);
    }

    function withdraw() external onlyOwner nonReentrant {
        require(feeBeneficiary != address(0));
        feeBeneficiary.transfer(address(this).balance);
    }

    function withdraw(address token) external onlyOwner nonReentrant {
        require(feeBeneficiary != address(0));
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(feeBeneficiary, amount);
    }
}
