// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.7.0 <0.9.0;

contract MatchingPennies{
    address payable private player1;
    bytes32 private player1Commitment;

    // Making betAmount 1 ether
    uint256 public betAmount = 1 ether;

    
    address payable private player2;
    bool private player2Choice;
    bool private canClaim = false;

    uint256 private expiration = 2**256-1;
    mapping(address => uint256) balance;

    
    event Commit(address player);
    event Bet(address player);
    event Reveal(address player, bool choice);
    event Withdrawal(address player, uint amount);
    
    function player1SendCommitment(bytes32 commitment) public payable {
        require(player1 == address(0));
        require(player2 == address(0));
        require(msg.value == betAmount);
        player1 = payable(msg.sender);
        player1Commitment = commitment;
        emit Commit(player1);
    }

    function cancelBet() public {
        require(msg.sender == player1);
        require(player2 == address(0));
        balance[msg.sender] += address(this).balance;
        player1 = payable(address(0));
    }
    
    // true, 0000000000000000000000000000000000000000000
    // false, 0000000000000000000000000000000000000000000
    function createHash(bool choice, uint256 nonce) public pure returns (bytes32 commitment){
        return keccak256(abi.encodePacked(choice, nonce));
        
    }

    function player2TakeBet(bool choice) public payable {
        require(player2 == address(0));
        require(player1 != address(0));
        require(msg.value == betAmount);

        player2 = payable(msg.sender);
        player2Choice = choice;
        expiration = block.timestamp + 10 minutes;
        canClaim = true;
        emit Bet(player2);
    }

    function revealChoice(bool choice, uint256 nonce) public {
        require(player2 != address(0));
        require(block.timestamp < expiration);

        require(keccak256(abi.encodePacked(choice, nonce)) == bytes32(player1Commitment));

        if (player2Choice != choice) {
            balance[msg.sender] += address(this).balance;
        } else {
            balance[msg.sender] += address(this).balance;
        }
        emit Reveal(player1, choice);
        
        // Reinitialising values
        player1 = payable(address(0));
        player2 = payable(address(0));
        player1Commitment = bytes32(0);
        player2Choice = bool(false);
        expiration = 2**256-1;
    }

    function claimTimeout() public {
        require(block.timestamp >= expiration);
        require(canClaim == true);
        balance[player2] = address(this).balance;
        emit Withdrawal(player2, betAmount*2);
        
        // Reinitialising values
        player1 = payable(address(0));
        player2 = payable(address(0));
        player1Commitment = bytes32(0);
        player2Choice = bool(false);
        expiration = 2**256-1;
    }
    
    function withdraw() public{
        uint256 b = balance[msg.sender];
        balance[msg.sender] = 0;
        payable(msg.sender).transfer(b);

        emit Withdrawal(msg.sender, b);
    }
    
    function showbalance() public view returns (uint256 amount){
        return balance[msg.sender];
    }
}