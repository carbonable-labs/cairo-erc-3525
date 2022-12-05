// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525SlotEnumerable {
    func slotCount() -> (count: Uint256) {
    }

    func slotByIndex(index: Uint256) -> (slot: Uint256) {
    }

    func tokenSupplyInSlot(slot: Uint256) -> (supply: Uint256) {
    }

    func tokenInSlotByIndex(slot: Uint256, index: Uint256) -> (tokenId: Uint256) {
    }
}
