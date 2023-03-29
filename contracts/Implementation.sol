// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";

contract NFT is ERC721Upgradeable, ERC721RoyaltyUpgradeable {
    using Counters for Counters.Counter;
    using StringsUpgradeable for uint256;

    uint8 public constant VERSION = 0;

    string private baseURI;
    uint256 private _supply;
    Counters.Counter private _tokenIdCounter;

    bool public isBurnable;
    address public creator;
    uint256 public artId = 0;

    event NewBaseURI(string baseURI);

    constructor() initializer {}

    function initialize(
        address creator_
    ) public initializer {
        __ERC721_init(name_, symbol_);
    }

    function burnFragmentsToUnlockArt() public {
        require(isBurnable == true, "Burn is disabled");
        require(
            balanceOf(msg.sender) == _supply && _supply > 1,
            "Caller doesn't own the full collection"
        );

        uint256 oldSupply = _supply;
        _supply = 1;

        for (uint256 id = 1; id < oldSupply; id++) {
            _burn(id);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
