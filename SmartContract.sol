//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SmartContract is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    mapping(address => bool) public isALWL;
    mapping(address => bool) public isALOG;

    uint public constant MXPR1 = 888;
    string public baseExtension = ".json";
    uint public constant forMarketing = 888;
    uint public constant forMeta = 888;
    uint public constant forPublic = 6224 + MXPR1;
    uint public constant MAX_SUPPLY = forMarketing + forMeta + forPublic;
    bool public paused = false;
    string public baseTokenURI;

    constructor(string memory _name,
                string memory _symbol,
                string memory baseURI
    ) 
        ERC721(_name, _symbol) {
        setBaseURI(baseURI);
    }

    function ALWL(address[] calldata wA) public onlyOwner {
        for (uint i = 0; i < wA.length; i++) {
            isALWL[wA[i]] = true;
        }
    }
    function ALOG(address[] calldata OA) public onlyOwner {
        for (uint i = 0; i < OA.length; i++) {
            isALOG[OA[i]] = true;
        }
    }

    function reserveNFTs(uint _count) public onlyOwner {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= MAX_SUPPLY);

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // Presale mints of 1
    function preSale1(uint _count) public payable {
        uint totalMinted = _tokenIds.current();
        uint psP = 0.01 ether;
        require(paused != true);
        require(totalMinted.add(_count) <= MXPR1);
        require(msg.value >= psP.mul(_count));
        require(isALWL[msg.sender] || isALOG[msg.sender]);

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }

    }

    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();
        uint PRICE = 0.01 ether;
        require(paused != true);
        require(totalMinted.add(_count) <= forPublic);
        require(msg.value >= PRICE.mul(_count));

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function minttoSomeaddress(uint256 _count, address _toAD) public payable onlyOwner {
        uint totalMinted = _tokenIds.current();
        uint price = 0.01 ether;
        require(paused != true);
        require(totalMinted.add(_count) <= forPublic);
        require(msg.value >= price.mul(_count));

        for (uint256 i = 1; i <= _count; i++) {
            uint newTokenID = _tokenIds.current();
            _safeMint(_toAD, newTokenID);
            _tokenIds.increment();
        }

    }
    
    function freeminttoSomeaddress(uint256 _count, address _toAD) public payable onlyOwner {
        uint totalMinted = _tokenIds.current();
        //uint price = 0.01 ether;
        require(paused != true);
        require(totalMinted.add(_count) <= MAX_SUPPLY);
        //require(msg.value >= price.mul(_count));

        for (uint256 i = 1; i <= _count; i++) {
            uint newTokenID = _tokenIds.current();
            _safeMint(_toAD, newTokenID);
            _tokenIds.increment();
        }

    }

    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

///this part makes NFT's metadata.
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId)
            
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)): "";
    }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success);
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0)) {
            address owner = ownerOf(tokenId);
            require(owner == msg.sender);
        }
    }

    function burn(uint256 tokenId) public {
        super._burn(tokenId);
    }

    ////this is for erc20 token/////
    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }

    TokenInfo[] public AllowedCrypto;
    
    function addCurrency(
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }

    mapping(address => mapping (address => uint256)) allowed;

    function mintwithERC20forOG(uint256 _count, uint256 _pid) public payable {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 cost;
        cost = tokens.costvalue;
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(_count) <= MXPR1);
        require(isALWL[msg.sender] || isALOG[msg.sender]);
        require(paused != true);

        
        for (uint256 i = 1; i <= _count; i++) {
            paytoken.transferFrom(msg.sender, address(this), cost);
            uint newTokenID = _tokenIds.current();
            _safeMint(msg.sender, newTokenID);
            _tokenIds.increment();
        }
      
    }

    function mintwithERC20(uint256 _count, uint256 _pid) public payable {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 cost;
        cost = tokens.costvalue;
        uint totalMinted = _tokenIds.current();
        require(paused != true);
        require(totalMinted.add(_count) <= forPublic);
        
        
        for (uint256 i = 1; i <= _count; i++) {
            paytoken.transferFrom(msg.sender, address(this), cost);
            uint newTokenID = _tokenIds.current();
            _safeMint(msg.sender, newTokenID);
            _tokenIds.increment();
        }
    }

    function withdrawERC20(uint256 _pid) public payable onlyOwner() {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
    }
    function getCryptotoken(uint256 _pid) public view virtual returns(IERC20) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = tokens.paytoken;
            return paytoken;
    }
    function getNFTCost(uint256 _pid) public view virtual returns(uint256) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            uint256 cost;
            cost = tokens.costvalue;
            return cost;
    }

}

