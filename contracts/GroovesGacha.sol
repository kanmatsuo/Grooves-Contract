// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./GroovesNFT.sol";

contract GroovesGacha is GroovesNFT {
    event GachaAdded(uint length);
    event GachaCanceled(uint length);
    event GachaDone(uint length, address indexed operator, uint paytype);

    GroovesNFT nftContract;

    uint256 public spin1GrvcPrice;
    uint256 public spin5GrvcPrice;
    uint256 public spin10GrvcPrice;

    uint256 public spin1BnbPrice;
    uint256 public spin5BnbPrice;
    uint256 public spin10BnbPrice;

    constructor(address addr) {
        nftContract = GroovesNFT(addr);
        uint256 toWei = 10 ** 18;
        spin1GrvcPrice = 1 * toWei;
        spin5GrvcPrice = 4 * toWei;
        spin10GrvcPrice = 7 * toWei;

        spin1BnbPrice = 0.01 ether;
        spin5BnbPrice = 0.04 ether;
        spin10BnbPrice = 0.07 ether;
    }

    function getGachaSpinPrice() public view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](6);
        prices[0] = spin1GrvcPrice;
        prices[1] = spin5GrvcPrice;
        prices[2] = spin10GrvcPrice;
        prices[3] = spin1BnbPrice;
        prices[4] = spin5BnbPrice;
        prices[5] = spin10BnbPrice;
        return prices;
    }

    function setGachaSpinPrice(uint256[] memory prices) public {
        spin1GrvcPrice = prices[0];
        spin5GrvcPrice = prices[1];
        spin10GrvcPrice = prices[2];
        spin1BnbPrice = prices[3];
        spin5BnbPrice = prices[4];
        spin10BnbPrice = prices[5];
    }

    function addGachaList(uint256[] memory tokenIds) public requireIsAdmin {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            nftContract.transferNFT(msg.sender, address(this), tokenId);

            Token memory t = Token(
                tokenId,
                address(this),
                nftContract.tokenURI(tokenId),
                0,
                0,
                6, // mint
                block.timestamp
            );

            nftContract.setToken(t, tokenId);
        }
    }

    function removeGachaList(uint256[] memory tokenIds) public requireIsAdmin {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            nftContract.transferNFT(address(this), msg.sender, tokenId);

            Token memory t = Token(
                tokenId,
                msg.sender,
                nftContract.tokenURI(tokenId),
                0,
                0,
                1, // mint
                block.timestamp
            );

            nftContract.setToken(t, tokenId);
        }
    }

    function execGacha(uint256[] memory tokenIds, uint payType) public payable {
        uint256 amount = 0;
        uint256 len = tokenIds.length;

        if (len == 10 && payType == 1) amount = spin10GrvcPrice;
        if (len == 5 && payType == 1) amount = spin5GrvcPrice;
        if (len == 1 && payType == 1) amount = spin1GrvcPrice;

        if (len == 10 && payType == 2) amount = spin10BnbPrice;
        if (len == 5 && payType == 2) amount = spin5BnbPrice;
        if (len == 1 && payType == 2) amount = spin1BnbPrice;

        if (payType == 1) {
            require(
                payToken.balanceOf(msg.sender) > amount,
                "You don't have enough GRVC."
            );

            payToken.transferFrom(msg.sender, admin, amount);
        } else {
            require(
                address(msg.sender).balance > amount,
                "You don't have enough BNB."
            );
            payable(admin).transfer(amount);
            // (bool success, ) = msg.sender.call{value: amount}("");
            // require(success, "Transfer failed");
        }

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = tokenIds[i];

            nftContract.transferNFT(address(this), msg.sender, tokenId);

            Token memory t = Token(
                tokenId,
                msg.sender,
                nftContract.tokenURI(tokenId),
                payType,
                amount / len,
                7,
                block.timestamp
            );

            nftContract.setToken(t, tokenId);
        }
    }
}
