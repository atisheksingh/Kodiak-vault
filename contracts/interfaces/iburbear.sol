
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;


interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IRouter {

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
    }

    function exitPool(
    bytes32 poolId,
    address sender,
    address recipient,
    ExitPoolRequest memory request
    ) external;

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);

    function getPoolTokens(bytes32 poolId) external view returns (address[] memory, uint256[] memory, uint256);

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

}

