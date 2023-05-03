// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NFTMarketPlace__PriceMustBeAboveZero();
error NFTMarketPlace__NotApprovedForMarketplace();
error NFTMarketPlace__AlreadyListed(address nftAddress, uint256 tokenID);
error NFTMarketPlace__NotOwner();

contract NFTMarketPlace {
    constructor() {}

    struct Listing {
        uint256 price;
        address seller;
    }

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenID,
        uint256 price
    );

    // NFT CA -> NFT TokenID -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // Modifiers //
    modifier notListed(
        address nftAddress,
        uint256 tokenID,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenID];
        if (listing.price > 0) {
            revert NFTMarketPlace__AlreadyListed(nftAddress, tokenID);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenID,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenID);
        if (spender != owner) {
            revert NFTMarketPlace__NotOwner();
        }
        _;
    }

    // MAIN Functions //

    /// @notice Method for listing a NFT in the MarketPlace
    /// @param nftAddress: is the address of the NFT contract
    /// @param tokenID: the token ID of the NFT
    /// @param price: is the price of the listed NFT sale

    function itemList(
        address nftAddress,
        uint256 tokenID,
        uint256 price
    )
        external
        notListed(nftAddress, tokenID, msg.sender)
        isOwner(nftAddress, tokenID, msg.sender)
    {
        if (price <= 0) {
            revert NFTMarketPlace__PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenID) != address(this)) {
            revert NFTMarketPlace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenID] = Listing(price, msg.sender);
        emit ItemListed(msg.sender, nftAddress, tokenID, price);
    }
}
