// scripts/deploy.js

const { ethers } = require("hardhat");

async function main() {
    // Get the contract factory
    const AutoCompoundingVault = await ethers.getContractFactory("AutoCompoundingVault");

    // Deploy the contract
    const vault = await AutoCompoundingVault.deploy();

       // Wait for the deployment to be mined
       const receipt = await vault.deployTransaction
        // Wait for the transaction to be mined
   
       // Log the transaction receipt
       console.log("Transaction Receipt:", receipt);

    console.log("AutoCompoundingVault deployed to:", vault.address);
}

// Execute the deployment script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });