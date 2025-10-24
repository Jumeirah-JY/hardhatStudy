const { ethers, deployments } = require('hardhat');
const { expect } = require('chai');

describe('Test auction', async function () {
    it('should be ok', async function () {
        await main();
    });
})

async function main() {
    const [signer, buyer] = await ethers.getSigners();
    await deployments.fixture(['deployNftAuction']);
    const nftAuctionProxy = await deployments.get('NftAuctionProxy');

    //1.部署 ERC721 合约
    const TestERC721 = await ethers.getContractFactory('TestERC721');
    const testERC721 = await TestERC721.deploy();
    await testERC721.waitForDeployment();
    const testERC721Address = await testERC721.getAddress();
    console.log("ERC721 address:", testERC721Address);

    //mint 10个NFT
    for (let i = 0; i < 10; i++) {
        await testERC721.mint(signer.address, i + 1);
    }

    const tokenId = 1;
    //2. 调用 createAuction 创建拍卖
    const nftAuction = await ethers.getContractAt(
        'NftAuction',
        nftAuctionProxy.address
    );
    //给代理合约授权
    await testERC721.connect(signer).setApprovalForAll(nftAuctionProxy.address, true);

    await nftAuction.createAuction(
        10,
        ethers.parseEther('0.01'),
        testERC721Address,
        tokenId
    );

    const auction = await nftAuction.auctions(0);
    console.log("拍卖创建成功:", auction);

    //3. 购买者参与拍卖
    await nftAuction.connect(buyer).placeBid(0, { value: ethers.parseEther('0.01') });

    //4.结束拍卖
    //等待10s 
    await new Promise((resolve) => setTimeout(resolve, 10 * 1000));
    await nftAuction.connect(signer).endAuction(0);

    //验证结果
    const auctionResult = await nftAuction.auctions(0);
    console.log("结束拍卖后读取拍卖成功:", auctionResult);
    expect(auctionResult.highestBidder).to.equal(buyer.address);
    expect(auctionResult.highestBid).to.equal(ethers.parseEther('0.01'));

    //验证NFT所有权
    const owner = await testERC721.ownerOf(tokenId);
    console.log("NFTowner:", owner);
    expect(owner).to.equal(buyer.address);
}
