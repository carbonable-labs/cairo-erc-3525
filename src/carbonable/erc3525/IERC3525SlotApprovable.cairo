// SPDX-License-Identifier: MIT
// Carbonable Contracts for Cairo v0.0.1 (erc3525/IERC3525SlotApprovable.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525SlotEnumerable {
    func setApprovalForSlot(owner, slot: uint256, operator, approved) {
    }

    func isApprovedForSlot(owner, slot: uint256, operator) -> (is_approved,) {
    }
}
