pragma solidity 0.6.12;

import { FlashLoanReceiverBase } from "FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20, WETH9 } from "Interfaces.sol";
import { SafeMath } from "Libraries.sol";

/** 
    !!!
    Never keep funds permanently on your FlashLoanReceiverBase contract as they could be 
    exposed to a 'griefing' attack, where the stored funds are used by an attacker.
    !!!
 */
contract HelloFlashLoans is FlashLoanReceiverBase {
    using SafeMath for uint256;
    address payable owner = 0xFFe7642922f0F6010291acd934bb18F174aaa218;
    address private weth = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    WETH9 wethContract = WETH9(weth);
    
    event InterestPaid(uint256 principal, uint256 interest);
    event BragAboutHowRichIAm(uint256 rich);


    
    // call with 0x88757f2f99175387aB4C6a4b3067c77A695b0349 as params
    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) public {}

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        
        // Look I have money here! Do something with it
        uint myWethBal = wethContract.balanceOf(address(this));
        emit BragAboutHowRichIAm(myWethBal);

        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
            emit InterestPaid(amounts[0], premiums[0]);
        }

        return true;
    }

    function myFlashLoanCall() payable external {
        if (msg.value > 0) {
            wethContract.deposit{value : msg.value}();
        }
        
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = address(weth); // Kovan weth

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10 finney;


        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
    
    function fund() payable external {
        wethContract.deposit{value : msg.value}();
        uint myWethBal = wethContract.balanceOf(address(this));
        emit BragAboutHowRichIAm(myWethBal);

    }
    
    receive() payable external {}
    fallback() payable external {}
    
    function murder() external {
        require(msg.sender == owner);
        uint myWethBal = wethContract.balanceOf(address(this));
        if (myWethBal > 0) {
            wethContract.withdraw(myWethBal);
        }
        owner.transfer(address(this).balance);
        selfdestruct(owner);
    }
}

