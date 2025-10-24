const { ethers, deployments, upgrades } = require('hardhat');
const { expect } = require('chai');

describe('Test upgrade', async function () {
    it('should be able to deploy', async function () {
        //1. 部署业务合约
        await deployments.fixture(['deployNftAuction']);
        const nftAuctionProxy = await deployments.get('NftAuctionProxy');
        //2. 调用createAuction 创建拍卖
        const nftAuction = await ethers.getContractAt('NftAuction', nftAuctionProxy.address);
        await nftAuction.createAuction(
            100 * 1000,
            ethers.parseEther('0.01'),
            ethers.ZeroAddress,
            1
        )
        const auction = await nftAuction.auctions(0);
        console.log("拍卖创建成功:", auction);
        const implAddress1 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);
        //3. 升级合约
        await deployments.fixture(['upgradeNftAuction']);

        //4. 读取合约的 auction[0] 看是否一致
        const auction2 = await nftAuction.auctions(0);
        console.log("升级后拍卖数据:", auction2);
        const nftAuctionV2 = await ethers.getContractAt('NftAuctionV2', nftAuctionProxy.address);
        const hello = await nftAuctionV2.testHello();
        console.log("调用V2新方法返回:", hello);


        const implAddress2 = await upgrades.erc1967.getImplementationAddress(nftAuctionProxy.address);
        console.log("升级前地址:", implAddress1);
        console.log("升级后地址:", implAddress2);
        expect(auction2.startTime).to.equal(auction.startTime);
        expect(implAddress1).to.not.equal(implAddress2);

    })


})