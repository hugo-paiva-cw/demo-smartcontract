pragma solidity ^0.8.0;

import "./ABDKMath64x64.sol";

contract LiquidityPool {
    struct Investment {
        address investor;
        uint timestampOfDeposit;
        uint amountOfMoney;
    }
    
    constructor() {
        contractOwner = msg.sender;
    }
    
    address public contractOwner;
    uint public dailyCDIinPoints = 49037; // fracao de 1% por 1_000_000;
    mapping(address => Investment ) public allInvestors;
    uint secondsPerDay = 86400;

    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    function invest() public payable {
        // bool isNewInvestor = lookUpPreviousInvestmentsAndUpdate();
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
        updatedInvestment.amountOfMoney = weiToEther(msg.value) + previousValue;   
    }

    // function lookUpPreviousInvestmentsAndUpdate() private returns (bool) {

    // }

    function etherToWei(uint valueEther) public pure returns (uint) {
       return valueEther*(10**18);
    }

    function weiToEther(uint valueWei) public pure returns (uint) {
       return valueWei/(10**18);
    }

    function withdrawTokens(uint requestedValue) public {
        Investment storage currentInvestment = allInvestors[msg.sender];

        require(currentInvestment.amountOfMoney > 0);        
        require(weiToEther(requestedValue) < currentInvestment.amountOfMoney);
        
        int128 interest = getInterestSince(currentInvestment.timestampOfDeposit);

        int128 amountOfMoney = ABDKMath64x64.fromUInt(currentInvestment.amountOfMoney);
        uint acumulattedDepositPlusInterest =  ABDKMath64x64.toUInt(ABDKMath64x64.mul(interest, amountOfMoney));
        uint newBalance = acumulattedDepositPlusInterest - requestedValue;

        address customer = currentInvestment.investor;
        bool isCompleted = payable(customer).send(etherToWei(requestedValue));
        
        if (isCompleted) {
            currentInvestment.amountOfMoney = newBalance;
            currentInvestment.timestampOfDeposit = block.timestamp;
        }
    }

    // function lazyBalanceUpdate() public returns () {
    //     currentInvestment.amountOfMoney -= etherToWei(withdrawed);
    // }

    function checkMyBalance() public view returns(uint) {
        uint valor = allInvestors[msg.sender].amountOfMoney;


        // require(investmentIsFound); // acredito que é possivle passar mensagem de erro como parametro
        return valor;

        // return currentInvestment.amountOfMoney;
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
}
