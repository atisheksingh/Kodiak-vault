const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenVault", function () {


    it("should get router values from bera chain ", async function () {

        const lbgTokenAddress = "0x32Cf940DB5d7ea3e95e799A805B1471341241264";
        const wberaAddress = "0x7507c1dc16935B82698e4C63f2746A2fCf994dF8";
        const LPvaultTokenAddress = "0x7fd165B73775884a38AA8f2B384A53A3Ca7400E6";
        const TokenVault = await ethers.getContractFactory("AutoCompoundingVault");
        const LbgToken = await ethers.getContractAt("contracts/utils/IERC20.sol:IERC20", lbgTokenAddress);
        const wberaAddresstoken = await ethers.getContractAt("contracts/utils/IERC20.sol:IERC20", wberaAddress);
        const lptoken = await ethers.getContractAt("contracts/utils/IERC20.sol:IERC20", LPvaultTokenAddress);

        // add impersonate account 
        const impersonatedAccount = "0xbf71f63a2f5804B70Aaa4880a641A45fbd5989a2"//"0xbf71f63a2f5804B70Aaa4880a641A45fbd5989a2"
        // "0xCe8D4e158981c4BB9B830FD729E415B5F7b666aF";
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [impersonatedAccount],
        });
        const impersonatedSigner = await ethers.getSigner(impersonatedAccount);
        // deploy the tokenVault contract
        const tokenVault = await TokenVault.connect(impersonatedSigner).
            deploy("0x7fd165B73775884a38AA8f2B384A53A3Ca7400E6",
                "lp share ", "lp");
        // checking the address of the tokenVault
        console.log(`[TokenVault] Attached to: `, tokenVault.target);
        // check for balance of the account of the  address 
        
        const LbgtTokenBalance = await LbgToken.balanceOf(impersonatedSigner.address);

        console.log(`Balance of LBGT Token: ${LbgtTokenBalance.toString()}`);

        const wberabalance = await wberaAddresstoken.balanceOf(impersonatedSigner);
        console.log(`Balance of WBera Token: ${wberabalance.toString()}`);

        //sending approve from LGT to tokenVault
        await LbgToken.connect(impersonatedSigner).approve(tokenVault.target, LbgtTokenBalance);
        console.log(`Approved LBG Token`, LbgtTokenBalance);

        await tokenVault.connect(impersonatedSigner).DepositLBGTtoken(LbgtTokenBalance);
        

        const lpvalue =  lptoken.balanceOf(tokenVault.target);
        await tokenVault.connect(impersonatedSigner).stake(lpvalue);


        await network.provider.send("evm_increaseTime", [345600]) // Increase time by 2 Days => 86400 * 2 =172800
        await network.provider.send("evm_mine")

        // await tokenVault.connect(impersonatedSigner).Get_rewards();

        await network.provider.send("evm_increaseTime", [172800]) // Increase time by 2 Days => 86400 * 2 =172800
        await network.provider.send("evm_mine")
        // if the token have increament value mean the rewards are added in out contract . 
        // await tokenVault.connect(impersonatedSigner).Get_rewards();

        const valueOfLp =        await tokenVault.connect(impersonatedSigner).balanceOf(impersonatedSigner);
        console.log(valueOfLp.toString(), "Value of LP token in the account");

        // await tokenVault.connect(impersonatedSigner).ReinvestReawardInfra()



        await tokenVault.connect(impersonatedSigner).LBGTWithdraw(valueOfLp, impersonatedSigner, impersonatedSigner)

        const LbgtTokenBalanceafterReinvest = await LbgToken.balanceOf(impersonatedSigner.address);
        console.log(LbgtTokenBalanceafterReinvest, "After withdraw the rewards");



    })




});