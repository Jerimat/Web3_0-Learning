pragma solidity >=0.7.0 <0.9.0;

contract MyErc20 {
    // Smart Contract attributes
    string NAME = "JerianETH";
    string SYMBOL = "JETH";

    uint256 immutable TOTAL_SUPPLY = 10000000 * 1e8;
    uint8 immutable DECIMALS = 8;

    mapping(address => uint256) balances;
    address deployer;
    uint256 totalMinted;

    mapping(uint => bool) blockMined;
    mapping(address => mapping(address => uint256)) allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approve(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        deployer = msg.sender;
        uint256 amountToDeployer = 1000000 * 1e8;
        balances[deployer] = amountToDeployer;

        totalMinted += amountToDeployer;
    }

    // Smart contract functions
    function name() public view returns (string memory){
        return NAME;
    }

    function symbol() public view returns (string memory) {
        return SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function _computeFee(uint256 _value) internal pure returns (uint256) {
        return (_value * 185) / 10000;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        assert(balances[msg.sender] >= _value);  // > instead of >= due to gas fees ?

        uint256 commissionFee = _computeFee(_value);
        uint256 effectiveValue = _value - commissionFee;

        balances[msg.sender] -= effectiveValue;
        balances[_to] += effectiveValue;
        balances[deployer] += commissionFee;

        emit Transfer(msg.sender, _to, _value);

        success = true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value, "The source account does not have enough balance!");
        require(allowances[_from][msg.sender] >= _value);

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        success = true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
    allowances[msg.sender][_spender] = _value;

    emit Approve(msg.sender, _spender, _value);

    success = true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function _getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    function _isMined(uint256 blockNumber) internal view returns (bool) {
        return blockMined[blockNumber];
    }

    function mine() public returns (bool success) {
        if (_isMined(_getBlockNumber())) {  // Reward of this block already mined
            return false;
        }
        if (_getBlockNumber() % 10 != 0) {  // No reward for this Block number
            return false;
        }

        uint256 rewardAmount = 10 * 1e8;
        balances[msg.sender] += rewardAmount;
        totalMinted += rewardAmount;
        blockMined[_getBlockNumber()] = true;

        assert(totalMinted < totalSupply());  // Be sure that the amount minted doesn't go overe the total supply!

        return true;
    }

}
