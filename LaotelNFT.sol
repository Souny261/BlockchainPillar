//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC1155Metadata_URI {
    function uri(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

abstract contract ERC721 is IERC165, IERC721, IERC721Metadata, IERC1155Metadata_URI,  IERC721Enumerable{
    mapping(address => uint) _balances; //owner => balance
    mapping(uint => address) _owners; //tokenID => owner
    mapping(address => mapping(address => bool)) _operatorApprovals; // owner => (operator => allow)
    mapping(uint => address) _tokenApprovals; //tokenId => operator
    string _name;
    string _symbol;
    mapping(uint => string) _tokenURIs; //token => uri
    uint[] _allTokens;
    mapping(address => mapping(uint => uint)) _ownerTokens; //Owner => (index => tokenId)


    constructor(string memory name_, string memory symbol_){
        _name = name_;
        _symbol=symbol_;
    }

    function name() public override view returns (string memory){
        return _name;
    }
    function symbol() public override view returns (string memory){
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public override view returns (string memory){
        return _tokenURIs[tokenId];
    }

    function uri(uint256 tokenId) public override view returns (string memory){
        return tokenURI(tokenId);
    }


    function supportsInterface(bytes4 interfaceId) public override pure returns (bool){
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IERC1155Metadata_URI).interfaceId
            || interfaceId == type(IERC721Enumerable).interfaceId;
    }
    // check total assets of user
    function balanceOf(address owner) public override view returns (uint256){
        require(owner != address(0), "Owner is zero address");
        return _balances[owner];
    }
    // check assets of user(ກວດວ່າເຮົາເປັນເຈົ້າຂອງແທ້ໍບ່)
    function ownerOf(uint256 tokenId) public override view returns (address){
        address owner = _owners[tokenId];
        require(owner != address(0), "token is not exists");
        return owner;
    }
    function setApprovalForAll(address operator, bool approved) public override{
        require(msg.sender != operator, "approval status for self");
        _operatorApprovals[msg.sender][operator] == approved;
        emit ApprovalForAll(msg.sender, operator, approved);

    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool){
        return _operatorApprovals[owner][operator];
     }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "appraval status for self");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "caller is not token owner or approval for all");
        _approve(to, tokenId);
     }
    function getApproved(uint256 tokenId) public override view returns (address){
        require(_owners[tokenId] != address(0), "token is not exits");
        return _tokenApprovals[tokenId];
     }
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(from != address(0), "transfer from zero address");
        require(to != address(0) , "transfer to zero address");
        address owner =ownerOf(tokenId);
        require(owner == from, "transfer from is not token owner");
        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not onwner or approver");
        _balances[from] -=1;
        _balances[to] +=1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override{
        transferFrom(from, to, tokenId);
        require(_checkOnErc721Received(from, to, tokenId, data), "transfer to non ERC721Receiver");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override{
        safeTransferFrom(from, to, tokenId, "");
    }

    function totalSupply() public override view returns (uint256){
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public override view returns (uint256){
        require(index <_allTokens.length, "index out of bounds");
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public override view returns (uint256){
        require(index < _balances[owner], "index out of bounds");
        return _ownerTokens[owner][index];
    }


    //  ===== Private or Internal Function =====
    function _approve(address to, uint tokenId) internal{
        _tokenApprovals[tokenId] = to;
        address owner =ownerOf(tokenId);
        emit Approval(owner, to, tokenId);
    }

    function _checkOnErc721Received(address from, address to, uint tokenId, bytes memory data) private returns(bool){
         if (to.code.length <= 0) return true;
        IERC721TokenReceiver receiver =  IERC721TokenReceiver(to);
        try receiver.onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 interfaceId){
            return interfaceId == type(IERC721TokenReceiver).interfaceId;
        }catch Error(string memory reason){
            revert(reason);
        }catch{
            revert("transfer to non ERC721Receiver implementer");
        }
    }

    function _mint(address to, uint tokenId, string memory url_) internal {
        require(to != address(0), "mint to zero address");
        require(_owners[tokenId] == address(0), "token already minted");
        _balances[to] +=1;
        _owners[tokenId] = to;
        _tokenURIs[tokenId] = url_;
        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint tokenId, string memory uri_, bytes memory data) internal{
        _mint(to, tokenId, uri_);
        require(_checkOnErc721Received(address(0), to, tokenId, data), "mint to non ERC721Receiver implementer");
    }

    function _safeMint(address to, uint tokenId, string memory uri_) internal{
        _safeMint(to, tokenId, uri_, "");
    }

    function _burn(uint tokenId) internal{
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not owner or approve");
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenURIs[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    // All Enumeration
    uint[] _allTokens;
    function _addTokenToAllEnumeration(uint tokenId)private{

    }
    function _removeTokenToAllEnumeration()private{
        
    }
    // Owner Enumeration
    mapping(address => mapping(uint => uint)) _ownerTokens; //Owner => (index => tokenId)

    function _addTokenToOwnerEnumeration()private{
        
    }
    function _removeTokenToOwnerEnumeration()private{
        
    }
}