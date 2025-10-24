// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract NftAuction is Initializable, UUPSUpgradeable {
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
        //参与竞拍的资产类型
        //0x 地址表示ETH，其他表示ERC20代币合约地址
        address tokenAddress;

    }

    //状态变量
    mapping(uint256 => Auction) public auctions;
    //下一个拍卖ID
    uint256 public nextAuctionId;
    //管理员地址
    address public admin;

    // AggregatorV3Interface internal priceETHFeed;

    mapping(address => AggregatorV3Interface) public priceFeeds;

     //初始化函数

    function initialize() initializer public {
        admin = msg.sender;
     }

    function setPriceFeed(address tokenAddress,address _priceETHFeed) external {
        priceFeeds[tokenAddress] = AggregatorV3Interface(_priceETHFeed);
    }
    //ETH -> USD ：3872 2647 4900
    //USDC -> USD : 0.9997 8992
  function getChainlinkDataFeedLatestAnswer(address tokenAddress) public view returns (int256) {
    AggregatorV3Interface priceETHFeed = priceFeeds[tokenAddress];
    // prettier-ignore
    (
      /* uint80 roundId */
      ,
      int256 answer,
      /*uint256 startedAt*/
      ,
      /*uint256 updatedAt*/
      ,
      /*uint80 answeredInRound*/
    ) = priceETHFeed.latestRoundData();
    return answer;
  }

     //创建拍卖
    function createAuction(uint256 duration, uint256 startPrice,address nftAddress,uint256 tokenId) public {
        require(msg.sender == admin, "Only admin can create auctions");
        require(duration >= 10, "Duration must be greater than 0");
        require(startPrice > 0, "Start price must be greater than 0");

        //转移NFT到合约地址
        IERC721(nftAddress).approve(address(this), tokenId);


        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            duration: duration,
            startPrice: startPrice,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            startTime: block.timestamp,
            nftAddress: nftAddress,
            tokenId: tokenId,
            tokenAddress: address(0)
        });
        nextAuctionId++;
    }  

    //买家参与买单
    function placeBid(uint256 auctionId,uint256 amount,address _tokenAddress) external payable {
        Auction storage auction = auctions[auctionId];
        require(!auction.ended && block.timestamp < auction.startTime + auction.duration, "Auction has ended");
 
        //判断出价是否大于当前最高出价
        uint payValue;
        if (_tokenAddress != address(0)) {
            // 处理 ERC20
            // 检查是否是 ERC20 资产
            payValue = amount * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        } else {
            // 处理 ETH
            amount = msg.value;

            payValue = amount * uint(getChainlinkDataFeedLatestAnswer(address(0)));
        }
            //判断是否是ERC20资产
            uint256 startPriceValue = auction.startPrice * uint256(getChainlinkDataFeedLatestAnswer(_tokenAddress));
            uint256 highestBidValue = auction.highestBid * uint256(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        require(payValue >= startPriceValue && payValue > highestBidValue, "Bid is too low");

                if(_tokenAddress != address(0)){
                //转移ERC20代币到合约地址
                IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);

                }

         // 退还前最高价
        if (auction.highestBid > 0) {
            if (auction.tokenAddress == address(0)) {
                // auction.tokenAddress = _tokenAddress;
                payable(auction.highestBidder).transfer(auction.highestBid);
            } else {
                // 退回之前的ERC20
                IERC20(auction.tokenAddress).transfer(
                    auction.highestBidder,
                    auction.highestBid
                );
            }
        }
        
        auction.tokenAddress = _tokenAddress;
        auction.highestBid = amount;
        auction.highestBidder = msg.sender;
    }

    //结束拍卖
    function endAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(!auction.ended, "Auction already ended");
        require(block.timestamp >= auction.startTime + auction.duration, "Auction not yet ended!!!");

        IERC721(auction.nftAddress).safeTransferFrom(admin, auction.highestBidder, auction.tokenId);
        //将资金转移给卖家
        // payable(address(this)).transfer(address(this).balance);
        auction.ended = true;


    }

    
    function _authorizeUpgrade(address newImplementation) internal override view{
        require(msg.sender == admin, "Only admin can upgrade");
    }

}