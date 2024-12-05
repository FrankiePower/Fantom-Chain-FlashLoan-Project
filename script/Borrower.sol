// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.  
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
    
}

contract FlashLoanBorrower is Ownable, IFlashBorrower {
    address public immutable bentoBoxAddress;
    address public immutable mimTokenAddress;
    address public immutable wftmTokenAddress;

    constructor(address _bentoBoxAddress, address _mimTokenAddress, address _wftmTokenAddress) {
        mimTokenAddress = _mimTokenAddress;
        wftmTokenAddress = _wftmTokenAddress;
        bentoBoxAddress = _bentoBoxAddress;
    }

    function executeFlashLoan(address userToLiquidate, uint256 flashLoanAmount) external {
        BentoBoxV1(bentoBoxAddress).flashLoan(this,IERC20(mimTokenAddress), flashLoanAmount, abi.encode(userToLiquidate));
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

