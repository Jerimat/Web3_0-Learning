pragma solidity ^0.8.9;

// We'll use this interface to communicate with the Compound
interface cETH{
    // Functions of Compound we'll use
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns(uint256);
    function redeemUnderlying(uint256 redeemTokens) external returns(uint256);

    // Functions to determine how much can be withdrawn
    function exchangeRateStored() external view returns(uint256);
    function balanceOf(address user) external view returns(uint256 balance);
}

// Interface to integrate ERC20 tokens to our Banking System
interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 value) external returns(bool);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
}

// Interface to use the Uniswap exchange
interface UniswapRouter {
    function WETH() external pure returns(address); //returns the canonical WETH address on the main or testnet

    function swapExactETHForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path, //first element must be the WETH address, last element must be the target token address
        address to,
        uint256 deadline
    ) external payable returns(uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns(uint256[] memory amounts);
}

contract SmartBankAccount {
    //@title The SmartBank receives ETH from users, and mint them to Compound to generate interests.
    // Hence, the SmartBank stores cETH for users, but we want users to only interact with ETH.
    // Contract attributes
    uint256 totalContractBalance = 0;

    address COMPOUND_CETH_ADDRESS = 0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);

    address UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    UniswapRouter uniswap = UniswapRouter(UNISWAP_ROUTER_ADDRESS);

    mapping(address => uint256) balances;  // in cETH
    mapping(address => uint256) depositTimestamps;

    // Contract attributes getter/setter
    function getContractBalance() public view returns(uint256) {
        return totalContractBalance;
    }

    //Contract functions
    receive() external payable{}

    function addBalance() public payable{
        _mintToCompound(msg.value);
    }

    function _approveAmountERC20Tokens(address erc20TokenSmartContractAddress) internal returns(uint256) {
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);

        uint256 approvedAmountERC20Tokens = erc20.allowance(msg.sender, address(this));

        // Transfer all the tokens approved from the sender to the smart contract
        erc20.transferFrom(msg.sender, address(this), approvedAmountERC20Tokens);
        // Approve Uniswap to use the ERC20 tokens, now owned by this Smart Contract
        erc20.approve(UNISWAP_ROUTER_ADDRESS, approvedAmountERC20Tokens);

        return approvedAmountERC20Tokens;
    }

    function _mintToCompound(uint256 EthAmount) internal {
        // Deposit ETH to Compound
        uint256 cEthContractBeforeMinting = ceth.balanceOf(address(this));
        // Send ethers to mint
        ceth.mint{value: EthAmount}();

        uint256 cEthContractAfterMinting = ceth.balanceOf(address(this));
        // Compute amount that was created by the mint
        uint256 cEthAmountUser = cEthContractAfterMinting - cEthContractBeforeMinting;

        balances[msg.sender] += cEthAmountUser;
        depositTimestamps[msg.sender] = block.timestamp;
        totalContractBalance += cEthAmountUser;
    }

    function addBalanceERC20(address erc20TokenSmartContractAddress) public payable {
        // Get the smart contract allowance over the user's ERC20 tokens and approve Uniswap to use the ERC20 tokens
        uint256 approvedAmountERC20Tokens = _approveAmountERC20Tokens(erc20TokenSmartContractAddress);

        uint256 amountETHMin = 0;
        address token = erc20TokenSmartContractAddress;
        address to = address(this);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();
        uint256 deadline = block.timestamp + (24 * 60 * 60);

        // Swap ERC20 tokens for ETH
        uint256 EthBeforeSwap = address(this).balance;
        uniswap.swapExactTokensForETH(approvedAmountERC20Tokens, amountETHMin, path, to, deadline);
        uint256 EthSwappedUser = address(this).balance - EthBeforeSwap;

        _mintToCompound(EthSwappedUser);
    }

    // Returns the number of remaining tokens that the contract can spend on behalf of the owner
    function getAllowanceERC20(address erc20TokenSmartContractAddress) public view returns(uint256) {
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        return erc20.allowance(msg.sender, address(this));
    }

    function getBalance(address userAddress) public view returns(uint256) {
        return balances[userAddress] * (ceth.exchangeRateStored() / 1e18);
    }

    function getCethBalance(address userAddress) public view returns(uint256) {
        return balances[userAddress];
    }

    function getExchangeRate() public view returns(uint256) {
        return ceth.exchangeRateStored();
    }

    function withdraw(uint256 EthAmountToWithdraw) public payable {
        require(EthAmountToWithdraw <= getBalance(msg.sender), "You don't have enough balance!");
        address payable transferTo = payable(msg.sender);
        uint256 cEthAmountToWithdraw = EthAmountToWithdraw / (ceth.exchangeRateStored() / 1e18);

        ceth.redeemUnderlying(EthAmountToWithdraw);
        totalContractBalance -= cEthAmountToWithdraw;
        balances[msg.sender] -= cEthAmountToWithdraw;

        transferTo.transfer(EthAmountToWithdraw);
    }

    function withdrawERC20(uint256 ERC20AmountToWithdraw) public payable {

    }

    function withdrawAll() public payable {
        address payable transferTo = payable(msg.sender);
        uint256 EthAmountToWithdraw = getBalance(msg.sender);
        uint256 cEthAmountToWithdraw = balances[msg.sender];

        ceth.redeem(cEthAmountToWithdraw);
        totalContractBalance -= cEthAmountToWithdraw;
        balances[msg.sender] = 0;

        transferTo.transfer(EthAmountToWithdraw);
    }

    function withdrawAllERC20() public payable {

    }

    function addMoneyToContract() public payable {
        totalContractBalance += msg.value;
    }

}
