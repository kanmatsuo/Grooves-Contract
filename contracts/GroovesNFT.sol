// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Library.sol";

interface IGroovesNFT {
    // listed token structure
    struct Token {
        uint256 id;
        address owner;
        string tokenURI;
        uint paytype;
        uint256 price;
        uint status;
        uint256 time;
    }

    struct Auction {
        uint32 i_interval; // For How much time does the nft seller want the auction to continue
        uint256 price; // The price of the nft  at which the auction will start
        uint256 s_lastTimeStamp; //The time at which the auction will start
        uint256 temporaryHighestBid; // The highest bid made for a nft at any given moment
        address currentWinner; //The adress which is currently winning the auction , at the end of the auction , this will automatically get set to the final winner
        address nftSeller; // The address of the seller of the nft
        bool auctionStarted; // A bool to keep track whether the auction has started or not ;
    }

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 time;
    }

    function transferNFT(address from, address to, uint256 tokenId) external;

    function setToken(Token memory t, uint256 tokenId) external;

    function getTokenForId(
        uint256 tokenId
    ) external view returns (Token memory);
}

contract GroovesNFT is
    ERC721URIStorage,
    ERC721Burnable,
    AccessControl,
    IGroovesNFT
{
    // role example
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // IERC20 public payToken = IERC20(0x13f184A0cf69319f888E982E5FDBFE80bC7d5a46); //localhost
    IERC20 public payToken = IERC20(0x52E087107876cFd8b460160CCA5074956D9AB27e); //testnet
    // address public admin = 0xe08dF132bd77E1f9c0608D1BDB6556450f6BFC0F; //localhost
    address public admin = 0x494332CfFC6Ca402547F4485C177622AbEc37004; //testnet

    constructor() ERC721("GroovesNFT", "GNFT") {
        // only admin can mint, list , auction , gacha function
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    modifier requireIsAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an Admin"
        );
        _;
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burnNFT(uint256 tokenId) public {
        _burn(tokenId);
    }

    // from AccessControl must initialized
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /*
    **************************************************************************************
                EVENTS WHICH WILL BE EMITTED DURING EXECUTION OF SMART CONTRACT
    ***************************************************************************************
    */

    mapping(uint256 => Token) private idToTokens;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //The first time a token is created, it is listed here
    function mintNFT(
        string memory tokenUri,
        uint256 quantity
    ) public requireIsAdmin {
        for (uint i = 0; i < quantity; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();

            // string memory tokenURI = string(
            //     abi.encodePacked(baseTokenURI, Strings.toString(newTokenId))
            // );

            //Mint the NFT with tokenId newTokenId to the address who called createToken
            _safeMint(msg.sender, newTokenId);

            //Map the tokenId to the tokenURI (which is an IPFS URL with the NFT metadata)
            _setTokenURI(newTokenId, tokenUri);

            idToTokens[newTokenId] = Token(
                newTokenId,
                msg.sender,
                tokenUri,
                0,
                0,
                1, // mint
                block.timestamp
            );
        }
    }

    //Returns all the NFTs that the current user is owner or seller in
    function getTokens() public view returns (Token[] memory) {
        Token[] memory items = new Token[](_tokenIds.current());

        // Important to get a count of all the NFTs that belong to the user before we can make an array for them

        for (uint i = 0; i < _tokenIds.current(); i++) {
            Token storage currentItem = idToTokens[i + 1];
            items[i] = currentItem;
        }
        return items;
    }

    function getTokenForId(
        uint256 tokenId
    ) public view override returns (Token memory) {
        return idToTokens[tokenId];
    }

    function setToken(Token memory t, uint256 tokenId) public override {
        idToTokens[tokenId] = t;
    }

    function transferNFT(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    function getCurrentId() public view returns (uint256) {
        return _tokenIds.current();
    }
}
