// SPDX-License-Identifier: MIT
// Carbonable Contracts for Cairo v0.0.1 (carbonable/erc3525/library.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

//
// Events
//

@event
func TransferValue(_fromTokenId: Uint256, _toTokenId: Uint256, _value: Uint256) {
}

@event
func ApprovalValue(_tokenId: Uint256, _operator, _value: Uint256) {
}

@event
func SlotChanged(_tokenId: Uint256, _oldSlot: Uint256, _newSlot: Uint256) {
}

//
// Storage
//

namespace ERC3525 {
}
