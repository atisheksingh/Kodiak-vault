// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20; 

import "contracts/utils/IERC20.sol";

// interface IERC20 {
//     function totalSupply() external view returns (uint256);
//     function balanceOf(address account) external view returns (uint256);
//     function transfer(address recipient, uint256 amount) external returns (bool);
//     function allowance(address owner, address spender) external view returns (uint256);
//     function approve(address spender, uint256 amount) external returns (bool);
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

//     event Transfer(address indexed from, address indexed to, uint256 value);
//     event Approval(address indexed owner, address indexed spender, uint256 value);
// }

interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

interface IPlugin {
    /*----------  FUNCTIONS  --------------------------------------------*/
    function claimAndDistribute() external;
    function depositFor(address account, uint256 amount) external;
    function withdrawTo(address account, uint256 amount) external;
    /*----------  RESTRICTED FUNCTIONS  ---------------------------------*/
    function setGauge(address gauge) external;
    function setBribe(address bribe) external;
    /*----------  VIEW FUNCTIONS  ---------------------------------------*/
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function getUnderlyingName() external view returns (string memory);
    function getUnderlyingSymbol() external view returns (string memory);
    function getUnderlyingAddress() external view returns (address);
    function getProtocol() external view returns (string memory);
    function getTokensInUnderlying() external view returns (address[] memory);
    function getBribeTokens() external view returns (address[] memory);
    function getUnderlyingDecimals() external view returns (uint8);
}

interface IKodiakVaultV1 {

    function getMintAmounts(uint256 amount0Max, uint256 amount1Max)
        external
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function getUnderlyingBalances()
        external
        view
        returns (uint256 amount0, uint256 amount1);


    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    
    function pool() external view returns (address);
}

interface IKodiakV1RouterStaking {
    function addLiquidity(
        IKodiakVaultV1 pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function addLiquidityETH(
        IKodiakVaultV1 pool,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        external
        payable
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function addLiquidityAndStake(
        IGauge gauge,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function addLiquidityETHAndStake(
        IGauge gauge,
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min,
        uint256 amountSharesMin,
        address receiver
    )
        external
        payable
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount
        );

    function removeLiquidity(
        IKodiakVaultV1 pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        );

    function removeLiquidityETH(
        IKodiakVaultV1 pool,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address payable receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        );

    function removeLiquidityAndUnstake(
        IGauge gauge,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        );

    function removeLiquidityETHAndUnstake(
        IGauge gauge,
        uint256 burnAmount,
        uint256 amount0Min,
        uint256 amount1Min,
        address payable receiver
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        );
}

interface IGauge {
    /*----------  FUNCTIONS  --------------------------------------------*/
    function getReward(address account) external;
    function notifyRewardAmount(address token, uint amount) external;
    /*----------  RESTRICTED FUNCTIONS  ---------------------------------*/
    function _deposit(address account, uint256 amount) external;
    function _withdraw(address account, uint256 amount) external;
    function addReward(address rewardToken) external;
    /*----------  VIEW FUNCTIONS  ---------------------------------------*/
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function rewardPerToken(address reward) external view returns (uint);
    function getRewardForDuration(address reward) external view returns (uint);
    function earned(address account, address reward) external view returns (uint);
    function left(address token) external view returns (uint);
    function getRewardTokens() external view returns (address[] memory);
}


// Infrared vault
// https://infrared-dao.github.io/infrared-contracts/src/interfaces/IMultiRewards.sol/interface.IMultiRewards.html?highlight=stake#stake
interface IStaking {

    function totalSupply() external view returns (uint256);
    function stake(uint256 amount) external ;
    // Withdraws staked tokens from the contract Transfers amount of staking tokens back to the user's wallet
    function withdraw(uint256 amount) external;
    // Claims all pending rewards for the caller Transfers all accrued rewards to the caller
    function getReward() external;
    // Withdraws all staked tokens and claims pending rewards `exit()` Combines withdraw and getReward operations
    function exit() external;
    function balanceOf(address account) external view returns (uint256);
    function lastTimeRewardApplicable(address _rewardsToken) external view returns (uint256);
    function rewardPerToken(address _rewardsToken)
    external
    view
    returns (uint256);

    function earned(address account, address _rewardsToken)
    external
    view
    returns (uint256);

    function getRewardForDuration(address _rewardsToken)
    external
    view
    returns (uint256);

    function rewardData(address _rewardsToken)
    external
    view
    returns (
        address rewardsDistributor,
        uint256 rewardsDuration,
        uint256 periodFinish,
        uint256 rewardRate,
        uint256 lastUpdateTime,
        uint256 rewardPerTokenStored,
        uint256 rewardResidual
    );

    function rewardTokens(uint256 index) external view returns (address);

    function getRewardForUser(address _user) external;

}

// interface Ivault{
//     function stake(uint256 amount) external returns (bool);
//     function getReward() external;
// }


