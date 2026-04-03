// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibAppStorage, AppStorage, UpgradeProposal} from "../libraries/LibAppStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

contract DiamondMultisigFacet {
    event UpgradeProposed(uint256 indexed proposalId, address indexed proposer);
    event UpgradeApproved(uint256 indexed proposalId, address indexed signer);
    event UpgradeExecuted(uint256 indexed proposalId);

    error NOT_A_SIGNER();
    error REQUIRED_EXCEED_SIGNERS();
    error ALREADY_INITIALIZED();
    error ADDRESS_ZERO_DETECTED();
    error ALREADY_EXECUTED();
    error ALREADY_VOTED();
    error ALREADY_A_SIGNER();
    error NOT_ENOUGH_APPROVALS();

    modifier onlySigner() {
        if (!LibAppStorage.appStorage().isSigner[msg.sender]) {
            revert NOT_A_SIGNER();
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
        address _setupAddress,
        bytes memory _calldata
    ) external onlySigner returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 proposalId = s.proposalCount++;
        
        UpgradeProposal storage p = s.proposals[proposalId];
        for (uint i = 0; i < _cuts.length; i++) {
            p.cuts.push(_cuts[i]);
        }
        p._setupAddress = _setupAddress;
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
        
        LibDiamond.diamondCut(p.cuts, p._setupAddress, p.calldata_);
        
        emit UpgradeExecuted(_proposalId);
    }

    function getSigners() external view returns (address[] memory) {
        return LibAppStorage.appStorage().signers;
    }

    function getProposalStatus(uint256 _id) external view returns (
        uint256 approvals, 
        bool executed,
        address _setupAddress
    ) {
        UpgradeProposal storage p = LibAppStorage.appStorage().proposals[_id];
        return (p.approvals, p.executed, p._setupAddress);
    }
}
