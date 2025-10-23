const { ethers } = require('hardhat');


describe('Starting', async function () {
    it('should be able to deploy', async function () {
        const Contract = await ethers.getContractFactory('NftAuction');
        const contract = await Contract.deploy();
        await contract.waitForDeployment();

        await contract.createAuction(
            100 * 1000,
            ethers.parseEther("0.00000000000001"),
            ethers.ZeroAddress,
            1
        )

        const auction = await contract.auctions(0);
        console.log(auction);


    })


})