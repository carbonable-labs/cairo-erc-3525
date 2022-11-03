// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525SlotEnumerable {
    func setApprovalForSlot(owner: felt, slot: Uint256, operator: felt, approved: felt) {
    }

    func isApprovedForSlot(owner: felt, slot: Uint256, operator: felt) -> (is_approved: felt) {
    }
}
