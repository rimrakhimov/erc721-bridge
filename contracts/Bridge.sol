pragma solidity ^0.4.24;

contract ERC721 {
    function getSerializedData(string _tokenId) public returns (bytes);

    function demolishToken(string _tokenVIN) public;

    function recoveryToken(address _owner, string _tokenVIN, bytes _serializedData) public;
}


contract BasicBridge {
    /// This emits when any NFT token was transferred to bridge contract.
    event UserRequestForSignature(address _from, string _tokenVIN, bytes _data);

    /// This emits when any NFT token was returned to its owner.
    event TransferCompleted(string _tokenVIN);

    // Contract of token the bridge is working with
    ERC721 ERC721Contract;

    // Number of approvals required for transferring NFT between networks
    uint256 requiredSignatures;

    // Array of accounts which are allowed to transfer NFT between networks
    address[] authorities;

    // Mapping from signature requests to number of their approvals
    mapping (bytes32 => uint256) internal totalApproved;

    // Mapping from signature requests to their status
    mapping (bytes32 => bool) internal transferCompleted;

    // Mapping from signature request and address of authority to boolean
    // value showing whether this authority already approved the request
    mapping (bytes32 => bool) internal authorityApproved;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    // Send request to recover NFT in a network. Must be called by authority.
    // Call 'recoveryToken' if number of collected signatures for specified NFT
    // is equal to required number of signatures. Otherwise add one more signature.
    // Reverts if msg.sender is not an authority
    // Reverts if specified NFT has already been recovered
    // Reverts if specified NFT has already been approved by msg.sender
    // @param _owner address of owner specified NFT should be recovered to
    // @param _tokenVIN string VIN of recovered NFT
    // @param _serializedData bytes of serialized metadata of NFT
    // @param _txHash bytes32 hash of transaction NFT was asked to signature in
    function transferApproved(address _owner, string _tokenVIN, bytes _serializedData, bytes32 _txHash) public {
        require(transferCompleted[_txHash] == false);
        require(isAuthority(msg.sender));
        require(authorityApproved[keccak256(msg.sender, _txHash)] == false);
        totalApproved[_txHash] += 1;
        authorityApproved[keccak256(msg.sender, _txHash)] = true;
        if (totalApproved[_txHash] == requiredSignatures) {
            transferCompleted[_txHash] = true;
            ERC721Contract.recoveryToken(_owner, _tokenVIN, _serializedData);
            emit TransferCompleted(_tokenVIN);
        }
    }

    // Internal funciton to check whether specified address is an authority
    // @param _authority address need to be checked
    // @return whether specified address is an authority
    function isAuthority(address _authority) internal view returns (bool) {
        for (uint256 i = 0; i < authorities.length; i++) {
            if (_authority == authorities[i]) {
                return true;
            }
        }
        return false;
    }
}

contract ForeignBridge is BasicBridge {
    constructor(address _contract, uint256 _requiredSignatures, address[] _authorities) public {
        require(_contract != address(0));
        require(_requiredSignatures <= _authorities.length);
        require(_requiredSignatures > 0);
        ERC721Contract = ERC721(_contract);
        authorities = _authorities;
        requiredSignatures = _requiredSignatures;
    }

    // Function which is called by safeTransferFrom.
    // Get serialized data and emit UserRequestForSignature event.
    // @param _from address of account which transferred an NFT
    // @param _owner address of account which owns specified NFT
    // @param _tokenVIN string identificator of NFT
    // @param _data bytes of additional data
    // @return constant ERC721_RECEIVED value
    function onERC721Received(
        address _from,
        address _owner,
        string _tokenVIN,
        bytes _data
    ) public returns(bytes4) {
        bytes memory data = ERC721(msg.sender).getSerializedData(_tokenVIN);
        emit UserRequestForSignature(_from, _tokenVIN, data);
        ERC721(msg.sender).demolishToken(_tokenVIN);
        return ERC721_RECEIVED;
    }
}

contract HomeBridge is BasicBridge {
    constructor(address _contract, uint256 _requiredSignatures, address[] _authorities) public {
        require(_contract != address(0));
        require(_requiredSignatures <= _authorities.length);
        require(_requiredSignatures > 0);
        ERC721Contract = ERC721(_contract);
        authorities = _authorities;
        requiredSignatures = _requiredSignatures;
    }

    // Function which is called by safeTransferFrom.
    // Get serialized data and emit UserRequestForSignature event.
    // @param _from address of account which transferred an NFT
    // @param _owner address of account which owns specified NFT
    // @param _tokenVIN string identificator of NFT
    // @param _data bytes of additional data
    // @return constant ERC721_RECEIVED value
    function onERC721Received(
        address _from,
        address _owner,
        string _tokenVIN,
        bytes _data
    ) public returns(bytes4) {
        bytes memory data = ERC721(msg.sender).getSerializedData(_tokenVIN);
        emit UserRequestForSignature(_from, _tokenVIN, data);
        return ERC721_RECEIVED;
    }
}