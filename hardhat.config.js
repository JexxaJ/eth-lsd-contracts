require("hardhat-contract-sizer")
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");
require("@nomicfoundation/hardhat-foundry");
require('dotenv').config()

// set proxy
if (process.env.HTTP_NETWORK_PROXY) {
  // set proxy
  console.log("using http proxy", process.env.HTTP_NETWORK_PROXY);
  const { ProxyAgent, setGlobalDispatcher } = require("undici");
  const proxyAgent = new ProxyAgent(process.env.HTTP_NETWORK_PROXY);
  setGlobalDispatcher(proxyAgent)
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
  },
  networks: {
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
    },
    goerli: {
      url: `${process.env.GOERLI_RPC_URL}`,
    },
    holesky: {
      url: `${process.env.HOLESKY_RPC_URL}`,
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      goerli: `${process.env.ETHERSCAN_KEY}`,
      holesky: `${process.env.ETHERSCAN_KEY}`,
    },
    customChains: [
      {
        network: "holesky",
        chainId: 17000,
        urls: {
          apiURL: "https://api-holesky.etherscan.io/api",
          browserURL: "https://holesky.etherscan.io"
        }
      }
    ]
  }
};
