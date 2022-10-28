// SPDX-License-Identifier: MIT
// Carbonable Contracts for Cairo v0.0.1 (erc3525/IERC3525SlotEnumerable.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525SlotEnumerable {
    func slotCount() -> (count: felt) {
    }

    func slotbyIndex(index) -> (slot: uint256) {
    }

    func tokenSupplyInSlot(slot: Uint256) -> (supply: Uint256) {
    }

    func tokenInSlotByIndex(slot: uint256, index) -> (token_id: Uint256) {
    }
}
