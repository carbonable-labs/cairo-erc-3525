// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_le

from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.utils.constants.library import UINT8_MAX

//
// Events
//

@event
func TransferValue(fromTokenId: Uint256, toTokenId: Uint256, value: Uint256) {
}

@event
func ApprovalValue(tokenId: Uint256, operator: felt, value: Uint256) {
}

@event
func SlotChanged(tokenId: Uint256, oldSlot: Uint256, newSlot: Uint256) {
}

//
// Storage
//
@storage_var
func ERC3525_value_decimals() -> (decimals: felt) {
}

namespace ERC3525 {
    //
    // Constructor
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        name: felt, symbol: felt, decimals: felt
    ) {
        ERC721.initializer(name, symbol);
        with_attr error_message("ERC3525: decimals exceed 2^8") {
            assert_le(decimals, UINT8_MAX);
        }
        ERC3525_value_decimals.write(decimals);
        return ();
    }
}
