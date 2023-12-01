// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract HunterZ_staking_contract is Ownable, IERC721Receiver, ERC721Holder {
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

    mapping(uint256 => uint256) public rewardRatios;
    mapping(address => mapping(uint256 => StakingInfo)) public HunterZ_StakingInfo;

    
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
    }
    



    function softStake(uint256 _tokenId, uint256 _rank) external {
        require(!_isStaked(msg.sender, _tokenId), "NFT is already staked");
        uint256 reward = _calculateSoftStakingReward(_rank);
        uint256 multiplier = _getMultiplier(_tokenId);
        _updateStakingInfo(_tokenId, reward, false);
        emit SoftStake(msg.sender, _tokenId, reward * multiplier);
    }

      function hardStake(uint256 _tokenId, uint256 _rank) external {
        require(!_isStaked(msg.sender, _tokenId), "NFT is already staked");
        HunterZ_StakingInfo[msg.sender][_tokenId].isHardStaked = true;
        uint256 reward = _calculateHardStakingReward(_rank);
        uint256 multiplier = _getMultiplier(_tokenId);
        _updateStakingInfo(_tokenId, reward, true);
        NFT.safeTransferFrom(msg.sender, address(this), _tokenId, "");
        emit HardStake(msg.sender, _tokenId, reward * multiplier);
    }

    function unstakeNFT( uint256 _tokenId) external {
        require( _isStaked(msg.sender, _tokenId), "NFT is not staked");
        if(HunterZ_StakingInfo[msg.sender][_tokenId].isHardStaked) {
            NFT.safeTransferFrom(address(this), msg.sender, _tokenId, "");
        }
        HunterZ_StakingInfo[msg.sender][_tokenId].isStaked = false;
        emit UnlockNFT(msg.sender, _tokenId);
    }

    function claimReward(uint256 _tokenId) external {
        StakingInfo storage stakingInfo = HunterZ_StakingInfo[msg.sender][_tokenId];
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
   

    function _isStaked(
        address _owner,
        uint256 _tokenId
    ) internal view returns (bool) {
        return HunterZ_StakingInfo[_owner][_tokenId].isStaked;
    }

    function _calculateSoftStakingReward(
        uint256 _rank
    ) internal pure returns (uint256) {
        require(_rank >= 1 && _rank <= 10000, "Invalid rank");
        return getRewardRatio(_rank);
    }

    function _calculateHardStakingReward(
        uint256 _rank
    ) internal pure returns (uint256) {
        require(_rank >= 1 && _rank <= 10000, "Invalid rank");
        return getRewardRatio(_rank) * 3;
    }

    function _calculateAccumulatedReward(uint256 _tokenId) internal view returns (uint256) {
        StakingInfo storage stakingInfo = HunterZ_StakingInfo[msg.sender][_tokenId];
        uint256 elapsedTime = block.timestamp - stakingInfo.lastClaimTime;
        uint256 dailyReward = (stakingInfo.dailyReward * elapsedTime) / DAY_IN_SECONDS;
        uint256 accumulatedReward = stakingInfo.accumulatedReward + dailyReward;
        return accumulatedReward;
    }

    function _getMultiplier(
        uint256 _tokenId
    ) public view returns (uint256) {
         if(HunterZ_StakingInfo[msg.sender][_tokenId].isHardStaked) {
           return  3;
        }else {
                return 1;
        }
    }

    function _updateStakingInfo(
        uint256 _tokenId,
        uint256 _reward,
        bool _hardStaked
    ) internal {
        HunterZ_StakingInfo[msg.sender][_tokenId] = StakingInfo({
            dailyReward: _reward,
            accumulatedReward: _reward,
            lastClaimTime: block.timestamp,
            isStaked: true,
            isHardStaked: _hardStaked
        });
    }

    function getRewardRatio(uint256 rank) public  pure  returns (uint256) {
         if (rank >= 2200 && rank <= 3000) {
            return 10;
        } else if (rank >= 1500 && rank <= 2199) {
            return 15;
        } else if (rank >= 1000 && rank <= 1499) {
            return 20;
        } else if (rank >= 500 && rank <= 999) {
            return 25;
        } else if (rank >= 150 && rank <= 499) {
            return 30;
        } else if (rank >= 31 && rank <= 149) {
            return 40;
        } else if (rank >= 1 && rank <= 30) {
         return 50;
        } else {
            revert("Invalid rank");
        }
    }


} 
