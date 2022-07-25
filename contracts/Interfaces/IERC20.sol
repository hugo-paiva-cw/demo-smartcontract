pragma solidity ^0.8.7;

interface IERC20 {
    function transferFrom(address A, address B, uint C) external view returns (bool);

    function approve() external view returns (uint256);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address D, uint amount) external;
}
