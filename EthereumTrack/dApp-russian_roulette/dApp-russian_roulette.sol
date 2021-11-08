// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract RussianRoulette {
    
    address payable [2] players;
    uint8 index = 0;
    uint turn = 0;  // indicates whose player turn it is
    uint killed = 0;  // indicates which of the two holes holds the bullet
    bool finished = false;
    
    event GameOver(address loser);
    
    constructor() {
        // Randomly determine which player begins, and which hole has the bullet
        turn = uint(keccak256(abi.encodePacked(block.difficulty, 
                                                block.timestamp, 
                                                block.number,
                                                players))) % 2;
        
        killed = uint(keccak256(abi.encodePacked(players,
                                                block.difficulty, 
                                                block.timestamp, 
                                                block.number))) % 2;
    }
    
    function _resetGame() internal {
        players[0] = players[1] = address(0);
        index = 0;
        finished = true;
    }
    
    function getTurn() public view returns (address) {
        return players[turn];
    }
    
    function isFinished() public view returns (bool) {
        return finished;
    }
    
    function register() public payable {
        require (index < 2);
        require (msg.value >= 0.5 ether);
        
        players[index] = msg.sender;
        index++;
        
        if(index == 2) {finished = false;}
    }
    
    function shoot() public gameNotFinished isSenderTurn {
        uint shot = uint(keccak256(abi.encodePacked(block.difficulty, 
                                                    block.timestamp, 
                                                    players,
                                                    block.number))) % 2;
        
        if(shot == killed) {  // player is killed
            emit GameOver(players[turn]);
            players[ (turn + 1) % 2 ].transfer(address(this).balance);
            _resetGame();
        }
        // player is not killed -> next player's turn
        turn = (turn + 1) % 2;
    }
    
    modifier isSenderTurn() {
        require (msg.sender == players[turn]);
        _;
    }
    
    modifier gameNotFinished() {
        require (finished == false);
        _;
    }
    
}
