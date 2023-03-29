// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "./ERC1155D.sol";
import "./SigVerifier.sol";

contract Genesis is ERC1155D, ERC2981, Ownable, SigVerifier {
    using Strings for uint256;

    uint256 private constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 public constant MAX_ID_AIRDROP_PLUS_ONE = 1090;

    uint256[2] private ticketsStorage = [MAX_INT, MAX_INT];

    bool public isActivePublic;
    uint256 public maxIdPlusOne = 447;
    uint256 public price;
    uint256 public amountPlusOne;
    uint256 public currentId = 1;
    uint256 public currentIdAirDrop = 900;

    string public name = "Fragmint Genesis Collection";

    constructor(uint256 _price, string memory uri_) ERC1155D(uri_) SigVerifier(name, "1.0.0") {
        setPrice(_price);
        _setDefaultRoyalty(owner(), 1000);
    }

    function checkTickets() external view returns (uint256[2] memory) {
        return ticketsStorage;
    }

    function mintPresale(bytes memory signature, uint256[] calldata tickets) external payable {
        require(verifySig(signature, tickets), "Invalid signature");
        useTickets(tickets);

        mint(tickets.length);
    }

    function mintPublic(uint256 amount) external payable {
        require(isActivePublic, "Public sale inactive");
        require(amount > 0 && amount < amountPlusOne, "Invalid amount");

        mint(amount);
    }

    function mintAirdrop(address[] calldata winners) external onlyOwner {
        uint256 amount = winners.length;
        uint256 _currentId = currentIdAirDrop;
        require(_currentId + amount - 1 < MAX_ID_AIRDROP_PLUS_ONE, "Limited supply");

        for (uint256 i = 0; i < amount; i++) {
            _mint(winners[i], _currentId + i, 1, "");
        }

        unchecked {
            _currentId += amount;
        }
        currentIdAirDrop = _currentId;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function switchToPublicSaleStage(uint256 newPrice, uint256 maxAmount) external onlyOwner {
        require(currentId == maxIdPlusOne, "Presale still active");
        isActivePublic = true;
        setVerifier(0xaaAaaAAAAAbBbbbbBbBBCCCCcCCCcCdddDDDdddd);
        maxIdPlusOne = 900;
        setMaxAmount(maxAmount);
        setPrice(newPrice);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155D, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(_owners[_id] != address(0), "Nonexistent token");
        return
            bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, _id.toString(), ".json")) : "";
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        require(newPrice > 0, "Invalid price");
        price = newPrice;
    }

    function setMaxAmount(uint256 maxAmount) public onlyOwner {
        require(maxAmount > 0, "Invalid maxAmount");
        amountPlusOne = maxAmount + 1;
    }

    function mint(uint256 amount) private {
        uint256 _currentId = currentId;
        require(_currentId + amount - 1 < maxIdPlusOne, "Limited supply");
        require(msg.value == price * amount, "Insufficient price");
        require(msg.sender == tx.origin, "EOAs only");
        if (amount == 1) {
            _mintSingle(msg.sender, _currentId);
        } else {
            _mintBatchSingle(msg.sender, _currentId, amount);
        }

        unchecked {
            _currentId += amount;
        }
        currentId = _currentId;
    }

    function useTickets(uint256[] memory tickets) private {
        for (uint256 i = 0; i < tickets.length; i++) {
            uint256 ticketNumber = tickets[i];
            require(ticketNumber < 512, "Invalid ticket number"); // 512 - number of bits

            uint256 slotNumber = ticketNumber / 256;
            uint256 slot = ticketsStorage[slotNumber];
            uint256 offset = ticketNumber % 256;
            uint256 bitValue = (slot >> offset) & uint256(1);

            require(bitValue == 1, "Ticket already used");
            ticketsStorage[slotNumber] = slot & ~(uint256(1) << offset);
        }
    }

    /**
     * This is created for gas optimization purposes
     *
     * Before/after transfer hooks are removed - not used
     * ids.length == amounts.length check is removed - arrays are created internally
     * operator is removed - minting is available for EOAs only
     * amounts[i] < 2 check removed - amount is set to 1 in the function
     * _doSafeBatchTransferAcceptanceCheck removed - minting is available for EOAs only
     */
    function _mintBatchSingle(
        address to,
        uint256 _currentId,
        uint256 amount
    ) private {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        uint256 j = 0;
        for (uint256 i = _currentId; i < _currentId + amount; i++) {
            require(_owners[i] == address(0), "ERC1155D: supply exceeded");
            // create the ids and amounts arrays to be used in the TransferBatch event
            ids[j] = i;
            amounts[j++] = 1;

            _owners[i] = to;
        }

        emit TransferBatch(to, address(0), to, ids, amounts);
    }
}
