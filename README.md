# COP 5615 - Project 4.1
Program to implement a simple bitcoin protocol. This program transacts bitcoins between participants, mines a block and adds the block to a blockchain.

## Team members
  - Anand Chinnappan Mani,  UFID: 7399-9125
  - Utkarsh Roy,            UFID: 9109-6657

## What is working

 - The program creates a node for each participant that consists of a private-key, public-key pair, public-key Base58 encoded hash and unspent output transactions(UTXO). 

 - A new node, bitcoind, is created. This node creates the genesis block and adds it to the blockchain. It also mediates between participants and miners. 
 
 - Once a participant sends a given amount of satoshis to the the other participant, a transaction is added to the transactions list in bitcoind.

 - The miner node keeps polling the bitcoind for the transaction list every 5 seconds. If it receives a non-empty transaction list, it'll recursively create a merkle root by hashing and pairing the transaction hashes in the transaction list.

 - The miner will then mine a block using a target threshold, which is 3 leading zeros in our case. It'll send the new block to be added to the blockchain to bitcoind.

 - The miner adds the new block to the blockchain and verifies the entire blockchain from the latest to the oldest transaction

 - The new block is broadcasted using an unsolicited-push to each participant

## Bonus

- The bitcoind node verifies the blockchain every time a new block is added to the blockchain, in case a malignant block has been added to the blockchain.

- The verifying method recursively iterates through every block in the blockchain until the genesis block and checks if the prev_hash field of the current block is equal to the hash of the previous block's hash,


 ## Test cases

 - BLOCK HASH TEST - Check whether each block hash has leading zeros equal to the target(3) after mining

 - BLOCKCHAIN VERIFICATION TEST - Check whether a blockchain is verified correctly if the prev_hash of each block is equal to the hash of the current hash.

 - ADDRESS VERIFICATION TEST - Check if the same address is constructed with identical private-key, public-key pair
 
 - TRANSACTION HASH - Computes hash of a transaction from tx_in and tx_out
 
 - WALLET BALANCE UPDATE - Obtain utxo from a new transaction added to the blockchain

## Implementation

 - We create two nodes A and B.
 - The genesis block pays A with 100 satoshis.
 - We are simulating transfer of money (value to be specified as input argument) from A to B.
 - A transaction is created by A, sending 'value' to B and change, '100 - value' back to itself.
 - This transaction is picked up by the miner and a block is mined.
 - The length of the blockchain increases by 1 as shown. 
 - The wallet balances of nodes A and B are also adjusted

 ## Instructions

Move to project working directory

Run Project
```
  mix deps.get
  iex -S mix
  SimpleBitcoin.start <value>
```

Sample Input 1:
```
  SimpleBitcoin.start 20
```
Sample Output 1:
![N|Solid](https://i.imgur.com/hh6a7Xy.png)
![N|Solid](https://i.imgur.com/NxnCAFX.png)
![N|Solid](https://i.imgur.com/21YYYeL.png)
![N|Solid](https://i.imgur.com/J5cHnwg.png)

```
NOTE:
 Notice increase of block_height from 0 to 1
 Also notice that the wallet balance of A went from 100 to 80  and that of B from 0 to 20
```
Sample Input 2:
```
  SimpleBitcoin.start 120
```

Sample Output 2:
```
.
.
.
Insufficient Balance
```

```NOTE: Please wait 5 seconds for whole output to be generated```

Run test cases
```
  mix test
```

Test output
```
.....

Finished in 0.3 seconds
5 tests, 0 failures
```
