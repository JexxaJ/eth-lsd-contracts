require("hardhat-contract-sizer")
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");
require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-chai-matchers")
require('dotenv').config()

// set proxy
if (process.env.HTTP_NETWORK_PROXY) {
  // set proxy
  console.log("using http proxy", process.env.HTTP_NETWORK_PROXY);
  const { ProxyAgent, setGlobalDispatcher } = require("undici");
  const proxyAgent = new ProxyAgent({
    uri: process.env.HTTP_NETWORK_PROXY,
    connect: {
      timeout: 30_000,
    }
  });
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
    goerli: {
      url: `${process.env.GOERLI_RPC_URL}`,
    },
    pusechain_testnet_v4: {
      url: `${process.env.PULSECHAIN_TESTNET_V4_RPC_URL}`,
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
        },
        network: "pusechain_testnet_v4",
        chainId: 943,
        urls: {
          apiURL: "https://api.scan.v4.testnet.pulsechain.com",
          browserURL: "https://rpc.v4.testnet.pulsechain.com"
        }
      }
    ]
  }
};
