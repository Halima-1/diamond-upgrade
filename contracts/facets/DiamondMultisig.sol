// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibAppStorage, AppStorage, UpgradeProposal} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

contract DiamondMultisigFacet {
    event UpgradeProposed(uint256 indexed proposalId, address indexed proposer);
    event UpgradeApproved(uint256 indexed proposalId, address indexed signer);
    event UpgradeExecuted(uint256 indexed proposalId);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event QuorumUpdated(uint256 newQuorum);

    error NOT_A_SIGNER();
    error REQUIRED_EXCEED_SIGNERS();
    error ALREADY_INITIALIZED();
    error ADDRESS_ZERO_DETECTED();
    error ALREADY_EXECUTED();
    error ALREADY_VOTED();
    error ALREADY_A_SIGNER();
    error NOT_ENOUGH_APPROVALS();
    error UNAUTHORIZED_GOVERNANCE();

    modifier onlySigner() {
        if (!LibAppStorage.appStorage().isSigner[msg.sender]) {
            revert NOT_A_SIGNER();
        }
        _;
    }

 
    modifier onlyDuringUpgrade() {
        if (!LibAppStorage.appStorage().isExecutingUpgrade) {
            revert UNAUTHORIZED_GOVERNANCE();
        }
        _;
    }

    function initializeGov(address[] memory _signers, uint256 _required) external {
        AppStorage storage s = LibAppStorage.appStorage();
        if (s.signers.length > 0) revert ALREADY_INITIALIZED();
        if (_required > _signers.length) revert REQUIRED_EXCEED_SIGNERS();

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            if (signer == address(0)) revert ADDRESS_ZERO_DETECTED();
            if (s.isSigner[signer]) revert ALREADY_A_SIGNER();
            
            s.isSigner[signer] = true;
            s.signers.push(signer);
        }
        s.requiredQuorum = _required;
    }

    function proposeUpgrade(
        IDiamondCut.FacetCut[] memory _cuts,
        address _init,
        bytes memory _calldata
    ) external onlySigner returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 proposalId = s.proposalCount++;
        
        UpgradeProposal storage p = s.proposals[proposalId];
        for (uint i = 0; i < _cuts.length; i++) {
            p.cuts.push(_cuts[i]);
        }
        p.init = _init;
        p.calldata_ = _calldata;
        p.approvals = 1;
        p.hasVoted[msg.sender] = true;

        emit UpgradeProposed(proposalId, msg.sender);
        return proposalId;
    }

    function approveUpgrade(uint256 _proposalId) external onlySigner {
        AppStorage storage s = LibAppStorage.appStorage();
        UpgradeProposal storage p = s.proposals[_proposalId];
        
        if (p.executed) revert ALREADY_EXECUTED();
        if (p.hasVoted[msg.sender]) revert ALREADY_VOTED();

        p.hasVoted[msg.sender] = true;
        p.approvals++;

        emit UpgradeApproved(_proposalId, msg.sender);

        if (p.approvals >= s.requiredQuorum) {
            _executeUpgrade(_proposalId);
        }
    }

    function _executeUpgrade(uint256 _proposalId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        UpgradeProposal storage p = s.proposals[_proposalId];
        
        if (p.approvals < s.requiredQuorum) revert NOT_ENOUGH_APPROVALS();
        
        p.executed = true;
        
        // --- SECURITY LOCK ---
        s.isExecutingUpgrade = true; // Unlock the door
        LibDiamond.diamondCut(p.cuts, p.init, p.calldata_);
        s.isExecutingUpgrade = false; // Relock the door
        // ---------------------
        
        emit UpgradeExecuted(_proposalId);
    }

    // function addValidSigner(address _signer) external onlyDuringUpgrade {
    //     AppStorage storage s = LibAppStorage.appStorage();
    //     if (_signer == address(0)) revert ADDRESS_ZERO_DETECTED();
    //     if (s.isSigner[_signer]) revert ALREADY_A_SIGNER();

    //     s.isSigner[_signer] = true;
    //     s.signers.push(_signer);
    //     emit SignerAdded(_signer);
    // }

    // function removeValidSigner(address _signer) external onlyDuringUpgrade {
    //     AppStorage storage s = LibAppStorage.appStorage();
    //     if (!s.isSigner[_signer]) revert NOT_A_SIGNER();

    //     s.isSigner[_signer] = false;
        
    //     for (uint i = 0; i < s.signers.length; i++) {
    //         if (s.signers[i] == _signer) {
    //             s.signers[i] = s.signers[s.signers.length - 1];
    //             s.signers.pop();
    //             break;
    //         }
    //     }
        
    //     if (s.requiredQuorum > s.signers.length) {
    //         s.requiredQuorum = s.signers.length;
    //     }

    //     emit SignerRemoved(_signer);
    // }

    function updateQuorum(uint256 _newQuorum) external onlyDuringUpgrade {
        AppStorage storage s = LibAppStorage.appStorage();
        if (_newQuorum == 0 || _newQuorum > s.signers.length) revert REQUIRED_EXCEED_SIGNERS();
        
        s.requiredQuorum = _newQuorum;
        emit QuorumUpdated(_newQuorum);
    }

    function getSigners() external view returns (address[] memory) {
        return LibAppStorage.appStorage().signers;
    }

    function getProposalStatus(uint256 _id) external view returns (
        uint256 approvals, 
        bool executed,
        address init
    ) {
        UpgradeProposal storage p = LibAppStorage.appStorage().proposals[_id];
        return (p.approvals, p.executed, p.init);
    }
}
