require("@nomicfoundation/hardhat-toolbox");

require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const url = process.env.ETHERSCAN_API_KEY;
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      // evmVersion: "paris",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: { 
      forking: {
        enabled:true,
        url: 'https://berachain-bartio.g.alchemy.com/v2/5NYUc5UX0Ht1_wsash-9iZCh6b-rvJuL',
        blockNumber: 9349245,
        accounts: [`0x${PRIVATE_KEY}`],
        chainId: 80084,
      },
    }, 
    bera: {
      chainId: 80084,
      url: 'https://berachain-bartio.g.alchemy.com/v2/5NYUc5UX0Ht1_wsash-9iZCh6b-rvJuL', //https://bartio.rpc.berachain.com
      accounts: [`0x${PRIVATE_KEY}`]
    },
  },
  mocha: {
    timeout: 100000
  }
};




