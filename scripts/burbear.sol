// // SPDX-License-Identifier: SEE LICENSE IN LICENSE
// pragma solidity ^0.8.20;


// import "./interfaces/irestaking.sol";
// import "./interfaces/burbear.sol";


// contract burbearvault  {


// // we need to define the addresses of the tokens and the router
//    address public  WBERAaddress  = 0x7507c1dc16935B82698e4C63f2746A2fCf994dF8;
//    address public  IBGTaddress = 0x46eFC86F0D7455F135CC9df501673739d513E982;
//     address public  BurrbearRouterAddress = 0xFDb2925aE2d3E2eacFE927611305e5e56AA5f832;

//         // constructor  


//            // make the swap

//     /**
//      * @notice function to deposit assets and receive vault tokens in exchange
//      * @param _assets amount of the asset token
//      */
//     function depositWBERA(uint _assets) public returns (uint256){
//         require(_assets > 0, "Deposit amount too low");
//         WBERA.transferFrom(msg.sender, address(this), _assets);

//         uint WBERABal = WBERA.balanceOf(address(this));

//         uint lpBal = addStrat(WBERABal);
//         WBERABal = WBERA.balanceOf(address(this));
//         WBERA.transfer(msg.sender, WBERABal);
//         uint sharesMinted = deposit(lpBal, msg.sender);
//         return sharesMinted;
//     }

//     function addStrat(uint _assets) public returns (uint256){

//         WBERA.approve(address(router),_assets);

//         IAsset[] memory assetsParam = new IAsset[](4);
//         assetsParam[0] = IAsset(0x0E4aaF1351de4c0264C5c7056Ef3777b41BD8e03);
//         assetsParam[1] = IAsset(0xd6D83aF58a19Cd14eF3CF6fe848C9A4d21e5727c);
//         assetsParam[2] = IAsset(0xf5AFCF50006944d17226978e594D4D25f4f92B40);
//         assetsParam[3] = IAsset(0xf74a682b45F488DF08a77Dc6aF07364e94e4ED98);

//         uint[] memory maxAmountsInParam = new uint[](4);
//         maxAmountsInParam[0] = _assets;
//         maxAmountsInParam[1] = 0;
//         maxAmountsInParam[2] = 0;
//         maxAmountsInParam[3] = 0;

//         uint[] memory amountsInParam = new uint[](3);
//         amountsInParam[0] = _assets;
//         amountsInParam[1] = 0;
//         amountsInParam[2] = 0;

//         // Encode userData for joinInit
//         uint8 joinKind = 1;
//         uint256 minimumBPT = 1;
//         // uint256 enterTokenIndex = 0;
//         bytes memory userEncode = abi.encode(joinKind,amountsInParam ,minimumBPT);
        
//         IRouter.JoinPoolRequest memory joinParams = IRouter.JoinPoolRequest({
//             assets: assetsParam,
//             maxAmountsIn: maxAmountsInParam,
//             userData: userEncode,
//             fromInternalBalance: false
//         });

//         router.joinPool(
//             poolId,
//             address(this),
//             address(this),
//             joinParams
//         );
        
//         uint lpBal = lp.balanceOf(address(this));
//         return lpBal;
//     }






// }