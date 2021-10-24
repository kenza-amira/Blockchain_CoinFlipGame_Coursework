pragma solidity >=0.7.0 <0.9.0;

contract MatchinePennies{
    address payable public player1;
    bytes32 public player1Commitment;

    uint256 public betAmount;

    address public player2;
    Choice public player2Choice;

    uint256 public expiration = 2**256-1;

    enum Choice {HEAD, TAIL}
    
    function player1SendCommitment(bytes32 commitment) public payable {
        require(player1 == address(0));
        require(player2 == address(0));
        betAmount = msg.value;
        player1 = payable(msg.sender);
        player1Commitment = commitment;
    }

    function cancelBet() public {
        require(msg.sender == player1);
        require(player2 == address(0));
        payable(msg.sender).transfer(address(this).balance);
        betAmount = 0;
    }
    
    bytes32 public hash;
    // true, 0000000000000000000000000000000000000000000
    // false, 0000000000000000000000000000000000000000000
    function createHash(bool choice, uint256 nonce) public {
        hash = keccak256(abi.encodePacked(choice, nonce));
    }

    function player2TakeBet(Choice choice) public payable {
        require(player2 == address(0));
        require(player1 != address(0));
        require(msg.value == betAmount);

        player2 = payable(msg.sender);
        player2Choice = choice;
        expiration = block.timestamp + 24 hours;
    }

    function revealChoice(Choice choice, uint256 nonce) public {
        require(player2 != address(0));
        require(block.timestamp < expiration);

        require(keccak256(abi.encodePacked(choice, nonce)) == bytes32(player1Commitment));

        if (player2Choice == choice) {
            payable(player2).transfer(address(this).balance);
        } else {
            player1.transfer(address(this).balance);
        }
    }

    function claim() public {
        require(block.timestamp >= expiration);
        payable(player2).transfer(address(this).balance);
    }
}