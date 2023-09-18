pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface Errors {
    error AddressNotAllowed();
    error CallerNotAllowed();
    error AlreadyInitialized();

    error AmountUnmatch();
    error AmountZero();
    error AmountNotZero();

    error NotFactoryAdmin();
    error NotNetworkAdmin();

    error FailedToTransfer();
    error FailedToCall();

    error SubmitBalancesDisable();
    error BlockNotMatch();
    error RateChangeOverLimit();

    error InvalidThreshold();
    error VoterNumberOverLimit();
    error VotersNotEnough();
    error ProposalAlreadyExecuted();
    error AlreadyVoted();

    error WithdrawIndexEmpty();
    error NotClaimable();
    error AlreadyClaimed();
    error InvalidMerkleProof();
    error ClaimableRewardZero();
    error ClaimableDepositZero();
    error ClaimableAmountZero();
    error AlreadyDealedHeight();
    error WithdrawIndexOver();
    error BalanceNotEnough();
    error LengthNotMatch();
    error CycleNotMatch();
    error AlreadyNotifyCycle();
    error AlreadyDealedEpoch();
    error LsdTokenAmountZero();
    error EthAmountZero();
    error ReachCycleWithdrawLimit();
    error ReachUserWithdrawLimit();

    error PubkeyNotExist();
    error PubkeyAlreadyExist();
    error PubkeyStatusUnmatch();
    error NodeAlreadyExist();
    error NotTrustNode();
    error NodeAlreadyRemoved();
    error TrustNodeDepositDisabled();
    error LightNodeDepositDisabled();
    error ReachPubkeyNumberLimit();
    error NotPubkeyOwner();

    error UserDepositDisabled();
    error DepositAmountLTMinAmount();
}