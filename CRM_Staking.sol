// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract CRM_StakingContract is Ownable, IERC721Receiver, ERC721Holder {
    using SafeERC20 for IERC20;
    IERC20 immutable rewardToken;
    IERC721 immutable NFT;

    // uint256 constant DAY_IN_SECONDS = 86400; // 24 hours in seconds
    uint256 constant DAY_IN_SECONDS = 60 seconds;   

  

     struct StakingInfo {
        uint256 dailyReward;
        uint256 accumulatedReward;
        uint256 lastClaimTime;
        bool isStaked;
        bool isHardStaked;
    }


    mapping(string => uint256) public rewardRatios;
    mapping(address => mapping(uint256 => StakingInfo)) public CRM_StakingInfo;

    
    // events
    event SoftStake(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 reward
    );
    event HardStake(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 reward
    );
    event UnlockNFT(
        address indexed owner,
        uint256 indexed tokenId
    );
    event ClaimReward(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 reward
    );
   

    constructor(address _nft, address _token) Ownable(msg.sender) {
        NFT = IERC721(_nft);
        rewardToken = IERC20(_token);
        rewardRatios["The Crazzzy Itzzz"] = 30;
        rewardRatios["The Crazzzy Voorheezzz"] = 30;
        rewardRatios["The Crazzzy Frankiezzz"] = 20;
        rewardRatios["The Crazzzy Dracozzz"] = 20;
        rewardRatios["The Crazzzy Gremlinzzz"] = 20;
        rewardRatios["The Crazzzy Predatorzzz"] = 17;
        rewardRatios["The Crazzzy Walkerzzz"] = 17;
        rewardRatios["The Crazzzy Biohazardzzz"] = 17;
        rewardRatios["The Crazzzy Zeazzz"] = 13;
        rewardRatios["The Crazzzy Terminatorzzz"] = 13;
        rewardRatios["The Crazzzy Werewolvezzz"] = 13;
        rewardRatios["The Crazzzy Crazzzyliens"] = 13;
        rewardRatios["The Crazzzy Screamerzzz"] = 8;
        rewardRatios["The Crazzzy Pinheadzzz"] = 8;
        rewardRatios["The Crazzzy Skeletonzzz"] = 8;
        rewardRatios["The Crazzzy Freddiezzz"] = 8;
        rewardRatios["The Crazzzy Diablozzz"] = 8;
        rewardRatios["The Crazzzy Mummiezzz"] = 4;
        rewardRatios["The Crazzzy Zombiezzz"] = 4;
        rewardRatios["The Crazzzy Pumpkinzzz"] = 4;
    }

 
    function softStake(uint256 _tokenId, string memory _trait) external {
        require(!_isStaked(msg.sender, _tokenId), "NFT is already staked");
        uint256 reward = _calculateSoftStakingReward(_trait);
        uint256 multiplier = _getMultiplier(_tokenId);
        _updateStakingInfo(_tokenId, reward, false);
        emit SoftStake(msg.sender, _tokenId, reward * multiplier);
    }

    function hardStake(uint256 _tokenId, string memory _trait) external {
        require(!_isStaked(msg.sender, _tokenId), "NFT is already staked");
        CRM_StakingInfo[msg.sender][_tokenId].isHardStaked = true;
        uint256 reward = _calculateHardStakingReward(_trait);
        uint256 multiplier = _getMultiplier(_tokenId);
        _updateStakingInfo(_tokenId, reward, true);
        NFT.safeTransferFrom(msg.sender, address(this), _tokenId, "");
        emit HardStake(msg.sender, _tokenId, reward * multiplier);
    }

    function unstakeNFT( uint256 _tokenId) external {
        require( _isStaked(msg.sender, _tokenId), "NFT is not staked");
        if(CRM_StakingInfo[msg.sender][_tokenId].isHardStaked) {
            NFT.safeTransferFrom(address(this), msg.sender, _tokenId, "");
        }
        CRM_StakingInfo[msg.sender][_tokenId].isStaked = false;
        emit UnlockNFT(msg.sender, _tokenId);
    }

    function claimReward(uint256 _tokenId) external {
        StakingInfo storage stakingInfo = CRM_StakingInfo[msg.sender][_tokenId];
        require(_isStaked(msg.sender, _tokenId), "NFT is not staked");
        uint256 interval = block.timestamp - stakingInfo.lastClaimTime;
        require(interval >= 30 seconds, "last claimed time less than 24 hours");
        uint256 reward = _calculateAccumulatedReward(_tokenId);
        stakingInfo.lastClaimTime = block.timestamp;
        stakingInfo.accumulatedReward = 0;  // Set accumulated reward to 0 after claiming
        stakingInfo.dailyReward = reward;
        rewardToken.safeTransfer(msg.sender, reward);
        emit ClaimReward(msg.sender, _tokenId, reward);
    }

    function _isStaked( address _owner,uint256 _tokenId) internal view returns (bool) {
            return CRM_StakingInfo[_owner][_tokenId].isStaked;
    }


    function _calculateSoftStakingReward(string memory _rank) internal view returns (uint256) {
        return getRewardRatio(_rank);
    }

    function _calculateHardStakingReward(string memory _rank ) internal view returns (uint256) {
        return getRewardRatio(_rank) * 3;
    }

    function _calculateAccumulatedReward(uint256 _tokenId) internal view returns (uint256) {
        StakingInfo storage stakingInfo = CRM_StakingInfo[msg.sender][_tokenId];
        uint256 elapsedTime = block.timestamp - stakingInfo.lastClaimTime;
        uint256 dailyReward = (stakingInfo.dailyReward * elapsedTime) / DAY_IN_SECONDS;
        uint256 accumulatedReward = stakingInfo.accumulatedReward + dailyReward;
        return accumulatedReward;
    }

    function _getMultiplier(uint256 _tokenId) internal view returns (uint256) {
         if(CRM_StakingInfo[msg.sender][_tokenId].isHardStaked) {
           return  3;
        }else {
                return 1;
        }
    }

    
    function _updateStakingInfo(uint256 _tokenId,uint256 _reward,bool _hardStaked ) internal {
        CRM_StakingInfo[msg.sender][_tokenId] = StakingInfo({
            dailyReward: _reward,
            accumulatedReward: _reward,
            lastClaimTime: block.timestamp,
            isStaked: true,
            isHardStaked: _hardStaked
        });
    }
    function getRewardRatio(string memory _trait) internal view  returns (uint256) {
       uint256 ratio = rewardRatios[_trait];
        require(ratio != 0, "Reward ratio not defined for the given entity");
        return ratio;
    }
}
