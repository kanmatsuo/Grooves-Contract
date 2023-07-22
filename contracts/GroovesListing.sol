// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./GroovesNFT.sol";

contract GroovesListing is GroovesNFT {
    // notify to admin list status
    event TokenListedSuccess(uint256 tokenId, uint payType, uint256 price);
    // notify to price update
    event ListPriceUpdated(uint256 tokenId, uint payType, uint256 price);
    // token cancel list
    event TokenCancelListSuccess(uint256 tokenId);
    // token sale complete.
    event NFTSold(uint256 tokenId, address owner, uint payType, uint256 price);

    GroovesNFT nftContract;

    constructor(address addr) {
        nftContract = GroovesNFT(addr);
    }

    function createListedToken(
        uint256 tokenId,
        uint payType,
        uint256 price
    ) public requireIsAdmin {
        require(price > 0, "Make sure the price isn't negative");

        nftContract.transferNFT(msg.sender, address(this), tokenId);

        Token memory t = Token(
            tokenId,
            address(this),
            nftContract.tokenURI(tokenId),
            payType,
            price,
            2, // list status
            block.timestamp
        );

        nftContract.setToken(t, tokenId);
    }

    function cancelListedToken(uint256 tokenId) public requireIsAdmin {
        nftContract.transferNFT(address(this), msg.sender, tokenId);

        Token memory t = Token(
            tokenId,
            msg.sender,
            nftContract.tokenURI(tokenId),
            0,
            0,
            1,
            block.timestamp
        );

        nftContract.setToken(t, tokenId);
    }

    function updateListPrice(
        uint256 tokenId,
        uint payType,
        uint256 price
    ) public requireIsAdmin {
        require(price > 0, "Make sure the price isn't negative");

        Token memory t = nftContract.getTokenForId(tokenId);

        t.price = price;
        t.paytype = payType;
        t.time = block.timestamp;

        nftContract.setToken(t, tokenId);
    }

    function execSale(uint256 tokenId) public payable {
        Token memory t = nftContract.getTokenForId(tokenId);

        uint256 price = t.price;
        uint payType = t.paytype;

        if (payType == 1) {
            require(
                payToken.balanceOf(msg.sender) > price,
                "You don't have enough GRVC."
            );
            payToken.transferFrom(msg.sender, admin, price);
        } else {
            require(
                address(msg.sender).balance > price,
                "You don't have enough BNB."
            );
            payable(admin).transfer(price);
        }

        nftContract.transferNFT(address(this), msg.sender, tokenId);

        t.owner = msg.sender;
        t.status = 3;
        t.time = block.timestamp;

        nftContract.setToken(t, tokenId);
    }
}
