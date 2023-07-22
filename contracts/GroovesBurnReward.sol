// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./GroovesNFT.sol";

contract GroovesBurnReward is GroovesNFT {
    GroovesNFT nftContract;

    constructor(address addr) {
        nftContract = GroovesNFT(addr);
    }

    function addAwardList(uint256[] memory tokenIds) public requireIsAdmin {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            nftContract.transferNFT(msg.sender, address(this), tokenId);

            Token memory t = Token(
                tokenId,
                address(this),
                nftContract.tokenURI(tokenId),
                0,
                0,
                8, // mint
                block.timestamp
            );

            nftContract.setToken(t, tokenId);
        }
    }

    function removeAwardList(uint256[] memory tokenIds) public requireIsAdmin {
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

    function execBurnReward(uint256[] memory tokenIds, uint256 id) public {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = tokenIds[i];

            Token memory token = nftContract.getTokenForId(tokenId);
            token.status = 10;
            token.time = block.timestamp;
            nftContract.setToken(token, tokenId);
            nftContract.burnNFT(tokenId);
        }

        nftContract.transferNFT(address(this), msg.sender, id);

        Token memory t = Token(
            id,
            msg.sender,
            nftContract.tokenURI(id),
            0,
            0,
            9, // reward
            block.timestamp
        );

        nftContract.setToken(t, id);
    }
}
