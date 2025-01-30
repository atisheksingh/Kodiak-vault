// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import "./interfaces/irestaking.sol";
import "./interfaces/iburbear.sol";
import "../contracts/erc4626.sol";
import "../contracts/utils/OwnableNew.sol";

import "hardhat/console.sol";

contract AutoCompoundingVault is ERC4626, OwnableNew {
    // static addresses
    address public LBGTTokenAddress =
        0x32Cf940DB5d7ea3e95e799A805B1471341241264;
    address public WBERATokenAddress =
        0x7507c1dc16935B82698e4C63f2746A2fCf994dF8;
    address public IBGTTokenAddress =
        0x46eFC86F0D7455F135CC9df501673739d513E982;
    address public LPvaultTokenAddress =
        0x7fd165B73775884a38AA8f2B384A53A3Ca7400E6; // WBERA-IBGT LP token
    address public KodiakSwapV3 = 0x66E8F0Cf851cE9be42a2f133a8851Bc6b70B9EBd;
    address public Kodiak_RouterV3 = 0x4d41822c1804ffF5c038E4905cfd1044121e0E85;
    address public BurbearRouterAddress =
        0xFDb2925aE2d3E2eacFE927611305e5e56AA5f832;
    address public InfraredVault = 0x763F65E5F02371aD6C24bD60BCCB0b14E160d49b;
    bytes32 LbgtwberaId =
        0x6acbbedecd914de8295428b4ee51626a1908bb12000000000000000000000010;

    // interafaces
    IERC20 public LBGTtoken = IERC20(LBGTTokenAddress);
    IERC20 public WBERAtoken = IERC20(WBERATokenAddress);
    IERC20 public IBGTtoken = IERC20(IBGTTokenAddress);
    IERC20 public Lpvault = IERC20(LPvaultTokenAddress);
    IRouter public BurbearRouter = IRouter(BurbearRouterAddress);
    IStaking public Vault = IStaking(InfraredVault);

    constructor(
        address _lp, // vault address 0x7fd165B73775884a38AA8f2B384A53A3Ca7400E6
        string memory _name,
        string memory _symbol
    ) ERC4626(ERC20(_lp)) ERC20(_name, _symbol) OwnableNew(msg.sender) {}

    // depositing LBGT token in the vault
    function DepositLBGTtoken(uint256 _amount) public returns (uint) {
        // please provide approval for the contract to spend the LBGT token
        require(_amount > 0, "Deposit amount too low");
        LBGTtoken.transferFrom(msg.sender, address(this), _amount);

        // sell LBGT for WBERA
        uint _amountWBERAtokentosell = sell_LBGTforWBERAusingBurbear(_amount);
        // buy IBGT from WBERA
        uint Ibgtamount = buyIBGTfromWBERAkodiak(_amountWBERAtokentosell);
        // add liquidity to the v3 pool
        uint AmountWBERAtoken = WBERAtoken.balanceOf(address(this));

        addLiquidityv3pool(Ibgtamount, AmountWBERAtoken);

        uint LBGTtokenBal = IERC20(LPvaultTokenAddress).balanceOf(
            address(this)
        );
        console.log(LBGTtokenBal, "lp contract balance");

        uint sharesMinted = deposit(LBGTtokenBal, msg.sender); // minting shares via vault

        console.log(sharesMinted, "sharesMinted ");
        return LBGTtokenBal;
    }

    //forward
    function sell_LBGTforWBERAusingBurbear(uint _amount) public returns (uint) {
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
        uint256 amountOut = BurbearRouter.swap(singleSwap, funds, 0, deadline);
        console.log("WBERA bought", amountOut);
        return amountOut;
    }

    //forward
    function buyIBGTfromWBERAkodiak(uint wbearamount) public returns (uint) {
        uint _amount = wbearamount / 2; // using half of the WBERA to buy IBGT
        console.log(_amount, "WBERA balance");
        // approve KodiakSwapV3 to spend WBERA
        WBERAtoken.approve(address(KodiakSwapV3), _amount);
        // Sell WBERA to LBGT
        uint deadline = block.timestamp + 1000;
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
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

    // adding liquidity to the v3 pool //forward
    function addLiquidityv3pool(
        uint _amountIBGTtoken,
        uint _amountWBERAtoken
    ) public returns (uint) {
        uint amountAMin = 0; //_amountIBGTtoken -1;
        uint amountBMin = 0; //_amountWBERAtoken -1;
        //approval
        IBGTtoken.approve(Kodiak_RouterV3, _amountIBGTtoken);
        WBERAtoken.approve(Kodiak_RouterV3, _amountWBERAtoken);

        require(
            (_amountIBGTtoken != 0) && (_amountWBERAtoken != 0),
            "Swap Failed"
        );

        IKodiakVaultV1 lpvault = IKodiakVaultV1(LPvaultTokenAddress);

        IKodiakV1RouterStaking kodiakRouter = IKodiakV1RouterStaking(
            Kodiak_RouterV3
        );
        (, , uint liquidity) = kodiakRouter.addLiquidity(
            lpvault,
            _amountIBGTtoken,
            _amountWBERAtoken,
            amountAMin,
            amountBMin,
            1,
            address(this)
        );
        console.log("Liquidity added to the pool", liquidity);
        return liquidity;
    }

    event Reinvestment(address indexed caller, uint256 reward, uint256 bounty);

    // Re-invest whatever this worker has earned back to staked LP tokens.
    function ClaimRewardonStakedToken() public {
        // get rewards from the existing staking
        uint rewards = GetrewardsFromInfra();
        console.log(rewards, "rewards claimed by contract");
      
    }

    function ReinvestReawardInfra() public {

        // get rewards from the existing staking 
        uint rewards = GetrewardsFromInfra();
        console.log(rewards, "rewards claimed by contract");
        // spending half rewards in ibgt token convert webra 
        uint wberaAmount = sell_ibgt_For_wbera(rewards/2);
        
        console.log(wberaAmount, "rewards claimed by contract");
        // add in the liquidity pool 
        addLiquidityv3pool(rewards/2, wberaAmount);
        // checking for lp token to staking 
        uint lp = checkforLP();
        // staking the lp token
        stake(lp);

        console.log("Rewards reinvested");
    }

    function checkforLP() public view returns (uint) {
        return IERC20(LPvaultTokenAddress).balanceOf(address(this));
    }

    function stake(uint256 lp) public returns (uint) {
        // need to approve vault with the LP token from contract
        IERC20(LPvaultTokenAddress).approve(InfraredVault, lp);
        console.log("stake reached here");
        // IRestaking restaking = IRestaking(InfraredVault);
        // bool v =
        Vault.stake(lp);
        // console.log(v, "staked");
        console.log(
            "Staked LP tokens into the vault",
            Vault.balanceOf(address(this))
        );
        return Vault.balanceOf(address(this));
    }

    function GetrewardsFromInfra() public returns (uint) {
        uint bal1 = IBGTtoken.balanceOf(address(this));
        console.log("ibgt balance ", bal1);
        Vault.getReward();
        uint bal = IBGTtoken.balanceOf(address(this));
        console.log("rewards claimed", bal);
        return bal;
    }

    function LBGTWithdraw(address ) public {
        // we need to burn the shares AND  get back the token needed 
        _withdraw(msg.sender, msg.sender, msg.sender, 0, balanceOf(msg.sender));
        // send LBGT token to user
        uint _amount = IBGTtoken.balanceOf(address(this));
        // rewards in ibgt token so convert into wbera
        uint wberaAmount = sell_ibgt_For_wbera(_amount);
        // wbera to lbgt 
        uint LBGTamount = sell_wbera_For_LBGT(wberaAmount);
        // finally transferring back to user 
        LBGTtoken.transfer(msg.sender, LBGTamount);
    }

    function checkamount() public view {
        console.log(WBERAtoken.balanceOf(address(this)), "WBERA balance");
        console.log(IBGTtoken.balanceOf(address(this)), "IBGT balance");
        console.log(LBGTtoken.balanceOf(address(this)), "LBGT balance");
    }

    // backward
    function withdrawStakedtokenInfra(uint256 _amount) public {
        Vault.withdraw(_amount);
        console.log(
            "withdraw LP tokens into the vault",
            Vault.balanceOf(address(this))
        );
    }

    //backward
    function withdrawLiquidityv3pool() public returns (uint, uint) {
        IKodiakVaultV1 lpvault = IKodiakVaultV1(LPvaultTokenAddress);

        uint liquidity = lpvault.balanceOf(address(this));

        Lpvault.approve(Kodiak_RouterV3, liquidity);

        console.log("Liquidity balance", liquidity);

        IKodiakV1RouterStaking kodiakRouter = IKodiakV1RouterStaking(
            Kodiak_RouterV3
        );

        (
            uint256 amount0,
            uint256 amount1,
            uint128 liquidityBurned
        ) = kodiakRouter.removeLiquidity(
                lpvault,
                liquidity,
                1,
                1,
                address(this)
            );
        console.log("Amount0", amount0);
        console.log("Amount1", amount1);
        console.log("Liquidity withdrawn from the pool", liquidityBurned);
        return (amount0, amount1);
    }

    function sell_ibgt_For_wbera(uint ibgtamount) public returns (uint) {
        IBGTtoken.approve(address(KodiakSwapV3), ibgtamount);
        // Sell ibgt to WBERA
        uint deadline = block.timestamp + 1000;
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: IBGTTokenAddress,
                tokenOut: WBERATokenAddress,
                fee: 500, //add fee variable
                recipient: address(this),
                deadline: deadline,
                amountIn: ibgtamount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        console.log("Buying WBERA from IGBT");
        uint amountOut = ISwapRouter(KodiakSwapV3).exactInputSingle(swapParams);
        // getting the amount of LBGT received
        console.log("WBERA bought", amountOut);
        return amountOut;
    }

    // backward
    function sell_wbera_For_LBGT(uint _amount) public returns (uint) {
        WBERAtoken.approve(address(BurbearRouter), _amount);
        uint deadline = block.timestamp + 1000;

        IRouter.SingleSwap memory singleSwap;
        singleSwap.poolId = LbgtwberaId;
        singleSwap.kind = IRouter.SwapKind.GIVEN_IN;
        singleSwap.assetIn = IAsset(address(WBERAtoken));
        singleSwap.assetOut = IAsset(address(LBGTtoken));
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
        uint256 amountOut = BurbearRouter.swap(singleSwap, funds, 0, deadline);
        console.log("Lgbt bought", amountOut);
        return amountOut;
    }

    modifier checkforshare {
        require(balanceOf(msg.sender) > 0, "No shares to withdraw");
        _;
    }

    function UserWithdraw() public checkforshare {
        _withdraw(msg.sender, msg.sender, msg.sender, 0, balanceOf(msg.sender));
    }


    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        _burn(owner, shares);
        // withdraw  everything from the vault 
        Vault.exit();
        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    // overrriding the deposit function of the vault
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override {
        _mint(receiver, shares);
        emit Deposit(caller, receiver, assets, shares);
    }

    // over riding the totalAsset function of the vault
    function totalAssets() public view override returns (uint256) {
        // checking the balance of the vault
        return Vault.balanceOf(address(this));
    }
}

// // TODO: function for reinvest
// // testing
// function runVault(uint256 _amount) public {
//     // deposit LBGT token
//     // uint lpshares =
//     DepositLBGTtoken(_amount);
//     // sell LBGT for WBERA
//     // uint _amountWBERAtokentosell =  sell_LBGTforWBERAusingBurbear(_amount);
//     // // buy IBGT from WBERA
//     // uint Ibgtamount =  buyIBGTfromWBERAkodiak( _amountWBERAtokentosell);
//     // // add liquidity to the v3 pool
//     // uint AmountWBERAtoken = WBERAtoken.balanceOf(address(this));

//     // uint lpvalue = addLiquidityv3pool(Ibgtamount , AmountWBERAtoken);

//     // deposit in the vault
//     uint  lpvalue =  IERC20(LPvaultTokenAddress).balanceOf(address(this));
//     stake(lpvalue);
//     //   uint reward =

//     //    Get_rewards();
//     // console.log("rewarrds claimed", reward);
// //     withdraw(lpvalue);
// //    (uint ibgtamount , uint wberaamount )= withdrawLiquidityv3pool();
// //     // selling the IBGT for WBERA
// //     console.log(ibgtamount," webrahere is the amount");
// //     console.log(wberaamount," wbera here is the amount");
// //     // selling igbt for wbera
// //    uint new_webra_amount = sell_ibgt_For_wbera(ibgtamount);
// //     // selling webra for LBGT

// //     uint256 webra_amount = new_webra_amount + wberaamount;

// //     sell_wbera_For_LBGT(webra_amount);

// //      exit();
// //     checkamount();
// }
