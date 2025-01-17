// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;


import "./interfaces/irestaking.sol";
import "./interfaces/iburbear.sol";

import "hardhat/console.sol";

contract AutoCompoundingVault  {

    address public LBGTTokenAddress = 0x32Cf940DB5d7ea3e95e799A805B1471341241264;
    address public WBERATokenAddress = 0x7507c1dc16935B82698e4C63f2746A2fCf994dF8;
    address public IBGTTokenAddress  = 0x46eFC86F0D7455F135CC9df501673739d513E982;
    address public LPvaultTokenAddress = 0x7fd165B73775884a38AA8f2B384A53A3Ca7400E6; // WBERA-IBGT LP token
    address public KodiakSwapV3 = 0x66E8F0Cf851cE9be42a2f133a8851Bc6b70B9EBd;
    address public Kodiak_RouterV3= 0x4d41822c1804ffF5c038E4905cfd1044121e0E85;
    address public BurbearRouterAddress = 0xFDb2925aE2d3E2eacFE927611305e5e56AA5f832;
    bytes32 LbgtwberaId = 0x6acbbedecd914de8295428b4ee51626a1908bb12000000000000000000000010;

    IERC20 public LBGTtoken = IERC20(LBGTTokenAddress);
    IERC20 public WBERAtoken = IERC20(WBERATokenAddress);
    IERC20 public IBGTtoken = IERC20(IBGTTokenAddress);
    IKodiakVaultV1 public Lpvault = IKodiakVaultV1(LPvaultTokenAddress);
    IRouter public BurbearRouter = IRouter(BurbearRouterAddress);
    // ISwapRouter public KodiakRouter = ISwapRouter(Kodiak_RouterV3);
    
    function DepositLBGTtoken(uint256 _amount) public {
        // please provide approval for the contract to spend the LBGT token
        LBGTtoken.transferFrom(msg.sender, address(this), _amount);
        console.log("LBGT token depositing");
        uint LBGTtokenBal = LBGTtoken.balanceOf(address(this));
        console.log(LBGTtokenBal , "contract balance");
    }

    function sellLBGTforWBERAusingBurbear() public  returns (uint) {
        uint LBGTtokenBal = LBGTtoken.balanceOf(address(this));
        console.log(LBGTtokenBal , "contract balance");
        LBGTtoken.approve(address(BurbearRouter), LBGTtokenBal);
        uint deadline = block.timestamp + 1000;

        IRouter.SingleSwap memory singleSwap;
        singleSwap.poolId = LbgtwberaId; //??
        singleSwap.kind = IRouter.SwapKind.GIVEN_IN;
        singleSwap.assetIn = IAsset(address(LBGTtoken));
        singleSwap.assetOut = IAsset(address(WBERAtoken));
        singleSwap.amount = LBGTtokenBal;
        singleSwap.userData = "";

        // Create the FundManagement struct
        IRouter.FundManagement memory funds;
        funds.sender = address(this);
        funds.recipient = payable(address(this));
        funds.fromInternalBalance = false;
        funds.toInternalBalance = false;
        console.log("Swapping LBGT for WBERA");
        // Call the swap function
        uint256 amountOut = BurbearRouter.swap(
            singleSwap,
            funds,
            0,
            deadline
        );

        uint wberaBal = WBERAtoken.balanceOf(address(this));
        console.log("contract WBERA balance after swap", wberaBal);
       return wberaBal;
    }   

    function buyIBGTfromWBERAkodiak() public returns (uint) {
        uint WBERAtokenBal = WBERAtoken.balanceOf(address(this))/2; // using half of the WBERA to buy IBGT
        console.log(WBERAtokenBal, "WBERA balance");
        address[] memory path = new address[](2);
        path[0] = WBERATokenAddress;
        path[1] = LBGTTokenAddress;
        // approve KodiakSwapV3 to spend WBERA
        WBERAtoken.approve(address(KodiakSwapV3), WBERAtokenBal);
        // Sell WBERA to LBGT
        uint deadline = block.timestamp + 1000;
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: WBERATokenAddress,
            tokenOut: IBGTTokenAddress,
            fee: 500, //add fee variable
            recipient: address(this),
            deadline: deadline,
            amountIn: WBERAtokenBal,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        console.log("Buying IBGT from WBERA");
        // change to v3 pool 
        // hope this do the swap for us 
       uint amountOut = ISwapRouter(KodiakSwapV3).exactInputSingle(swapParams);
       // getting the amount of LBGT received
        console.log("IBGT bought", amountOut);
       return amountOut;
     
    }

    // adding liquidity to the v3 pool
    function addLiquidityv3pool() public  returns (uint) { 

        uint amountADesired = IBGTtoken.balanceOf(address(this));
        uint amountBDesired = WBERAtoken.balanceOf(address(this));
        console.log(amountADesired, "IBGT balance");
        console.log(amountBDesired, "WBERA balance");

        uint amountAMin = amountADesired / 2;
        uint amountBMin = amountBDesired / 2;

        IBGTtoken.approve(Kodiak_RouterV3, amountADesired);
        WBERAtoken.approve(Kodiak_RouterV3, amountBDesired);

        require((amountADesired != 0)&&(amountBDesired != 0),"Swap Failed");

        IKodiakVaultV1 lpvault = IKodiakVaultV1(LPvaultTokenAddress);

        IKodiakV1RouterStaking  kodiakRouter = IKodiakV1RouterStaking(Kodiak_RouterV3);
        (, , uint liquidity) =kodiakRouter.addLiquidity(lpvault, amountADesired, amountBDesired, amountAMin, amountBMin, 1, address(this));
        console.log("Liquidity added to the pool", liquidity);
        return liquidity;

    }

    function checkforLP() public view returns (uint) {
        return IERC20(LPvaultTokenAddress).balanceOf(address(this));
    }

    function runVault(uint256 _amount) public {
        DepositLBGTtoken(_amount);
        sellLBGTforWBERAusingBurbear();
        buyIBGTfromWBERAkodiak();
        addLiquidityv3pool();
    }
}