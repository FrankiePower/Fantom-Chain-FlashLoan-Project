// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ISwapper.sol";
interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface ICauldron {
    function liquidate(address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper) external;
}

contract MIMFlashLoanBorrower is Ownable, IFlashBorrower {
    address public constant BENTOBOX_ADDRESS = 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966;
    address public constant MIM_TOKEN_ADDRESS = 0x82f0B8B456c1A451378467398982d4834b6829c1;
    address public immutable wftmTokenAddress;

    constructor(address _bentoBoxAddress, address _mimTokenAddress, address _wftmTokenAddress) {
        mimTokenAddress = _mimTokenAddress;
        wftmTokenAddress = _wftmTokenAddress;
        bentoBoxAddress = _bentoBoxAddress;
    }

    /// @notice Initiates a flash loan for a specific user and amount
    /// @param userToLiquidate The address of the user to be liquidated
    /// @param flashLoanAmount The amount for the flash loan
    function executeFlashLoan(address userToLiquidate, uint256 flashLoanAmount) external {
        // Request a flash loan from the BentoBox contract
        // Pass this contract as the borrower, specify the token type and amount, and encode the user address as additional data
        BentoBoxV1(bentoBoxAddress).flashLoan(
            this, // Borrower contract (this contract)
            IERC20(mimTokenAddress), // The token to borrow (MIM token)
            flashLoanAmount, // The amount to borrow
            abi.encode(userToLiquidate) // Encoded data (user to liquidate)
        );
    }

    // Implement onFlashLoan
    function onFlashLoan(address sender, IERC20 token, uint256 amount, uint256 fee, bytes calldata data) external override {

        require(msg.sender == bentoBoxAddress, "BUnauthorized access");
        // do liquidation

        address userToLiquidate = abi.decode(data, (address));

        performLiquidation(userToLiquidate, amount);

        //Repay the flashloan
        uint256 amountToRepay = amount + fee;
        token.transfer(bentoBoxAddress, amountToRepay);// Repay BentoBox
    }

    function performLiquidation(address user, uint256 amount) internal {}

    function withdraw(IERC20 token, uint256 amount) external {
        token.transfer(owner(), amount);
    }
}

