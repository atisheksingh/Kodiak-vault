const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TokenVault", function () {
    let TokenVault;
    let tokenVault;
    let owner;
    let addr1;

    // beforeEach(async function () {
    //     TokenVault = await ethers.getContractFactory("AutoCompoundingVault");
    //     [owner, addr1] = await ethers.getSigners();
    //     tokenVault = await TokenVault.deploy();
       
    //     console.log(
    //         `[AddLiqStrat] Attached to: ${await tokenVault.address}`
    //       );
    // });

    // it("should deploy the contract", async function () {
    //     expect(tokenVault.address).to.properAddress;
    // });

    it("should get router values from bera chain ", async function () {

        // add impersonate account 
        const impersonatedAccount = "0xbf71f63a2f5804B70Aaa4880a641A45fbd5989a2";
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [impersonatedAccount],
        });
        const impersonatedSigner = await ethers.getSigner(impersonatedAccount);
    

        const TokenVault = await ethers.getContractFactory("AutoCompoundingVault");
        const tokenVault = await TokenVault.connect(impersonatedSigner).deploy();
        // checking the address of the tokenVault
        console.log(
            `[TokenVault] Attached to: `, tokenVault.target
          );

        // check for balance of the account of the  address 
         const lbgTokenAddress = "0x32Cf940DB5d7ea3e95e799A805B1471341241264";
         const wberaAddress = "0x7507c1dc16935B82698e4C63f2746A2fCf994dF8";

        const lbgToken = await ethers.getContractAt("contracts/interfaces/irestaking.sol:IERC20", lbgTokenAddress);
        const balance = await lbgToken.balanceOf(impersonatedSigner);
        console.log(`Balance of LBGT Token: ${balance.toString()}`);


        
        const wberaAddresstoken = await ethers.getContractAt("contracts/interfaces/irestaking.sol:IERC20", wberaAddress);
        const wberabalance = await wberaAddresstoken.balanceOf(impersonatedSigner);
        console.log(`Balance of WBera Token: ${wberabalance.toString()}`);

        // // check for balance of the account of native token 
        // const nativeTokenBalance = await ethers.provider.getBalance(impersonatedAccount);
        // console.log(`Balance of Native Token: ${nativeTokenBalance.toString()}`);


        const balance2 = await tokenVault.checkforLP()
        console.log(`Balance of LP Token: ${balance2.toString()}`);

        //sending approve from LGT to tokenVault
        await lbgToken.connect(impersonatedSigner).approve(tokenVault.target, balance);
        console.log(`Approved LBG Token`);


        // running the function

    

        await tokenVault.connect(impersonatedSigner).runVault("3000000000000000000");


    })
   

    
});