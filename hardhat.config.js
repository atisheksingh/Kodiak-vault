require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.23",
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
        url: "https://artio.rpc.berachain.com/",
        // blockNumber: 2627700, // Specify a block number for consistent testing
      },
      chainId: 80085,
    },
  },
  mocha: {
    timeout: 100000
  }
};
