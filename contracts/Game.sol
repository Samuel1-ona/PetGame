// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Istaking.sol";
import "./Encryption.sol";


contract GameContract is EncryptionContract {


    error Error__NotPlayed();
    error Error__AlreadyPlayed();

    IERC20 public immutable s_stakingToken;
    uint256 public immutable REWARD_AMOUNT;
    uint256 public immutable REWARD_PERCENTAGE;
    Istaking public immutable s_stakingContract;

    event GameStarted(
        address player,
        uint256 startTime,
        bytes32[5] codedWordArray
    );
    event PlayedGame(
        address indexed player,
        bool indexed isWon,
        uint256 indexed _amountWon
    );

    constructor(
        uint256 _rewardPercent,
        uint256 _rewardAmount,
        address _stakingToken,
        address _stakingContract,
        bytes32 _secretKey
    ) EncryptionContract(_secretKey) {

        REWARD_PERCENTAGE = _rewardPercent;

        REWARD_AMOUNT = _rewardAmount;

        s_stakingToken = IERC20(_stakingToken);

        s_stakingContract = Istaking(_stakingContract);
    }

    //mapping that stores winners
    address[] private winners;

    //mapping that stores users encryptedword
    mapping(address => bytes32[5]) private userToCodedPetArray;

    //mapping that maps users time of play
    mapping(address => uint256) timeOfPlay;

    function startGame(bytes32[5] memory _codedWordArray) public {

        //update user's word
        userToCodedPetArray[msg.sender] = _codedWordArray;

        //update user time
        timeOfPlay[msg.sender] = block.timestamp;

        emit GameStarted(msg.sender, block.timestamp, _codedWordArray);
    }

    function playedGame( bytes32[5] memory _encryptedWordArray, string[5] memory _wordArray ) external  {

        if (block.timestamp == 0) {
            revert Error__NotPlayed();
        }
        if (block.timestamp >= timeOfPlay[msg.sender] + 1 days) {
            revert Error__AlreadyPlayed();
        }
        uint userStake = s_stakingContract.getStaked(msg.sender);

        uint _payAmount = (REWARD_PERCENTAGE * userStake) / 100;
        
        s_stakingToken.transfer(msg.sender, _payAmount);

        bool isWon = isCorrect(_encryptedWordArray, _wordArray);
        //check if won
        if (isWon) {
            winners.push(msg.sender);
            s_stakingToken.transfer(msg.sender, REWARD_AMOUNT);
        }
        emit PlayedGame(msg.sender, isWon, _payAmount + REWARD_AMOUNT);
    }

    function fetchWinners() external  view returns (address[] memory) {
        return winners;
    }

    function fetchPlayerInfo()external  view returns (bytes32[5] memory, uint256) {

        return (userToCodedPetArray[msg.sender], timeOfPlay[msg.sender]);
    }
}