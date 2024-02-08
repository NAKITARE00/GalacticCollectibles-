// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract GalacticCollectibles is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    address payable owner;

    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping(uint256 => Auction) private idToAuction;

    struct MarketItem {
        uint256 tokenId;
        string name;
        address payable seller;
        address payable owner;
        uint256 price;
        string dateFound;
        string rightAscension;
        string declination;
        string additionalInfo;
        bool sold;
    }

    struct Auction {
        uint256 tokenId;
        address payable seller;
        uint256 startingPrice;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool ended;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        string name,
        address seller,
        address owner,
        uint256 price,
        string rightAscension,
        string declination,
        string dateFound,
        bool sold
    );

    event AuctionCreated(
        uint256 indexed tokenId,
        address seller,
        uint256 startingPrice,
        uint256 endTime
    );

    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 bid);

    event AuctionEnded(uint256 indexed tokenId, address indexed winner, uint256 winningBid);


    constructor() ERC721("Crypto Tokens", "CT") {
        owner = payable(msg.sender);
    }

    // Mint the Token and list it in the marketplace
    function createToken(
        string memory tokenURI,
        string memory _name,
        uint256 price, 
        string memory _dateFound, 
        string memory _rightAscension,
        string memory _declination, 
        string memory _additionalInfo
    )
        public
        payable
        returns (uint)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId,_name, price, _dateFound, _rightAscension,_declination, _additionalInfo);
        return newTokenId;
    }

    // create market item
    function createMarketItem(
        uint256 tokenId,
        string memory _name,
        uint256 price, 
        string memory _dateFound, 
        string memory _rightAscension,
        string memory _declination, 
        string memory _additionaInfo) private 
        {
        require(price > 0, "Price must be at least 1 wei");
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            _name,
            payable(msg.sender),
            payable(address(this)),
            price,
            _dateFound,
            _rightAscension,
            _declination,
            _additionaInfo,
            false
        );
        _transfer(msg.sender, address(this), tokenId);
        emit MarketItemCreated(
            tokenId,
            _name,
            msg.sender,
            address(this),
            price,
            _rightAscension,
            _declination,
            _dateFound,
            false
        );
    }
 
    function createAuction(uint256 tokenId, uint256 startingPrice, uint256 duration) public {
        require(idToMarketItem[tokenId].owner == msg.sender, "Only item owner can create an auction");
        require(startingPrice > 0, "Starting price must be greater than 0");

        uint256 endTime = block.timestamp + duration;
        idToAuction[tokenId] = Auction(
            tokenId,
            payable(msg.sender),
            startingPrice,
            endTime,
            address(0),
            0,
            false
        );

        emit AuctionCreated(tokenId, msg.sender, startingPrice, endTime);
    }

    // place a bid on an ongoing auction
    function placeBid(uint256 tokenId) public payable {
        Auction storage auction = idToAuction[tokenId];
        require(auction.endTime > block.timestamp, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid must be greater than current highest bid");

        if (auction.highestBidder != address(0)) {
            // refund the previous highest bidder
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    // end an ongoing auction and transfer the NFT to the highest bidder
    function endAuction(uint256 tokenId) public {
        Auction storage auction = idToAuction[tokenId];
        require(auction.endTime <= block.timestamp, "Auction is still ongoing");
        require(!auction.ended, "Auction has already ended");

        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            idToMarketItem[tokenId].owner = payable(auction.highestBidder);
            idToMarketItem[tokenId].sold = true;
            _itemsSold.increment();
            _transfer(address(this), auction.highestBidder, tokenId);

            emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);
        }
    }
   
    // allow someone to resell
    function resellToken(uint256 tokenId, uint256 price) public payable {
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform this operation"
        );
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    // creating market sale
    function createMarketSale(uint256 tokenId) public payable {
        uint price = idToMarketItem[tokenId].price;
        address seller = idToMarketItem[tokenId].seller;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        (bool sellersent, ) = payable(seller).call{value: msg.value}("");
        require(sellersent, "Failed to send");
    }

    // Returns all unsold market items
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex = 0;
        // creating an empty array and provinding the size of the array that is unsold items as unsoldItemCount
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Returns only items that a user has purchased
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }   
        }
        // creating an empty array and providing the size of the array that is my item count as itemCount
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Returns only items a user has listed
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        // creating an empty array and provinding the size of the array that is total items as itemCount
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}