// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract SaffronLock_V1 is Initializable, OwnableUpgradeable,ReentrancyGuardUpgradeable {
    IERC721 public nftContract;

    struct Lock {
        uint256 tokenId;
        address owner;
        uint256 checkpoint;
        uint256 start;
        uint256 unlockTime;
        uint256 lockDuration;
    }
    mapping(uint256 => Lock) public locks;
    mapping(address => uint256[]) public userTokenId;
    mapping(address => Lock[]) public userHistory;

    uint256 public minDayLock;
    uint256 public maxDayLock;

    event Locked(uint256 indexed tokenId, address indexed owner,uint256 lockTime, uint256 unlockTime);
    event UnLocked(uint256 indexed tokenId, address indexed owner, uint256 time);
    
    event UpdateLocked(uint256 indexed tokenId, address indexed owner,uint256 o_checkpoint,uint o_start, uint256 o_unlockTime, uint n_start,uint256 n_unlockTime);

    function initialize(address initialOwner,address _nftContract) initializer public {
        __Ownable_init(initialOwner);
        nftContract = IERC721(_nftContract);
        minDayLock=1;
        maxDayLock=4000;
    }

    function lockLiquidity(uint256 _tokenId, uint256 _days) external nonReentrant  {
        require((_days>=minDayLock) && (_days<=maxDayLock),"MinMaxDay");
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not the owner of the NFT");
        require(address(this)==nftContract.getApproved(_tokenId),"Not Approved");
        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        require(locks[_tokenId].start == 0, "NFT is already locked");
        uint256 lockDuration = _days * 1 days;
        uint256 unlockTime = block.timestamp + lockDuration;
        locks[_tokenId] = Lock(_tokenId, msg.sender,0,block.timestamp,unlockTime,lockDuration);
        userTokenId[msg.sender].push(_tokenId);
        emit Locked(_tokenId, msg.sender, block.timestamp,unlockTime);
    }

    function unlockLiquidity(uint256 _tokenId) external nonReentrant {
        require(locks[_tokenId].checkpoint <= 0,"Fund alredy withdrawal");
        require(block.timestamp >= locks[_tokenId].unlockTime, "Unlock time has not arrived");
        require(locks[_tokenId].owner == msg.sender,"Caller is Not Owner");
        locks[_tokenId].checkpoint = block.timestamp;
        nftContract.safeTransferFrom(address(this), msg.sender, _tokenId);
        userHistory[msg.sender].push(locks[_tokenId]);
        emit UnLocked(_tokenId, msg.sender, block.timestamp);
    }

    function updateLockLiquidity(uint256 _tokenId, uint256 _days) external nonReentrant {
        require((_days>=minDayLock) && (_days<=minDayLock),"MinMaxDay");
        Lock storage oUL=locks[_tokenId];
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not the owner of the NFT");
        require(address(this)==nftContract.getApproved(_tokenId),"Not Approved");
        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        require(locks[_tokenId].checkpoint != 0, "Liquidity not Claimed");        

        uint256 lockDuration = _days * 1 days;
        uint256 unlockTime = block.timestamp + lockDuration;
        locks[_tokenId] = Lock(_tokenId, msg.sender,0,block.timestamp,unlockTime,lockDuration);
        emit UpdateLocked(_tokenId, msg.sender, oUL.checkpoint,oUL.start, oUL.unlockTime, block.timestamp, unlockTime);
    }

    function getUserTokenLength(address _user) public view returns(uint256)
    {
        return userTokenId[_user].length;
    }

     function getUserHistoryLength(address _user) public view returns(uint256)
    {
        return userHistory[_user].length;
    }

    function updateMinDay(uint256 _days) public onlyOwner
    {
        require(_days >=1,"Day not Valid");
        minDayLock=_days;
    }

    function updateManDay(uint256 _days) public onlyOwner
    {
        require(_days >=1,"Day not Valid");
        maxDayLock=_days;
    }

}