// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {VestingMerkleTreeVerifier} from "./VestingMerkleTreeVerifier.sol";
import {VestingWithdrawVerifier} from "./VestingWithdrawVerifier.sol";

/// @title Private vesting contract, that distributes
contract PrivateVesting {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    VestingWithdrawVerifier public immutable withdrawalVerifier;
    uint256 public immutable merkleTreeRoot;
    uint256 public immutable vestingStart;

    mapping(address => uint256) public withdrawn;

    event Withdrawal(address user, address receiver, uint256 amount);

    error InvalidRecipient();
    error InvalidMerkleTreeRoot();
    error InvalidWithdrawnAmount();
    error InvalidTimePassed();
    error ZkVerificationFailed();

    /// @param _token ERC20 token that is vested
    /// @param _withdrawalVerifier Verifier contract that will verify withdrawal legitimacy
    /// @param _merkleTreeRoot Merkle tree root value
    constructor(
        IERC20 _token,
        VestingWithdrawVerifier _withdrawalVerifier,
        uint256 _merkleTreeRoot
    ) {
        token = _token;
        withdrawalVerifier = _withdrawalVerifier;
        merkleTreeRoot = _merkleTreeRoot;
        vestingStart = block.timestamp;
    }

    /// @notice Verify withdrawal legitimacy and withdraw funds
    /// @param _pA ZK-proof
    /// @param _pB ZK-proof
    /// @param _pC ZK-proof
    /// @param _pubSignals Public signals [recipient, amount, receivedAmount, root]
    /// @param receiver Tokens receiver
    /// @dev ZK proof of the fact that user is allowed to withdraw tokens is verified
    function withdraw(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[5] calldata _pubSignals,
        address receiver
    ) external {
        uint256 amount = _pubSignals[1];
        uint256 withdrawnAmount = withdrawn[msg.sender];
        {
            uint256 recipient = _pubSignals[0];
            uint256 receivedAmount = _pubSignals[2];
            uint256 timePassed = _pubSignals[3];
            uint256 root = _pubSignals[4];

            if (uint256(uint160(msg.sender)) != recipient) {
                revert InvalidRecipient();
            }
            if (root != merkleTreeRoot) {
                revert InvalidMerkleTreeRoot();
            }
            if (receivedAmount != withdrawnAmount) {
                revert InvalidWithdrawnAmount();
            }
            if (block.timestamp - vestingStart < timePassed) {
                revert InvalidTimePassed();
            }
        }

        withdrawn[msg.sender] = withdrawnAmount + amount;
        if (!withdrawalVerifier.verifyProof(_pA, _pB, _pC, _pubSignals)) {
            revert ZkVerificationFailed();
        }
        token.safeTransfer(receiver, amount);

        emit Withdrawal(msg.sender, receiver, amount);
    }
}

/// @title Factory contract that deploys and funds private vesting contracts
contract PrivateVestingFactory {
    using SafeERC20 for IERC20;

    VestingMerkleTreeVerifier public immutable creationVerifier;
    VestingWithdrawVerifier public immutable withdrawalVerifier;

    event VestingCreated(address);

    error CreationVerificationError();
    error FeeOnTransferTokensNotSupported();

    /// @param _creationVerifier Verifier for Vesting creations
    /// @param _withdrawalVerifier Verifier for Vesting withdrawals
    constructor(
        VestingMerkleTreeVerifier _creationVerifier,
        VestingWithdrawVerifier _withdrawalVerifier
    ){
        creationVerifier = _creationVerifier;
        withdrawalVerifier = _withdrawalVerifier;
    }

    /// @notice Deploy new vesting contract
    /// @param _token ERC20 token address that will be distributed
    /// @param _pA ZK-proof
    /// @param _pB ZK-proof
    /// @param _pC ZK-proof
    /// @param _pubSignals Public signals [merkleTreeRoot, totalAmount]
    /// @dev ZK proof of valid Merkle tree creation is validated before deployment
    ///  This way we can make sure proper Merkle tree root will be used
    function createPrivateVesting(
        IERC20 _token,
        uint[2] memory _pA,
        uint[2][2] memory _pB,
        uint[2] memory _pC,
        uint[2] memory _pubSignals
    ) external {
        uint256 merkleTreeRoot = _pubSignals[0];
        uint256 totalAmount = _pubSignals[1];

        // Verifying that creator has built merkle tree properly
        if (!creationVerifier.verifyProof(_pA, _pB, _pC, _pubSignals)) {
            revert CreationVerificationError();
        }

        PrivateVesting deployedContract = new PrivateVesting(
            _token,
            withdrawalVerifier,
            merkleTreeRoot
        );

        uint256 initialBalance = _token.balanceOf(address(deployedContract));
        _token.safeTransferFrom(msg.sender, address(deployedContract), totalAmount);
        if (_token.balanceOf(address(deployedContract)) - initialBalance < totalAmount) {
            revert FeeOnTransferTokensNotSupported();
        }

        emit VestingCreated(address(deployedContract));
    }
}