# Bridge for ERC721 token
The goal of these contracts and scripts is to 
allow users to transfer non fungible tokens(NFT) 
between two ethereum networks.

# Deployment steps
## Home Deployment (Sokol)
1. Deploy [ERC721 Token](https://github.com/rimrakhimov/erc721-bridge/blob/master/contracts/ERC721.sol)
    (Example address: '0xa51120080cd19c6dd35a1154e3fdaa770555f746') 
    that will be used as Home ERC721 contract
2. Deploy [Bridge Contract](https://github.com/rimrakhimov/erc721-bridge/blob/master/contracts/Bridge.sol)
    (Example address: '0xba1ecd4b35953cc578f773580e6aecd3128e5775') 
    that will be used as Home Bridge contract.
    To deploy use the address of ERC721 contract which was deployed on step 1 
    as the first parameter.
    The second parameter is number of signatures required to transfer NFT
    from one network to another. 
    The third one is an array with addresses of all authorities who can transfer NFT

## Foreign Deployment (Kovan)
1. Deploy [ERC721 Token](https://github.com/rimrakhimov/erc721-bridge/blob/master/contracts/ERC721.sol)
    (Example address: '0xa51120080cd19c6dd35a1154e3fdaa770555f746') 
    that will be used as Foreign ERC721 contract
2. Deploy [Bridge Contract](https://github.com/rimrakhimov/erc721-bridge/blob/master/contracts/Bridge.sol)
    (Example address: '0xba1ecd4b35953cc578f773580e6aecd3128e5775') 
    that will be used as Foreign Bridge contract.
    To deploy use the address of ERC721 contract which was deployed on step 1 
    as the first parameter.
    The second parameter is number of signatures required to transfer NFT
    from one network to another. 
    The third one is an array with addresses of all authorities who can transfer NFT
    
# Running bridge
1. Write down your private key in [privateKey.json](https://github.com/rimrakhimov/erc721-bridge/blob/master/validator/privateKey.json)
    (Example private key: '0x48656c6c6f2c20776f726c6448656c6c6f2c20776f726c6448656c6c6f2c2048').
    The address corresponded to specified private key should be listed as authority in bridge contracts
2. Write down addresses of Home and Foreign Bridges in file [contracts.json](https://github.com/rimrakhimov/erc721-bridge/blob/master/validator/contracts.json)
3. Run [bridge.py](https://github.com/rimrakhimov/erc721-bridge/blob/master/validator/bridge.py) that will be the main script of the bridge
