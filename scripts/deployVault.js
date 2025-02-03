const hre = require("hardhat");

async function main() {
    // Compile the contracts
    await hre.run('compile');

    // Get the contract to deploy
    const TokenVault = await ethers.getContractFactory("AutoCompoundingVault");
    const vault = await TokenVault.deploy("0x7fd165B73775884a38AA8f2B384A53A3Ca7400E6","lp share ", "lp");

    console.log(`[TokenVault] Attached to: `, vault.target);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });