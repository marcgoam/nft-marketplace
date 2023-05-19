const { ethers } = require("hardhat")
const fs = require("fs")

const frontEndContractsFile =
    "../nextjs-nft-marketplace/constants/networkMapping.json"
const frontEndAbiFile = "../nextjs-nft-marketplace/constants/"

module.exports = async function () {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Updating front end...")
        await updateContractAddresses()
        await updateABI()
    }

    async function updateContractAddresses() {
        const NFTMarketPlace = await ethers.getContract("NFTMarketPlace")
        const contractAddresses = JSON.parse(
            fs.readFileSync(frontEndContractsFile, "utf8")
        )
        if (network.config.chainId.toString() in contractAddresses) {
            if (
                !contractAddresses[network.config.chainId.toString()].includes(
                    NFTMarketPlace.address
                )
            ) {
                contractAddresses[network.config.chainId.toString()].push(
                    NFTMarketPlace.address
                )
            }
        } else {
            contractAddresses[network.config.chainId.toString()] = [
                NFTMarketPlace.address,
            ]
        }
        fs.writeFileSync(
            frontEndContractsFile,
            JSON.stringify(contractAddresses)
        )
    }

    async function updateABI() {
        const nftMarketplace = await ethers.getContract("NFTMarketPlace")
        fs.writeFileSync(
            `${frontEndAbiFile}NftMarketplace.json`,
            nftMarketplace.interface.format(ethers.utils.FormatTypes.json)
        )
    }

    module.exports.tags = ["all", "frontend"]
}
