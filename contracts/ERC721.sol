pragma solidity ^0.4.24;

contract ERC721Reciever{
    function onERC721Received(
        address _from,
        address _owner,
        string _tokenVIN,
        bytes _data
    ) public returns(bytes4);
}

contract ERC721 {

    ///  This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, string indexed _tokenId);

    /// This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, string indexed _tokenId);

    /// This emits when color for an NFT is changed.
    event TokenColorChanged(string indexed _tokenVIN, string _tokenColor);

    /// This emits when registration number for an NFT is changed.
    event TokenRegNumberChanged(string indexed _tokenVIN, string indexed _tokenRegNumber);

    event TokenRecovered(string _tokenVIN);

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    // Total number of token available on the blockchain
    uint256 public totalSupply;

    address contractOwner;

    address allowedToDemolish;

    address allowedToRecover;

    // Mapping from account to number of token it owns
    mapping (address => uint256) balances;

    // Mapping from token VIN to its owner
    mapping (string => address) tokenOwner;

    // Maping from token VIN to approved account
    mapping (string => address) tokenApprovals;

    // Mapping from token VIN to its color
    mapping (string => string) private tokenColor;

    // Mapping from token VIN to its registration number
    mapping (string => string) private tokenRegNumber;

    constructor() public {
        totalSupply = 0;
        contractOwner = msg.sender;
    }

   // @dev Approves another address to transfer the given token VIN
   // The zero address indicates there is no approved address.
   // There can only be one approved address per token at a given time.
   // Can only be called by the token owner.
   // @param _to address to be approved for the given token VIN
   // @param _tokenVIN string VIN of the token to be approved
    function approve(address _approved, string _tokenVIN) public {
        address owner = ownerOf(_tokenVIN);
        require(owner == msg.sender);
        require(_approved != msg.sender);
        tokenApprovals[_tokenVIN] = _approved;
        emit Approval(owner, _approved, _tokenVIN);
    }

   // @dev Transfers the ownership of a given token VIN to another address
   // Requires the msg sender to be the owner or approved
   // @param _from current owner of the token
   // @param _to address to receive the ownership of the given token VIN
   // @param _tokenVIN string VIN of the token to be transferred
    function transferFrom(address _from, address _to, string _tokenVIN) public {
        require(_from != address(0) && _to != address(0));
        require(_from != _to);
        address owner = ownerOf(_tokenVIN);
        require(owner == _from);
        require(owner == msg.sender || getApproved(_tokenVIN) == msg.sender);
        clearApproval(_from, _tokenVIN);
        removeTokenFrom(_from, _tokenVIN);
        addTokenTo(_to, _tokenVIN);
        emit Transfer(_from, _to, _tokenVIN);
    }

   // @dev Gets the balance of the specified address
   // @param _owner address to query the balance of
   // @return uint256 representing the amount owned by the passed address
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

   // @dev Gets the owner of the specified token VIN
   // @param _tokenVIN string VIN of the token to query the owner of
   // @return owner address currently marked as the owner of the given token VIN
    function ownerOf(string _tokenVIN) public view returns (address) {
        return tokenOwner[_tokenVIN];
    }

   // @dev Gets the approved address for a token ID, or zero if no address set
   // @param _tokenVIN string VIN of the token to query the approval of
   // @return address currently approved for the given token VIN
    function getApproved(string _tokenVIN) public view returns (address) {
        return tokenApprovals[_tokenVIN];
    }

   // @dev Internal function to clear current approval of a given token VIN
   // Reverts if the given address is not indeed the owner of the token
   // @param _owner owner of the token
   // @param _tokenVIN string VIN of the token to be transferred
    function clearApproval(address _owner, string _tokenVIN) internal {
        require(ownerOf(_tokenVIN) == _owner);
        if (tokenApprovals[_tokenVIN] != address(0)) {
            tokenApprovals[_tokenVIN] = address(0);
        }
    }

   // @dev Internal function to remove a token VIN from the list of a given address
   // @param _from address representing the previous owner of the given token VIN
   // @param _tokenVIN string VIN of the token to be removed from the tokens list of the given address
    function removeTokenFrom(address _from, string _tokenVIN) internal {
        require(ownerOf(_tokenVIN) == _from);
        tokenOwner[_tokenVIN] = address(0);
        balances[_from] -= 1;
    }

   // @dev Internal function to add a token VIN to the list of a given address
   // @param _to address representing the new owner of the given token VIN
   // @param _tokenVIN string VIN of the token to be added to the tokens list of the given address
    function addTokenTo(address _to, string _tokenVIN) internal {
        require(tokenOwner[_tokenVIN] == address(0));
        tokenOwner[_tokenVIN] = _to;
        balances[_to] += 1;
    }

   // @dev Produce a new token
   // Reverts if the given token VIN already exists
   // Reverts if the address token should be given to equals 0
   // @param _to The address that will own the produced token
   // @param _tokenVIN string VIN of the token to be produced by the msg.sender
   // @param _color string color of the produced token
    function produce(address _to, string _tokenVIN, string _color) public {
        require(_to != address(0));
        require(tokenOwner[_tokenVIN] == address(0));
        addTokenTo(_to, _tokenVIN);
        tokenColor[_tokenVIN] = _color;
        totalSupply += 1;
        emit Transfer(address(0), _to, _tokenVIN);
    }

   // @dev Produce a new token
   // Reverts if the given token VIN already exists
   // Reverts if the address token should be given to equals 0
   // @param _to The address that will own the produced token
   // @param _tokenVIN string VIN of the token to be produced by the msg.sender
   // @param _color string color of the produced token
   // @param _regNumeber string regestration number of the produced token
    function produce(address _to, string _tokenVIN, string _color, string _regNumber) public {
        require(_to != address(0));
        require(tokenOwner[_tokenVIN] == address(0));
        addTokenTo(_to, _tokenVIN);
        tokenColor[_tokenVIN] = _color;
        tokenRegNumber[_tokenVIN] = _regNumber;
        totalSupply += 1;
        emit Transfer(address(0), _to, _tokenVIN);
    }

   // @dev Destroy a specific token
   // Reverts if the token does not exist
   // @param _tokenId uint256 ID of the token being burned by the msg.sender
    function demolishToken(string _tokenVIN) public {
        require(msg.sender == allowedToRecover);
        address owner = tokenOwner[_tokenVIN];
        clearApproval(owner, _tokenVIN);
        removeTokenFrom(owner, _tokenVIN);
        totalSupply -= 1;
        emit Transfer(owner, address(0), _tokenVIN);
    }

   // @dev Gets the color of the specified token VIN
   // @param _tokenVIN string VIN of the token to query the color of
   // @return color string currently marked as the color of the given token VIN
    function getTokenColor(string _tokenVIN) public view returns (string) {
        require(ownerOf(_tokenVIN) != address(0));
        return tokenColor[_tokenVIN];
    }

   // @dev Gets the registration number of the specified token VIN
   // @param _tokenVIN string VIN of the token to query the registration number of
   // @return registration number string currently marked as the registration number of the given token VIN
    function getTokenRegNumber(string _tokenVIN) public view returns (string) {
        require(ownerOf(_tokenVIN) != address(0));
        return tokenRegNumber[_tokenVIN];
    }

   // @dev Change color of specified token VIN
   // Reverts if the given token VIN does not exist
   // Reverts if the given address is not indeed the owner of the token or approved
   // @param _tokenVIN string VIN of the specified token
   // @param _newTokenColor string color the specified token should be set to
    function setTokenColor(string _tokenVIN, string _newTokenColor) public {
        address owner = ownerOf(_tokenVIN);
        require(owner != address(0));
        require(owner == msg.sender || getApproved(_tokenVIN) == msg.sender);
        tokenColor[_tokenVIN] = _newTokenColor;
    }

   // @dev Change registration number of specified token VIN
   // Reverts if the given token VIN does not exist
   // Reverts if the given address is not indeed the owner of the token or approved
   // @param _tokenVIN string VIN of the specified token
   // @param _newTokenColor string registration number the specified token should be set to
    function setTokenRegNumber(string _tokenVIN, string _newTokenRegNumber) public {
        address owner = ownerOf(_tokenVIN);
        require(owner != address(0));
        require(owner == msg.sender || getApproved(_tokenVIN) == msg.sender);
        tokenRegNumber[_tokenVIN] = _newTokenRegNumber;
    }

   // @dev Safely transfers the ownership of a given token VIN to another address
   // If the target address is a contract, it must implement `onERC721Received`,
   // which is called upon a safe transfer, and return the magic value
   // `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   // the transfer is reverted.
   //
   // Requires the msg sender to be the owner or approved
   // @param _from current owner of the token
   // @param _to address to receive the ownership of the given token VIN
   // @param _tokenVIN string VIN of the token to be transferred
    function safeTransferFrom(address _from, address _to, string _tokenVIN) public {
        safeTransferFrom(_from, _to, _tokenVIN, "");
    }

   // @dev Safely transfers the ownership of a given token VIN to another address
   // If the target address is a contract, it must implement `onERC721Received`,
   // which is called upon a safe transfer, and return the magic value
   // `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   // the transfer is reverted.
   // Requires the msg sender to be the owner or approved
   // @param _from current owner of the token
   // @param _to address to receive the ownership of the given token VIN
   // @param _tokenVIN string VIN of the token to be transferred
   // @param _data bytes data to send along with a safe transfer check
    function safeTransferFrom(address _from, address _to, string _tokenVIN, bytes _data) public {
        transferFrom(_from, _to, _tokenVIN);
        if (isContract(_to)) {
            bytes4 retval = ERC721Reciever(_to).onERC721Received(_from, _to, _tokenVIN, _data);
            require (retval == ERC721_RECEIVED);
        }
    }

   // Returns whether the target address is a contract
   // @dev This function will return false if invoked during the constructor of a contract,
   // as the code is not actually created until after the constructor finishes.
   // @param addr address to check
   // @return whether the target address is a contract
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function getSerializedData(string _tokenVIN) public view returns (bytes) {
        require(ownerOf(_tokenVIN) == msg.sender);
        bytes memory retval;
        uint256 len = bytes(tokenColor[_tokenVIN]).length;
        retval = addToBytes(retval, bytes32(len));
        retval = addToBytes(retval, bytes(tokenColor[_tokenVIN]));
        len = bytes(tokenRegNumber[_tokenVIN]).length;
        retval = addToBytes(retval, bytes32(len));
        retval = addToBytes(retval,  bytes(tokenRegNumber[_tokenVIN]));
        return (retval);
    }

    function recoveryToken(address _owner, string _tokenVIN, bytes _serializedData) public {
        require(msg.sender == allowedToRecover);
        string memory color;
        string memory regNumber;
        (color, regNumber) = deserealizeData(_serializedData);
        if (ownerOf(_tokenVIN) != address(0)) {
            tokenColor[_tokenVIN] = color;
            tokenRegNumber[_tokenVIN] = regNumber;
            safeTransferFrom(msg.sender, _owner, _tokenVIN);
        }
        else {
            produce(_owner, _tokenVIN, color, regNumber);
        }
    }

    function deserealizeData(bytes _serializedData) public pure returns (string, string) {
        uint256 len = getUintFromBytes(_serializedData, 0);
        uint256 offset = 32;
        string memory color = getStringFromBytes(_serializedData, offset, len);
        offset += len;
        len = getUintFromBytes(_serializedData, offset);
        string memory regNumber = getStringFromBytes(_serializedData, 32+offset, len);
        return (color, regNumber);
    }

    function addToBytes(bytes _to, bytes32 _add) internal pure returns (bytes) {
        bytes memory retval = new bytes(_to.length + 32);
        for (uint256 i = 0; i < _to.length; i++) {
            retval[i] = _to[i];
        }
        uint256 offset = _to.length;
        for (i = offset; i < 32+offset; i++) {
            retval[i] = _add[i-offset];
        }
        return retval;
    }

    function addToBytes(bytes _to, bytes _add) internal pure returns (bytes) {
        bytes memory retval = new bytes(_to.length + _add.length);
        for (uint256 i = 0; i < _to.length; i++) {
            retval[i] = _to[i];
        }
        uint256 offset = _to.length;
        for (i = offset; i < _add.length+offset; i++) {
            retval[i] = _add[i-offset];
        }
        return retval;
    }


    function getUintFromBytes(bytes _serializedData, uint256 _offset) internal pure returns (uint256) {
        bytes32 out;
        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(_serializedData[_offset + i] & 0xFF) >> (i * 8);
        }
        return uint256(out);
    }

    function getStringFromBytes(bytes _serializedData, uint256 _offset, uint256 _len) internal pure returns (string) {
        bytes memory out = new bytes(_len);
        for (uint256 i=_offset; i < _offset+_len; i++) {
            out[i-_offset] = _serializedData[i];
        }
        return string(out);
    }

    function setPermissionsToRecover(address _allowed) {
        require(msg.sender == contractOwner);
        allowedToRecover = _allowed;
    }

    function setPermissionsToDemolish(address _allowed) {
        require(msg.sender == contractOwner);
        allowedToDemolish = _allowed;
    }

}