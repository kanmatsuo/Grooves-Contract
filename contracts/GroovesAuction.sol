// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./GroovesNFT.sol";

contract GroovesAuction is GroovesNFT {
    //This event will be emitted when a instance of Auction is inititialized by the seller
    event AuctionInitialized(
        uint256 indexed tokenId,
        uint256 price,
        uint32 interval
    );

    //This Event will be emitted when a  bid is made by a adress
    event BidMade(
        uint256 indexed tokenId,
        address indexed bidMakerAddress,
        uint256 price
    );

    //This Event will be emitted when a  auction winner receives the nft After the auction has ended
    event WinNftAfterAuction(
        uint256 indexed tokenId,
        address indexed nftWinnerAddress,
        uint256 finalPrice
    );

    //This Event will be emitted when a  auction ended without no winner , and the seller of the nft gets
    //the nft back to his address
    event WithdrawNftAfterAuctionUnsuccesful(uint256 indexed tokenId);

    //This Event will be emitted when a  auction ended with a succesful bid , and the seller of the nft gets
    //the winning bid transferred to his wallet
    event ReceiveWinningBidAfterAuction(uint256 tokenId, uint256 winningBid);

    //mapping from a nft(adress + token Id) to a Auction
    mapping(uint256 => Auction) public idToAuctions;
    mapping(uint256 => Bid[]) public bids;

    GroovesNFT nftContract;

    constructor(address addr) {
        nftContract = GroovesNFT(addr);
    }

    //State Variables

    /*
    **************************************************************************************
                STRUCTURES USED FOR THE SMART CONTRACT
    ***************************************************************************************
    */
    function getBids(uint256 tokenId) public view returns (Bid[] memory) {
        return bids[tokenId];
    }

    /*
    **************************************************************************************
                MODIFIERS TO ENHANCE CODE READABLITY
    ***************************************************************************************
    */
    //This Modifier will check whether the caller of function is indeed the owner of the nft
    modifier requireIsOwner(uint256 tokenId, address spender) {
        address owner = nftContract.ownerOf(tokenId);
        require(spender == owner, "You are not owner!");
        _;
    }

    //This modifier will check whether the bid made is a valid bid by checking if the msg.value is grater than
    //the minimum price of the nft as well as the previous Highest bid

    modifier requireIsBidValid(uint256 tokenId, uint256 bidAmount) {
        require(
            bidAmount > idToAuctions[tokenId].temporaryHighestBid,
            "Please make a bid more bigger!"
        );
        _;
    }

    //This modifier will check whether the auction has ended

    modifier requireIsAuctionEnded(uint256 tokenId) {
        require(
            block.timestamp - idToAuctions[tokenId].s_lastTimeStamp >
                idToAuctions[tokenId].i_interval ==
                true,
            "Auction is not ended!"
        );
        _;
    }

    //This modifier will check whether the auction has ended

    modifier requireIsAuctionNotEnded(uint256 tokenId) {
        require(
            block.timestamp - idToAuctions[tokenId].s_lastTimeStamp <
                idToAuctions[tokenId].i_interval ==
                true,
            "Auction is ended!"
        );
        _;
    }

    //This modifier will check whether the caller of the function is the auction winner

    modifier requireIsAuctionWinner(uint256 tokenId, address sender) {
        require(
            sender == idToAuctions[tokenId].currentWinner,
            "You are not winner!"
        );
        _;
    }

    //This modifier will check whether the caller of the function is the seller of the nft or not

    modifier requireIsAuctionNftSeller(uint256 tokenId, address sender) {
        require(
            sender == idToAuctions[tokenId].nftSeller,
            "You are not owner!"
        );
        _;
    }

    //This modifier will check whether the auction has any bids

    modifier requireIsAuctionBidded(uint256 tokenId) {
        require(
            idToAuctions[tokenId].price !=
                idToAuctions[tokenId].temporaryHighestBid,
            "There are no bids!"
        );
        _;
    }

    //This modifier will check whether the auction has no bids

    modifier requireIsAuctionNotBidded(uint256 tokenId) {
        require(
            idToAuctions[tokenId].price ==
                idToAuctions[tokenId].temporaryHighestBid,
            "There are some bids!"
        );
        _;
    }

    /*
    **************************************************************************************
                Initializing Auction And Making Bids Functions
    ***************************************************************************************
*/

    //This Function will be called by the nft owner to initialize the auction and specify
    // and specify their  custom parameters
    //The user will have the choice to specify for how many duration does he want the auction to continue
    // And what will be the starting price of the nft
    function InitializeAuction(
        uint256 _tokenId,
        uint256 _price,
        uint32 interval,
        uint payType
    ) public requireIsOwner(_tokenId, msg.sender) requireIsAdmin {
        nftContract.transferNFT(msg.sender, address(this), _tokenId);

        idToAuctions[_tokenId].i_interval = interval;
        idToAuctions[_tokenId].price = _price;
        idToAuctions[_tokenId].temporaryHighestBid = _price;
        idToAuctions[_tokenId].nftSeller = msg.sender;
        idToAuctions[_tokenId].s_lastTimeStamp = block.timestamp;

        Token memory t = Token(
            _tokenId,
            address(this),
            nftContract.tokenURI(_tokenId),
            payType,
            _price,
            4, // list status
            block.timestamp
        );

        nftContract.setToken(t, _tokenId);

        require(
            nftContract.ownerOf(_tokenId) == address(this),
            "failed to tranfer nft"
        );
    }

    //This function will be called whenever a address  will make a bid
    // We will do all the necessary checks that whether our bid is valid or not
    //After the checks we will change the state variable of the smart contract
    //After changing the state we will transfer funds from the adress who made the bid to contract

    function makeBid(
        uint256 _tokenId,
        uint256 _amount
    )
        public
        payable
        requireIsBidValid(_tokenId, _amount)
        requireIsAuctionNotEnded(_tokenId)
    {
        Token memory t = nftContract.getTokenForId(_tokenId);

        if (idToAuctions[_tokenId].auctionStarted) {
            if (t.paytype == 1) {
                payToken.transfer(
                    idToAuctions[_tokenId].currentWinner,
                    idToAuctions[_tokenId].temporaryHighestBid
                );
            } else {
                (bool success, ) = idToAuctions[_tokenId].currentWinner.call{
                    value: idToAuctions[_tokenId].temporaryHighestBid
                }("");
                require(success, "Transfer failed");
            }
        }

        if (t.paytype == 1) {
            payToken.transferFrom(msg.sender, address(this), _amount);
        }

        idToAuctions[_tokenId].auctionStarted = true;
        idToAuctions[_tokenId].temporaryHighestBid = _amount;
        idToAuctions[_tokenId].currentWinner = msg.sender;

        bids[_tokenId].push(Bid(msg.sender, _amount, block.timestamp));
    }

    /*
    **************************************************************************************
                These functions will be called after the auction has ended
    ***************************************************************************************
*/

    //This function will be called by nft auction winner and it will transfer the nft from contract
    //to theadress of the nft winner
    function receiveNft(
        uint256 _tokenId
    )
        public
        // requireIsAuctionEnded(_tokenId)
        requireIsAuctionWinner(_tokenId, msg.sender)
    {
        //Transfering the nft to the winner

        nftContract.transferNFT(address(this), msg.sender, _tokenId);

        Token memory t = nftContract.getTokenForId(_tokenId);

        t.price = idToAuctions[_tokenId].temporaryHighestBid;
        t.time = block.timestamp;
        t.owner = msg.sender;

        nftContract.setToken(t, _tokenId);

        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "failed to tranfer nft"
        );
    }

    //This function will be called by the seller of the nft if there was no bid on the auction
    //Meaning the Auction Failed
    function withdrawNft(
        uint256 _tokenId
    )
        public
        // requireIsAuctionEnded(_tokenId)
        requireIsAuctionNftSeller(_tokenId, msg.sender)
        requireIsAuctionNotBidded(_tokenId)
        requireIsAdmin
    {
        nftContract.transferNFT(address(this), msg.sender, _tokenId);

        idToAuctions[_tokenId] = Auction(
            0,
            0,
            0,
            0,
            address(0),
            msg.sender,
            false
        );

        Token memory t = Token(
            _tokenId,
            msg.sender,
            nftContract.tokenURI(_tokenId),
            0,
            0,
            1,
            block.timestamp
        );

        nftContract.setToken(t, _tokenId);

        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "failed to tranfer nft"
        );
    }

    //This function will be called by the seller of the nft if the auction was succesful
    function withdrawWinningBid(
        uint256 _tokenId
    )
        public
        // requireIsAuctionEnded(_tokenId)
        requireIsAuctionNftSeller(_tokenId, msg.sender)
        requireIsAuctionBidded(_tokenId)
        requireIsAdmin
    {
        Token memory t = nftContract.getTokenForId(_tokenId);

        if (t.paytype == 1) {
            payToken.transfer(
                msg.sender,
                idToAuctions[_tokenId].temporaryHighestBid
            );
        } else {
            (bool success, ) = msg.sender.call{
                value: idToAuctions[_tokenId].temporaryHighestBid
            }(""); //At this point the temporary highestbid will become the highest bid
            require(success, "Transfer failed");
        }

        t.status = 5;
        t.owner = idToAuctions[_tokenId].currentWinner;

        nftContract.setToken(t, _tokenId);
    }

    function getAuctionForId(
        uint256 tokenId
    ) public view returns (Auction memory) {
        return idToAuctions[tokenId];
    }
}
