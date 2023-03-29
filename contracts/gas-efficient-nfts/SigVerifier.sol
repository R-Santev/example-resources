// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract SigVerifier is EIP712, Ownable {
    bytes32 private constant _PRESALE_TYPEHASH =
        keccak256("Presale(address user,uint256[] tickets)");

    address public verifier;

    constructor(string memory name, string memory version) EIP712(name, version) {
        verifier = 0xaaAaaAAAAAbBbbbbBbBBCCCCcCCCcCdddDDDdddd;
    }

    function setVerifier(address _verifier) public onlyOwner {
        verifier = _verifier;
    }

    function verifySig(bytes memory signature, uint256[] memory tickets)
        internal
        view
        returns (bool)
    {
        bytes32 structHash = keccak256(
            abi.encode(_PRESALE_TYPEHASH, msg.sender, keccak256(abi.encodePacked(tickets)))
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address _verifier = ECDSA.recover(hash, signature);
        if (_verifier == verifier) {
            return true;
        }

        return false;
    }
}
