// SPDX-License-Identifier: MIT

%lang starknet

namespace ERC3525MetadataDescriptor {
    func constructContractURI() -> (contractURI: felt) {
        return ('');
    }

    func constructSlotURI(slot: Uint256) -> (slotURI: felt) {
        return (0);
    }

    func constructTokenURI(tokenId: Uint256) -> (tokenURI: felt) {
        return (0);
    }

    func _contractDescription() -> (description: felt) {
        return (0);
    }

    func _contractImage() -> (description: felt) {
        return (0);
    }

    func _slotName(slot: Uint256) -> (description: felt) {
        return (0);
    }

    func _slotDescription(slot: Uint256) -> (string: felt) {
        return (0);
    }

    func _slotImage(slot: Uint256) -> (string: felt) {
        return (0);
    }

    func _slotProperties(slot: Uint256) -> (string: felt) {
        return (0);
    }

    func _tokenName(tokenId: Uint256) -> (string: felt) {
        return (0);
    }

    func _tokenDescription(tokenId: Uint256) -> (string: felt) {
        return (0);
    }

    func _tokenImage(tokenId: Uint256) -> (string: felt) {
        return (0);
    }

    func _tokenProperties(tokenId: Uint256) -> (string: felt) {
        return (0);
    }
}
