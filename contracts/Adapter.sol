//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
//https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-01#factory
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';


contract Adapter{

    enum Status{
        ACTIVE,
        INACTIVE
    }

    struct PairToken{
        address tokenA;
        address tokenB;
    }

    struct Liquidity{
        uint amountA;
        uint amountB;
        uint liquidityTokens;
        Status status;
    }
    
    address public factory;
    IUniswapV2Router02 public router;

    constructor(address factory_, address router_) public {
        factory = factory_;
        router = IUniswapV2Router02(router_);
    }

    mapping (address => PairToken) public pairToken;
    mapping (address => Liquidity) public liquidity;

    uint amountAMin = 1;
    uint amountBMin = 1;
    uint deadline = 1;
    uint amountOutMin = 1;

    function createPair(address tokenA_, address tokenB_) public {
        require(tokenA_ != address(0) || tokenB_ != address(0), "Adapter: Address token don't be equal null");
        address pair =  IUniswapV2Factory(factory).createPair(tokenA_, tokenB_);
        pairToken[pair] = PairToken({tokenA: tokenA_, tokenB: tokenB_});
    }
    
    function addLiquidity(address pairTokens, uint amountADesired_, uint amountBDesired_, address to_ ) public {
        require(to_ != address(0), "Adapter: Address 'to' don't be equal null");
        require(pairTokens != address(0), "Adapter: Address 'pairTokens' don't be equal null");
        require(amountADesired_ > 0 || amountBDesired_ > 0, "Adapter: amountADesired_ need be more");
        require(liquidity[pairTokens].status != ACTIVE, "Adapter: Liquidity already created");
        (uint amountA_, uint amountB_, uint liquidity_) = router.addLiquidity(
        pairToken[pairTokens].tokenA,
        pairToken[pairTokens].tokenB,
        amountADesired_,
        amountBDesired_,
        amountAMin,
        amountBMin,
        to_,
        deadline);

        liquidity[pairTokens] = Liquidity({amountA: amountA_, amountB: amountB_, liquidityTokens: liquidity_, status: Status.ACTIVE});
    }

    function deleteLiquidity(address pairTokens, address to_) public {
        require(to_ != address(0), "Adapter: Address 'to' don't be equal null");
        require(pairTokens != address(0), "Adapter: Address 'pairTokens' don't be equal null");
        require(liquidity[pairTokens].status == ACTIVE, "Adapter: Liquidity is inactive");
        (uint amountA_, uint amountB_) =  router.removeLiquidity(
        pairToken[pairTokens].tokenA,
        pairToken[pairTokens].tokenB,
        liquidity[pairTokens].liquidityTokens,
        amountAMin,
        amountBMin,
        to_,
        deadline);

        liquidity[pairTokens] = Liquidity({amountA: amountA_, amountB: amountB_, liquidityTokens: 0, status: Status.INACTIVE});
    }

    function getPrice(address addressPair) public returns(uint){
        require(addressPair != address(0), "Adapter: Address 'addressPair' don't be equal null");
        return addressPair.balance;
    }
    

    function swapPairForPath(address pairTokens, address to_, uint amountIn) public {
        require(to_ != address(0), "Adapter: Address 'to' don't be equal null");
        require(pairTokens != address(0), "Adapter: Address 'pairTokens' don't be equal null");
        address[] memory path = new address[](2);
        path[0] = pairToken[pairTokens].tokenA;
        path[1] = pairToken[pairTokens].tokenB;
        router.swapExactTokensForETH(amountIn, amountOutMin, path, to_, deadline);
    }

    /*
    function swapPair() public{
        swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    }
    */
}