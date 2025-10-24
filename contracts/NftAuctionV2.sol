// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NftAuctionV2 is Initializable {
    //结构体
    struct Auction {
        //卖家
        address seller; 
        //拍卖持续时间
        uint256 duration;
        //起拍价
        uint256 startPrice; 
        //开始时间
        uint256 startTime;
        //拍卖是否结束
        bool ended; 
        //最高出价者
        address highestBidder; 
        //最高价格
        uint256 highestBid; 
        //NFT合约地址
        address nftAddress; 
        //NFT的ID
        uint256 tokenId;
        

    }

    //状态变量
    mapping(uint256 => Auction) public auctions;
    //下一个拍卖ID
    uint256 public nextAuctionId;
    //管理员地址
    address public admin;

    function initialize() initializer public {
        admin = msg.sender;
     }

     //创建拍卖
    function createAuction(uint256 duration, uint256 startPrice,address nftAddress,uint256 tokenId) public {
        require(msg.sender == admin, "Only admin can create auctions");
        require(duration > 1000 * 60, "Duration must be greater than 0");
        require(startPrice > 0, "Start price must be greater than 0");
        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            duration: duration,
            startPrice: startPrice,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            startTime: block.timestamp,
            nftAddress: nftAddress,
            tokenId: tokenId
        });
        nextAuctionId++;
    }  

    //买家参与买单
    function placeBid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];
        require(!auction.ended && block.timestamp < auction.startTime + auction.duration, "Auction has ended");
        require(msg.value > auction.highestBid && msg.value >= auction.startPrice, "Bid is too low");

        //退还之前的最高出价者
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        //更新最高出价者和最高出价
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }
    
    function testHello() public pure returns(string memory) {
        return "Hello, this is NftAuctionV2!";
    }

}