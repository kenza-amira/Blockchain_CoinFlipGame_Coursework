pragma solidity >=0.7.0 <0.9.0;

contract MatchingPennies{
    address payable public player1;
    bytes32 public player1Commitment;

    // Making betAmount 1 ether
    uint256 public betAmount = 1000000000000000000;

    address public player2;
    bool public player2Choice;

    uint256 public expiration = 2**256-1;
   
    event Commit(address player);
    event Bet(address player);
    event Reveal(address player, bool choice);
    event Payout(address player, uint amount);
    
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
        payable(msg.sender).transfer(address(this).balance);
    }
    
    bytes32 public hash;
    // true, 0000000000000000000000000000000000000000000
    // false, 0000000000000000000000000000000000000000000
    function createHash(bool choice, uint256 nonce) public {
        hash = keccak256(abi.encodePacked(choice, nonce));
        
    }

    function player2TakeBet(bool choice) public payable {
        require(player2 == address(0));
        require(player1 != address(0));
        require(msg.value == betAmount);

        player2 = payable(msg.sender);
        player2Choice = choice;
        expiration = block.timestamp + 24 hours;
        emit Bet(player2);
    }

    function revealChoice(bool choice, uint256 nonce) public {
        require(player2 != address(0));
        require(block.timestamp < expiration);

        require(keccak256(abi.encodePacked(choice, nonce)) == bytes32(player1Commitment));

        if (player2Choice == choice) {
            payable(player2).transfer(address(this).balance);
            emit Payout(player2, betAmount*2);
        } else {
            player1.transfer(address(this).balance);
            emit Payout(player1, betAmount*2);
        }
        emit Reveal(player1, choice);
        
        // Reinitialising values
        player1 = payable(address(0));
        player2 = payable(address(0));
        player1Commitment = bytes32(0);
        player2Choice = bool(false);
        expiration = 2**256-1;
    }

    function claimReward() public {
        require(block.timestamp >= expiration);
        payable(player2).transfer(address(this).balance);
        emit Payout(player2, betAmount*2);
    }
}