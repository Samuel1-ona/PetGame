// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./Encryption.sol";

contract VRF is VRFConsumerBaseV2 {

     uint256 private constant ROLL_IN_PROGRESS = 30;

    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    // address vrfCoordinator;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 s_keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 40,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 40000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 5;

    // For this example, retrieve 1 random value in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    // map rollers to requestIds
    mapping(uint256 => address) private s_rollers;
    // map vrf results to rollers
    mapping(address => uint256) private s_results;
    //map users address to request time
    mapping(address => uint256) private s_lastRequestTime;

    event DiceRolled(uint256 indexed requestId, address indexed roller);
    event DiceLanded(uint256 indexed requestId, uint256 indexed result);

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @dev NETWORK: specify upon deployment
     *
     * @param subscriptionId subscription id that this consumer contract can use
     */
    constructor(
        uint64 subscriptionId,  address vrfCoordinator,   bytes32 _keyHash) VRFConsumerBaseV2(vrfCoordinator) {

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

        s_subscriptionId = subscriptionId;

        s_keyHash = _keyHash;
    }

    /**
     * @notice Requests randomness
     * @dev Warning: if the VRF response is delayed, avoid calling requestRandomness repeatedly
     * as that would give miners/VRF operators latitude about which VRF response arrives first.
     * @dev You must review your implementation details with extreme care.
     *
     * @param roller address of the roller
     */
    function rollDice(address roller) public returns (uint256 requestId) {
        require(
            block.timestamp >= s_lastRequestTime[roller] + 1 days,
            "Can only request once per day"
        );
        require(s_results[roller] == 0, "Already rolled");
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        s_rollers[requestId] = roller;
        s_results[roller] = ROLL_IN_PROGRESS;
        s_lastRequestTime[roller] = block.timestamp;

        emit DiceRolled(requestId, roller);
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number to this contract.
     *
     * @dev Some action on the contract state should be taken here, like storing the result.
     * @dev WARNING: take care to avoid having multiple VRF requests in flight if their order of arrival would result
     * in contract states with different outcomes. Otherwise miners or the VRF operator would could take advantage
     * by controlling the order.
     * @dev The VRF Coordinator will only send this function verified responses, and the parent VRFConsumerBaseV2
     * contract ensures that this method only receives randomness from the designated VRFCoordinator.
     *
     * @param requestId uint256
     * @param randomWords  uint256[] The random result returned by the oracle.
     */
    function fulfillRandomWords(uint256 requestId,   uint256[] memory randomWords ) internal override {

        uint256 d20Value = (randomWords[0] % 10) + 1;

        s_results[s_rollers[requestId]] = d20Value;

        emit DiceLanded(requestId, d20Value);
    }

    /**
     * @notice Get the word assigned to the player once the address has rolled
     * @param player address
     * @return word as a string
     */
 function word(address player) public view returns (string memory) {
    require(s_results[player] != 0, "Dice not rolled");
    require(s_results[player] != ROLL_IN_PROGRESS, "Roll in progress");

    string memory userWord = getWord(s_results[player]);

    return userWord;
}


      function getWord(uint256 id) private   pure returns (string memory) {
        string[10] memory words = [
               "Dog",
              "Rabbit",
               "Parrot",
               "Hamster",
              "Guinea Pig",
                 "Turtle",
                  "Fish",
                 "Ferret",
                   "Snake",
                   "Lizard"
        ];
          return words[id - 1];
    }
}
