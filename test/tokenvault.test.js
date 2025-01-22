const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenVault", function () {

  
    it("should get router values from bera chain ", async function () {

        // add impersonate account 
        const impersonatedAccount = "0xCe8D4e158981c4BB9B830FD729E415B5F7b666aF";
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [impersonatedAccount],
        });
        const impersonatedSigner = await ethers.getSigner(impersonatedAccount);
        const TokenVault = await ethers.getContractFactory("AutoCompoundingVault");
        const tokenVault = await TokenVault.connect(impersonatedSigner).deploy("0x32Cf940DB5d7ea3e95e799A805B1471341241264", "lp share ","lp");
        // checking the address of the tokenVault
        console.log(`[TokenVault] Attached to: `, tokenVault.target);
        // check for balance of the account of the  address 
        const lbgTokenAddress = "0x32Cf940DB5d7ea3e95e799A805B1471341241264";
        const wberaAddress = "0x7507c1dc16935B82698e4C63f2746A2fCf994dF8";
        const lpvaultAddress = "0x7fd165B73775884a38AA8f2B384A53A3Ca7400E6"

        const LbgToken = await ethers.getContractAt("contracts/utils/IERC20.sol:IERC20", lbgTokenAddress);
        const LbgtTokenBalance = await LbgToken.balanceOf(impersonatedSigner.address);

        console.log(`Balance of LBGT Token: ${LbgtTokenBalance.toString()}`);

        const wberaAddresstoken = await ethers.getContractAt("contracts/utils/IERC20.sol:IERC20", wberaAddress);
        const wberabalance = await wberaAddresstoken.balanceOf(impersonatedSigner);
        console.log(`Balance of WBera Token: ${wberabalance.toString()}`);


        

        //sending approve from LGT to tokenVault
        await LbgToken.connect(impersonatedSigner).approve(tokenVault.target, LbgtTokenBalance);
        console.log(`Approved LBG Token`, LbgtTokenBalance);
        // running the function
        // checking the balance of the LP token
        const LPbalance = await tokenVault.checkforLP()
        console.log(`Balance of LP Token: ${LPbalance.toString()}`);
        // const LpVaultAddresstoken = await ethers.getContractAt("contracts/utils/IERC20.sol:IERC20", "0x7fd165B73775884a38AA8f2B384A53A3Ca7400E6");
       
        // await tokenVault.connect(impersonatedSigner).checkforEarnedRewards();
        await tokenVault.connect(impersonatedSigner).runVault(LbgtTokenBalance);
       
       
        
  




    })

   

    
});