// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Interfaces for external contracts
interface IKodiakRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

interface IKodiakSwap {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IPlugin {
    function deposit(uint256 amount, address account) external;
    function withdraw(uint256 amount, address account) external;
}

interface IGauge {
    function claim_rewards(address account) external;
}

contract AutoCompoundingVault is ERC4626, Ownable, ReentrancyGuard, Pausable {
    // Contract addresses
    address public constant HONEY_TOKEN = 0x0E4aaF1351de4c0264C5c7056Ef3777b41BD8e03;
    address public constant OBERO_TOKEN = 0x7629668774f918c00Eb4b03AdF5C4e2E53d45f0b;
    address public constant ISLAND_TOKEN = 0x63b0EdC427664D4330F72eEc890A86b3F98ce225;
    address public constant KODIAK_ROUTER = 0x4d41822c1804ffF5c038E4905cfd1044121e0E85;
    address public constant KODIAK_SWAP = 0x66E8F0Cf851cE9be42a2f133a8851Bc6b70B9EBd;
    address public constant PLUGIN = 0x398A242f9F9452C1fF0308D4b4bf7ae6F6323868;
    address public constant GAUGE = 0x996c24146cDF5756aFA42fa78447818A9a304851;
    
    // Minimum time between harvests
    uint256 public harvestDelay = 1 days;
    uint256 public lastHarvestTimestamp;
    
    // Slippage tolerance for swaps (default 2%)
    uint256 public slippageTolerance = 200;
    
    constructor() 
        ERC4626(IERC20(ISLAND_TOKEN))
        ERC20("Auto-Compounding Kodiak LP Vault", "acKLP")
        Ownable(msg.sender)
    {
       
       
    }

     // Approve infinite tokens for router and plugin
    function approveToken(uint256 amount)  public {
        IERC20(ISLAND_TOKEN).approve(PLUGIN, amount);
        IERC20(OBERO_TOKEN).approve(KODIAK_SWAP, amount);
        IERC20(HONEY_TOKEN).approve(KODIAK_ROUTER, amount);
    }
    
    // Override deposit to stake in Beradrome
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        super._deposit(caller, receiver, assets, shares);
        
        // Stake deposited LP tokens in Beradrome
        IPlugin(PLUGIN).deposit(assets, address(this));
    }
    
    // Override withdraw to unstake from Beradrome
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        // Unstake LP tokens from Beradrome
        IPlugin(PLUGIN).withdraw(assets, address(this));
        
        super._withdraw(caller, receiver, owner, assets, shares);
    }
    
    // Harvest rewards and compound
    function harvest() external nonReentrant whenNotPaused {
        require(block.timestamp >= lastHarvestTimestamp + harvestDelay, "Too soon to harvest");
        
        // 1. Claim rewards from gauge
        IGauge(GAUGE).claim_rewards(address(this));
        
        // 2. Swap oBERO for HONEY and NECT
        uint256 oberoBalance = IERC20(OBERO_TOKEN).balanceOf(address(this));
        require(oberoBalance > 0, "No rewards to harvest");
        
        // Split oBERO rewards into HONEY
        address[] memory path = new address[](2);
        path[0] = OBERO_TOKEN;
        path[1] = HONEY_TOKEN;
        
        uint256 amountOutMin = (oberoBalance * (10000 - slippageTolerance)) / 10000;
        IKodiakSwap(KODIAK_SWAP).swapExactTokensForTokens(
            oberoBalance,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        
        // 3. Add liquidity to Kodiak
        uint256 honeyBalance = IERC20(HONEY_TOKEN).balanceOf(address(this));
        
        (uint256 amountA, uint256 amountB, uint256 liquidity) = IKodiakRouter(KODIAK_ROUTER).addLiquidity(
            HONEY_TOKEN,
            ISLAND_TOKEN,
            honeyBalance,
            honeyBalance,
            0, // Min amounts - consider adding slippage protection
            0,
            address(this),
            block.timestamp
        );
        
        // 4. Stake new LP tokens in Beradrome
        if (liquidity > 0) {
            IPlugin(PLUGIN).deposit(liquidity, address(this));
        }
        
        lastHarvestTimestamp = block.timestamp;
        
        emit Harvested(oberoBalance, liquidity);
    }
    
    // Admin functions
    function setHarvestDelay(uint256 _delay) external onlyOwner {
        harvestDelay = _delay;
    }
    
    function setSlippageTolerance(uint256 _tolerance) external onlyOwner {
        require(_tolerance <= 1000, "Slippage too high"); // Max 10%
        slippageTolerance = _tolerance;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Emergency function to rescue tokens
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }
    
    // Events
    event Harvested(uint256 rewardAmount, uint256 newLiquidity);
}