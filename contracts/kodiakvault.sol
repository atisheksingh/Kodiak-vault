// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;


import "./interfaces/irestaking.sol";
import "./interfaces/iburbear.sol";
import "../contracts/erc4626.sol";
import "../contracts/utils/OwnableNew.sol";

import "hardhat/console.sol";

contract AutoCompoundingVault  is ERC4626 , OwnableNew {

    // static addresses
    address public LBGTTokenAddress = 0x32Cf940DB5d7ea3e95e799A805B1471341241264;
    address public WBERATokenAddress = 0x7507c1dc16935B82698e4C63f2746A2fCf994dF8;
    address public IBGTTokenAddress  = 0x46eFC86F0D7455F135CC9df501673739d513E982;
    address public LPvaultTokenAddress = 0x7fd165B73775884a38AA8f2B384A53A3Ca7400E6; // WBERA-IBGT LP token
    address public KodiakSwapV3 = 0x66E8F0Cf851cE9be42a2f133a8851Bc6b70B9EBd;
    address public Kodiak_RouterV3= 0x4d41822c1804ffF5c038E4905cfd1044121e0E85;
    address public BurbearRouterAddress = 0xFDb2925aE2d3E2eacFE927611305e5e56AA5f832;
    address public InfraredVault = 0x763F65E5F02371aD6C24bD60BCCB0b14E160d49b;
    bytes32 LbgtwberaId = 0x6acbbedecd914de8295428b4ee51626a1908bb12000000000000000000000010;

    // interafaces 
    IERC20 public LBGTtoken = IERC20(LBGTTokenAddress);
    IERC20 public WBERAtoken = IERC20(WBERATokenAddress);
    IERC20 public IBGTtoken = IERC20(IBGTTokenAddress);
    IERC20 public Lpvault = IERC20(LPvaultTokenAddress);
    IRouter public BurbearRouter = IRouter(BurbearRouterAddress);
    IStaking public StakeFarm = IStaking(InfraredVault);

    mapping (address => uint) public sharesbalance;
    
   
    // use a  constructor for erc4626 
    //Set the underlying asset contract. This must be an ERC20-compatible contract (ERC-20 or ERC-777).
    // name and symbol are the name and symbol of the LP token

    constructor( address _lp,
        string memory _name,
        string memory _symbol )ERC4626(ERC20(_lp)) ERC20(_name, _symbol) OwnableNew(msg.sender) {

    }
    

    function DepositLBGTtoken(uint256 _amount) public returns (uint) {
        // please provide approval for the contract to spend the LBGT token
        require(_amount > 0, "Deposit amount too low");
        LBGTtoken.transferFrom(msg.sender, address(this), _amount);
        uint LBGTtokenBal = LBGTtoken.balanceOf(address(this));
        // uint sharesMinted = deposit(_amount, msg.sender); // minting shares via vault
        // console.log(sharesMinted , "contract balance");
        return 0;
    }

    function reinvest(uint _amount) public {
        // reinvest the rewards
        // 1. minting new shares
        DepositLBGTtoken(_amount);
        // 2. adding liquidity to the pool

        // 3. staking the LP tokens
        // 4. getting rewards
    



    }
   

    function sellLBGTforWBERAusingBurbear(uint _amount) public  returns (uint) {
        LBGTtoken.approve(address(BurbearRouter), _amount);
        uint deadline = block.timestamp + 1000;

        IRouter.SingleSwap memory singleSwap;
        singleSwap.poolId = LbgtwberaId; 
        singleSwap.kind = IRouter.SwapKind.GIVEN_IN;
        singleSwap.assetIn = IAsset(address(LBGTtoken));
        singleSwap.assetOut = IAsset(address(WBERAtoken));
        singleSwap.amount = _amount;
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
        console.log("WBERA bought", amountOut);
       return amountOut;
    }   

    function selltokenForLBGT() public // ToDO add the function to sell token for LBGT
    {
        // sell token for LBGT
    }

    function buyIBGTfromWBERAkodiak(uint wbearamount) public returns (uint) {
        uint _amount = wbearamount/2; // using half of the WBERA to buy IBGT
        console.log(_amount, "WBERA balance");
        address[] memory path = new address[](2);
        path[0] = WBERATokenAddress;
        path[1] = LBGTTokenAddress;
        // approve KodiakSwapV3 to spend WBERA
        WBERAtoken.approve(address(KodiakSwapV3), _amount);
        // Sell WBERA to LBGT
        uint deadline = block.timestamp + 1000;
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: WBERATokenAddress,
            tokenOut: IBGTTokenAddress,
            fee: 500, //add fee variable
            recipient: address(this),
            deadline: deadline,
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        console.log("Buying IBGT from WBERA");
       uint amountOut = ISwapRouter(KodiakSwapV3).exactInputSingle(swapParams);
       // getting the amount of LBGT received
       console.log("IBGT bought", amountOut);
       return amountOut;
     
    }

    // adding liquidity to the v3 pool
    function addLiquidityv3pool(uint _amountIBGTtoken, uint _amountWBERAtoken) public  returns (uint) { 

        // uint amountADesired = IBGTtoken.balanceOf(address(this));
        // uint amountBDesired = WBERAtoken.balanceOf(address(this));
        // console.log(amountADesired, "IBGT balance");
        // console.log(amountBDesired, "WBERA balance");
        //  tokenA and tokenB minimum amounts
        uint amountAMin = _amountIBGTtoken / 2;
        uint amountBMin = _amountWBERAtoken / 2;
        //approval
        IBGTtoken.approve(Kodiak_RouterV3, _amountIBGTtoken);
        WBERAtoken.approve(Kodiak_RouterV3, _amountWBERAtoken);

        require((_amountIBGTtoken != 0)&&(_amountWBERAtoken != 0),"Swap Failed");

        IKodiakVaultV1 lpvault = IKodiakVaultV1(LPvaultTokenAddress);

        IKodiakV1RouterStaking  kodiakRouter = IKodiakV1RouterStaking(Kodiak_RouterV3);
        (, , uint liquidity) =kodiakRouter.addLiquidity(lpvault, _amountIBGTtoken, _amountWBERAtoken, amountAMin, amountBMin, 1, address(this));
        console.log("Liquidity added to the pool", liquidity);
        return liquidity;

    }

    function withdrawLiquidityv3pool() public {
        IKodiakVaultV1 lpvault = IKodiakVaultV1(LPvaultTokenAddress);

        uint liquidity = lpvault.balanceOf(address(this));
        
        Lpvault.approve(Kodiak_RouterV3, liquidity);
        
        console.log("Liquidity balance", liquidity);
       
        IKodiakV1RouterStaking  kodiakRouter = IKodiakV1RouterStaking(Kodiak_RouterV3);

       (uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned)= kodiakRouter.removeLiquidity(
            lpvault, 
            liquidity,
            1, 1, 
            address(this));
        console.log("Amount0", amount0);
        console.log("Amount1", amount1);
        console.log("Liquidity withdrawn from the pool", liquidityBurned);
    }

    function checkforLP() public view returns (uint) {
        return IERC20(LPvaultTokenAddress).balanceOf(address(this));
    }

    // stake into the Infrared IBGT-WBERA Vault
    function stake(uint256 lp) public  returns (uint) {
        // need to approve vault with the LP token from contract
        IERC20(LPvaultTokenAddress).approve(InfraredVault, lp);
        // IRestaking restaking = IRestaking(InfraredVault);
        StakeFarm.stake(lp);
        console.log("Staked LP tokens into the vault", StakeFarm.balanceOf(address(this)));
        return  StakeFarm.balanceOf(address(this));
    }

    function Get_rewards() public  returns (uint)
    {  
        StakeFarm.getReward(); 

        return StakeFarm.balanceOf(address(this));
    }
    function withdraw(uint256 _amount) public {
        StakeFarm.withdraw(_amount);
        console.log("withdraw LP tokens into the vault", StakeFarm.balanceOf(address(this)));
    }

    // TODO: function for reinvest 

    function runVault(uint256 _amount) public {
        // deposit LBGT token
        uint lpshares = DepositLBGTtoken(_amount);
        // sell LBGT for WBERA
        uint _amountWBERAtokentosell =  sellLBGTforWBERAusingBurbear(_amount);
        // buy IBGT from WBERA
        uint Ibgtamount =  buyIBGTfromWBERAkodiak( _amountWBERAtokentosell);
        // add liquidity to the v3 pool
        uint AmountWBERAtoken = WBERAtoken.balanceOf(address(this));

        uint lpvalue = addLiquidityv3pool(Ibgtamount , AmountWBERAtoken);

        stake(lpvalue);

        uint reward = Get_rewards();
        console.log("rewarrds claimed", reward);
        withdraw(lpvalue);
        withdrawLiquidityv3pool();
    }
}