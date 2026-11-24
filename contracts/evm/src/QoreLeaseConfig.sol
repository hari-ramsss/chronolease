// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title QoreLeaseConfig
/// @notice Deployment/authorization configuration kept strictly separate from
///         QoreLeaseEscrow product logic.
/// @dev These values are deployment inputs, not protocol rules:
///      - `bridgeAddress` defaults to the documented Diana precompile 0x0901 and is
///        only overridden by local mock deployments. Diana live behaviour
///        (empty responses, allowlist, code pin) is a separate gate.
///      - `nativeRegistryAddress` is the `qor1...` address passed as the bridge
///        `targetContract` string.
///      - `escrowNativeIdentity` is the mapped Native identity of this EVM contract.
///        The Native registry authorizes `info.sender`, never a JSON payload field,
///        so this value is documentation/config for operators, not an on-chain proof.
contract QoreLeaseConfig {
    error NotAdmin();
    error ZeroAddress();

    address public admin;
    address public bridgeAddress;
    string public nativeRegistryAddress;
    /// qor1... identity mapped to this EVM contract (G0-C unverified until Diana test).
    string public escrowNativeIdentity;
    /// Native penalty recipient, recorded for operator reconciliation only.
    string public nativePenaltyRecipient;

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(address admin_) {
        if (admin_ == address(0)) revert ZeroAddress();
        admin = admin_;
    }

    function setBridgeAddress(address bridge) external onlyAdmin {
        if (bridge == address(0)) revert ZeroAddress();
        bridgeAddress = bridge;
    }

    function setNativeRegistry(string calldata registry) external onlyAdmin {
        nativeRegistryAddress = registry;
    }

    function setEscrowNativeIdentity(string calldata identity) external onlyAdmin {
        escrowNativeIdentity = identity;
    }

    function setNativePenaltyRecipient(string calldata recipient) external onlyAdmin {
        nativePenaltyRecipient = recipient;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        admin = newAdmin;
    }
}

/// @title QoreLeaseMonitorRoles
/// @notice Monitor authorization for evidence submission, kept separate from escrow logic.
abstract contract QoreLeaseMonitorRoles {
    error UnknownMonitor(address monitor);

    mapping(address => bool) public authorizedMonitor;

    function _authorizeMonitor(address monitor, bool allowed) internal virtual;

    modifier onlyAuthorizedMonitor() {
        if (!authorizedMonitor[msg.sender]) revert UnknownMonitor(msg.sender);
        _;
    }
}