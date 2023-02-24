The purpose of this smart contract is to allow the contract owner to deposit Binance Smart Chain's native cryptocurrency, BNB, to the contract, which will then automatically scan PancakeSwap for new pairs where the contract has been verified on Binance Smart Chain's explorer, BscScan. Once it identifies a new pair, the contract will automatically buy a predefined amount of tokens using the deposited BNB. The smart contract will then sell 33% of the tokens back to BNB when the token's price reaches 3x its initial buy price. The owner can also choose to sweep any remaining BNB and tokens back to their wallet at any time.

The contract includes the following functions:

depositBNB() - allows the contract owner to deposit BNB into the contract.

buyTokens(address _token) - scans PancakeSwap for a new pair where the contract has been verified and buys the predefined amount of tokens with the deposited BNB.

sellTokens(address _token) - sells 33% of the tokens back to BNB when the token's price reaches 3x its initial buy price.

withdraw(address _token, uint256 _amount) - allows the contract owner to withdraw any remaining BNB or tokens from the contract to their wallet.

The contract also includes the following modifiers:

onlyOwner() - restricts certain functions to the contract owner.

notBlacklisted(address _token) - prevents the contract from interacting with certain blacklisted tokens.
