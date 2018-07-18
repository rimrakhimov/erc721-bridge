pragma solidity ^0.4.24;

contract ERC721 {
    function getSerializedData(string _tokenId) public returns (bytes);

    function demolishToken(string _tokenVIN) public;

    function recoveryToken(address _owner, string _tokenVIN, bytes _serializedData) public;
}


contract BasicBridge {
    event UserRequestForSignature(address _from, string _tokenVIN, bytes _data);

    event TransferCompleted(string _tokenVIN);

    ERC721 ERC721Contract;

    uint256 requiredSignatures;
    address[] authorities;

    mapping (bytes32 => uint256) internal totalApproved;
    mapping (bytes32 => bool) internal transferCompleted;
    mapping (bytes32 => bool) internal authorityApproved;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

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