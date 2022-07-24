pragma solidity ^0.8.1;

import "./ABDKMath64x64.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityPool {
    using SafeERC20 for IERC20;

    struct Investment {
        address investor;
        uint timestampOfDeposit;
        uint amountOfMoney;
    }
    IERC20 token;
    address public contractOwner;
    uint public dailyCDIinPoints = 49037; // fracao de 1% por 1_000_000;
    mapping(address => Investment ) public allInvestors;
    uint secondsPerDay = 86400;
    
    constructor(IERC20 _brlcToken) {
        // IERC20 token = '0xC6d1eFd908ef6B69dA0749600F553923C465c812';
        token = _brlcToken;
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    function invest() public payable {
        Investment memory currentInvestment = allInvestors[msg.sender];
        uint depositPlusInterest = 0;
        if (currentInvestment.timestampOfDeposit > 0) {
            int128 interest = getInterestSince(currentInvestment.timestampOfDeposit);

            int128 amountOfMoney = ABDKMath64x64.fromUInt(currentInvestment.amountOfMoney);
            depositPlusInterest =  ABDKMath64x64.toUInt(ABDKMath64x64.mul(interest, amountOfMoney)); // + weiToEther(msg.value);
        }

        uint previousValue = depositPlusInterest;

        Investment storage updatedInvestment = allInvestors[msg.sender];          
        
        updatedInvestment.investor = msg.sender;
        updatedInvestment.timestampOfDeposit = block.timestamp;
        updatedInvestment.amountOfMoney = weiToEther(token.balanceOf(address(this))) + previousValue;   
    }

    // function lookUpPreviousInvestmentsAndUpdate() private returns (bool) {

    // }

    function etherToWei(uint valueEther) public pure returns (uint) {
       return valueEther*(10**6);
    }

    function weiToEther(uint valueWei) public pure returns (uint) {
       return valueWei/(10**6);
    }

    function withdrawTokens(uint requestedValue) public {
        Investment storage currentInvestment = allInvestors[msg.sender];

        require(currentInvestment.amountOfMoney > 0);        
        require(requestedValue < currentInvestment.amountOfMoney);
        
        int128 interest = getInterestSince(currentInvestment.timestampOfDeposit);

        int128 amountOfMoney = ABDKMath64x64.fromUInt(currentInvestment.amountOfMoney);
        uint acumulattedDepositPlusInterest =  ABDKMath64x64.toUInt(ABDKMath64x64.mul(interest, amountOfMoney));
        uint newBalance = acumulattedDepositPlusInterest - requestedValue;

        address customer = currentInvestment.investor;
        // bool isCompleted = payable(customer).send(etherToWei(requestedValue));
        token.safeTransfer(customer, etherToWei(requestedValue));

        currentInvestment.amountOfMoney = newBalance;
        currentInvestment.timestampOfDeposit = block.timestamp;
        
        // if (isCompleted) {
        //     currentInvestment.amountOfMoney = newBalance;
        //     currentInvestment.timestampOfDeposit = block.timestamp;
        // }
    }

    function checkMyBalance() public view returns(uint) {
        uint valor = allInvestors[msg.sender].amountOfMoney;
        return valor;
    }

    function checkContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getInterestSince(uint timestampOfDeposit) public view returns (int128) {

        // Get time since deposit in days
        uint currentTime = block.timestamp; // now // you can use either block.timestamp or now to have a unix timestamp
        uint elapsedTimeInSeconds = currentTime - timestampOfDeposit;
        // uint elapsedDays = elapsedTimeInSeconds / secondsPerDay;
        uint elapsedDays = 252;

        // Get interest ratio in binary that in the end converts to 1.05 for example meaning an addition of 5%
        int128 acumulattedInterestInBinary =
        ABDKMath64x64.pow (
        ABDKMath64x64.add (
          ABDKMath64x64.fromUInt(1),
          ABDKMath64x64.div(
            ABDKMath64x64.fromUInt(dailyCDIinPoints),
            ABDKMath64x64.fromUInt(100000000) // 100 do percentual vezes 1_000_000 da fraçao do daily points
         )),
        elapsedDays);

        return acumulattedInterestInBinary;
    }

    function getMoneyBackDebug() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function changeCDIinterestRate(uint cdiInPercentualPoints) public onlyOwner {
        // TODO mudar CDI já tem o modifier onlyOwner ai
        // Take the example 1% equals to 1_000_000 points. 0.05% equals to 50_000 points
        dailyCDIinPoints = cdiInPercentualPoints;
    }

    function transferERC20(address to, uint amount) public {
        // require(msg.sender == contractOwner);
        uint erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, 'balance is low');
        token.safeTransfer(to, amount);
    }

    function getBalanceERC20() public view returns (uint) {
        uint erc20balance = token.balanceOf(address(this));
        return erc20balance;
    }
}
