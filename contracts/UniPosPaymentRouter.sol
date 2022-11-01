// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract UniPosPaymentRouter is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private AVAX = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address payable internal feeBeneficiary;

    event PaymentReceived(address indexed payeer, address indexed receiver, address indexed token, uint256 amount, uint256 fee);
    event Withdrawn(address indexed beneficiary, address indexed token,  uint256 amount);
    event FeeBeneficiaryChanged(address indexed newBeneficiary);

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

        emit PaymentReceived(msg.sender, receiver, AVAX, amount, fee);

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

        emit PaymentReceived(msg.sender, receiver, token, amount, fee);

        IERC20(token).safeTransferFrom(msg.sender, feeBeneficiary, fee);
        IERC20(token).safeTransferFrom(msg.sender, receiver, amount);
    }

    function withdraw() external onlyOwner nonReentrant {
        require(feeBeneficiary != address(0));
        
        uint256 amount = address(this).balance;

        emit Withdrawn(feeBeneficiary, AVAX, amount);
        
        feeBeneficiary.transfer(amount);
    }

    function withdraw(address token) external onlyOwner nonReentrant {
        require(feeBeneficiary != address(0));
        uint256 amount = IERC20(token).balanceOf(address(this));

        emit Withdrawn(feeBeneficiary, token, amount);

        IERC20(token).safeTransfer(feeBeneficiary, amount);
    }

    function setFeeBeneficiary(address payable beneficiary) external onlyOwner {
        require(beneficiary != address(0), "Router: Invalid beneficiary address");

        emit FeeBeneficiaryChanged(beneficiary);

        feeBeneficiary = beneficiary;
    }
}
