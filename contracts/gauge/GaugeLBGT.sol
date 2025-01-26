// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPawOperator {
    function mintLbgtTo(address rewardsVault, address recipient) external returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract DummyGauge is IPawOperator {
    IERC20 public token;

    /**
     * @notice Sets the token address in the constructor.
     * @param _token The address of the token to be used for transfers.
     */
    constructor(address _token) {
        require(_token != address(0), "Invalid token address");
        token = IERC20(_token);
    }

    /**
     * @notice Transfers the entire balance of the token to the recipient.
     * @param rewardsVault Ignored in this implementation.
     * @param recipient The address to receive the tokens.
     * @return amount The amount of tokens sent to the recipient.
     */
    function mintLbgtTo(address rewardsVault, address recipient) external override returns (uint256) {
        // Ignoring rewardsVault as per requirements

        require(recipient != address(0), "Invalid recipient address");

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens available to transfer");

        // Transfer tokens to the recipient
        token.transfer(recipient, balance);

        return balance;
    }
}
