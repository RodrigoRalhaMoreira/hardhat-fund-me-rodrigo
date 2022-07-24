// last step before deploying for a mainnet tests for testnets
const { deployments, ethers, getNamedAccounts, network } = require("hardhat")
const { assert, expect } = require("chai")
const { developmentChains } = require("../../helper-hardhat-config")
developmentChains.includes(network.name)
    ? describe.skip
    : describe("FundMe", async function() {
          let fundMe
          let deployer
          const sendValue = ethers.utils.parseEther("0.04") // 1 ETH
          beforeEach(async function() {
              // we assume we do not need fixings because its already deployed
              deployer = (await getNamedAccounts()).deployer
              fundMe = await ethers.getContract("FundMe", deployer)
          })

          it("allows people to fund and withdraw", async function() {
              await fundMe.fund({ value: sendValue })
              const transactionResponse = await fundMe.withdraw()
              // put this line with wait because in testnet it does not recognize imediatly
              const transactionReceipt = await transactionResponse.wait(1)
              const endingBalance = await fundMe.provider.getBalance(
                  fundMe.address
              )
              assert.equal(endingBalance.toString(), "0")
          })
      })
