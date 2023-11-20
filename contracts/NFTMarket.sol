// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds; //total number of properties created
    Counters.Counter private _itemsSold; //total number of properties sold

    address payable owner; //owner of the smart contract
    uint256 listingPrice = 0.05 ether; //comission to put a new  property in the properties-store

    constructor(){
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        string address_property;
        address payable seller; //person selling the property
        address payable owner; //owner of the property
        uint256 price;
        bool sold;
    }

    //a way to access values of the MarketItem struct by passing an integer ID
    mapping(uint256 => MarketItem) private idToMarketItem;

    //log message (when Item is sold)
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        string address_property,
        address  seller,
        address  owner,
        uint256 price,
        bool sold
    );

    //function to get the price of a bottle of wine
    function getListingPrice() public view returns (uint256){
        return listingPrice;
    }

    //function to set the price of a bottle of wine
    function setListingPrice(uint _price) public returns(uint) {
         if(msg.sender == address(this) ){
             listingPrice = _price;
         }
         return listingPrice;
    }

    //function to create a bottle of wine in the wine-store
    function createMarketItem(
        address nftContract, 
        uint256 tokenId,
        string memory address_property,
        uint256 price) public payable nonReentrant{
        require(price > 0, "Price must be above zero");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        
        _itemIds.increment(); //add 1 to the total number of properties created
        uint256 itemId = _itemIds.current(); //update the current item ids to the new id of the properties
        

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract, //direction of the nft contract
            tokenId,
            address_property,
            payable(msg.sender), //address of the seller putting the nft up for sale
            payable(address(0)), //no owner yet (set owner to empty address)
            price,
            false
        );

        //transfer ownership of the nft to the contract itself
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        //log the transaction with the characteristics of the property
        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            address_property,
            msg.sender,
            address(0),
            price,
            false);
        }


        //function to create a sale
        function createMarketSale(
            address nftContract,
            uint256 itemId
            ) public payable nonReentrant{
                uint price = idToMarketItem[itemId].price;
                uint tokenId = idToMarketItem[itemId].tokenId;

                //require(msg.value == price, "Please submit the asking price in order to complete the purchase");

                //pay the seller the amount
                idToMarketItem[itemId].seller.transfer(msg.value);

                //transfer ownership of the nft from the contract itself to the buyer
                IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

                idToMarketItem[itemId].owner = payable(msg.sender); //mark buyer as new owner
                idToMarketItem[itemId].sold = true; //mark that the bottle of wine has been sold
                _itemsSold.increment(); //increment the total number of bottle of wines sold by 1
                payable(owner).transfer(listingPrice); //pay owner of contract the listing price
        }


        //total number of properties unsold in the wine-store
        function fetchMarketItems() public view returns (MarketItem[] memory){
            uint itemCount = _itemIds.current(); //total number of items ever created
            //total number of properties that are unsold = 
            //total bottle of properties created - total bottle of wines ever sold
            uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
            uint currentIndex = 0;

            MarketItem[] memory items =  new MarketItem[](unsoldItemCount);

            //loop through all items ever created
            for(uint i = 0; i < itemCount; i++){

                //get only the unsold bottle of wines
                //check if the bottle of wine has not been sold
                //by checking if the bottle of wine has got an owner or not
                if(idToMarketItem[i+1].owner == address(0)){
                    uint currentId = idToMarketItem[i + 1].itemId;
                    MarketItem storage currentItem = idToMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
            return items; //return an array of all the bottle of wines unsold
        }

        //fetch list of the properties owned by an user
        function fetchMyNFTs() public view returns (MarketItem[] memory){
            //get total number of items ever created
            uint totalItemCount = _itemIds.current();
            uint itemCount = 0;
            uint currentIndex = 0;

            for(uint i = 0; i < totalItemCount; i++){
                //get only the items that this user has bought/is the owner
                if(idToMarketItem[i+1].owner == msg.sender){
                    itemCount += 1; //total length
                }
            }

            MarketItem[] memory items = new MarketItem[](itemCount);
            for(uint i = 0; i < totalItemCount; i++){
               if(idToMarketItem[i+1].owner == msg.sender){
                   uint currentId = idToMarketItem[i+1].itemId;
                   MarketItem storage currentItem = idToMarketItem[currentId];
                   items[currentIndex] = currentItem;
                   currentIndex += 1;
               }
            }
            return items;
        }


         //fetch list of properties bought by this user
        function fetchItemsCreated() public view returns (MarketItem[] memory){
            //get total number of items ever created
            uint totalItemCount = _itemIds.current();

            uint itemCount = 0;
            uint currentIndex = 0;


            for(uint i = 0; i < totalItemCount; i++){
                //get only the items that this user has bought/is the owner
                if(idToMarketItem[i+1].seller == msg.sender){
                    itemCount += 1; //total length
                }
            }

            MarketItem[] memory items = new MarketItem[](itemCount);
            for(uint i = 0; i < totalItemCount; i++){
               if(idToMarketItem[i+1].seller == msg.sender){
                   uint currentId = idToMarketItem[i+1].itemId;
                   MarketItem storage currentItem = idToMarketItem[currentId];
                   items[currentIndex] = currentItem;
                   currentIndex += 1;
               }
            }
            return items;
        }

}