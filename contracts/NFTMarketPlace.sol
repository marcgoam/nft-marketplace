// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NFTMarketPlace__PriceMustBeAboveZero();
error NFTMarketPlace__NotApprovedForMarketplace();
error NFTMarketPlace__AlreadyListed(address nftAddress, uint256 tokenID);
error NFTMarketPlace__NotOwner();
error NFTMarketPlace__NotListed(address nftAddress, uint256 tokenID);
error NFTMarketPlace__PriceError(
    address nftAddress,
    uint256 tokenID,
    uint256 price
);
error NFTMarketPlace__noBalance();
error NFTMarketPlace__notSuccess();

contract NFTMarketPlace is ReentrancyGuard {
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

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenID,
        uint256 price
    );

    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenID
    );

    // NFT CA -> NFT TokenID -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // Seller Address -> Amount earned
    mapping(address => uint256) private s_balance;

    // Modifiers //
    modifier notListed(address nftAddress, uint256 tokenID) {
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

    modifier isListed(address nftAddress, uint256 tokenID) {
        Listing memory listing = s_listings[nftAddress][tokenID];
        if (listing.price <= 0) {
            revert NFTMarketPlace__NotListed(nftAddress, tokenID);
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
        notListed(nftAddress, tokenID)
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

    function itemBuy(
        address nftAddress,
        uint256 tokenID
    ) external payable isListed(nftAddress, tokenID) {
        Listing memory item = s_listings[nftAddress][tokenID];
        if (msg.value < item.price) {
            revert NFTMarketPlace__PriceError(nftAddress, tokenID, item.price);
        }
        s_balance[item.seller] = s_balance[item.seller] + msg.value;
        delete (s_listings[nftAddress][tokenID]);
        // We put this line at the bottom for protecting agains Reentrancy-attack
        IERC721(nftAddress).safeTransferFrom(item.seller, msg.sender, tokenID);
        emit ItemBought(msg.sender, nftAddress, tokenID, item.price);
    }

    function cancelListing(
        address nftAddress,
        uint256 tokenID
    )
        external
        isOwner(nftAddress, tokenID, msg.sender)
        isListed(nftAddress, tokenID)
    {
        delete (s_listings[nftAddress][tokenID]);
        emit ItemCanceled(msg.sender, nftAddress, tokenID);
    }

    function updateListing(
        address nftAddress,
        uint256 tokenID,
        uint256 priceUpdated
    )
        external
        isListed(nftAddress, tokenID)
        isOwner(nftAddress, tokenID, msg.sender)
    {
        s_listings[nftAddress][tokenID].price = priceUpdated;
        emit ItemListed(msg.sender, nftAddress, tokenID, priceUpdated);
    }

    function withdraw() external {
        uint256 balance = s_balance[msg.sender];
        if (balance <= 0) {
            revert NFTMarketPlace__noBalance();
        }
        s_balance[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        if (!success) {
            revert NFTMarketPlace__notSuccess();
        }
    }

    // Getter Functions //

    function getListing(
        address nftAddress,
        uint256 tokenID
    ) external view returns (Listing memory) {
        return s_listings[nftAddress][tokenID];
    }

    function getBalance(address seller) external view returns (uint256) {
        return s_balance[seller];
    }
}
