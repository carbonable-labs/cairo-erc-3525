// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525Example {
    func valueDecimals() -> (decimals: felt) {
    }

    func balanceOf3525(tokenId: Uint256) -> (balance: Uint256) {
    }

    func slotOf(tokenId: Uint256) -> (slot: Uint256) {
    }

    func approve3525(tokenId: Uint256, operator: felt, value: Uint256) {
    }

    func allowance(tokenId: Uint256, operator: felt) -> (amount: Uint256) {
    }

    func transferFrom3525(fromTokenId: Uint256, toTokenId: Uint256, to: felt, value: Uint256) -> (
        toTokenId: Uint256
    ) {
    }

    func mint(to: felt, slot: Uint256, value: Uint256) -> (token_id: Uint256) {
    }

    func mintValue(tokenId: Uint256, value: Uint256) {
    }

    func burn(tokenId: Uint256) {
    }

    func burnValue(tokenId: Uint256, value: Uint256) {
    }

    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }
}
