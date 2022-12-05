// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_lt, uint256_eq

from carbonable.erc3525.library import assert_erc3525

//
// Storage
//

@storage_var
func ERC3525SlotEnumerable_all_slot_len() -> (count: Uint256) {
}

@storage_var
func ERC3525SlotEnumerable_all_slots(index: Uint256) -> (slot: Uint256) {
}

@storage_var
func ERC3525SlotEnumerable_all_slots_index(slot: Uint256) -> (index: Uint256) {
}

@storage_var
func ERC3525SlotEnumerable_slot_tokens_len(slot: Uint256) -> (supply: Uint256) {
}

@storage_var
func ERC3525SlotEnumerable_slot_tokens(slot: Uint256, index: Uint256) -> (token_id: Uint256) {
}

@storage_var
func ERC3525SlotEnumerable_slot_tokens_index(slot: Uint256, token_id: Uint256) -> (index: Uint256) {
}

namespace ERC3525SlotEnumerable {
    func slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        count: Uint256
    ) {
        let (count) = ERC3525SlotEnumerable_all_slot_len.read();
        return (count=count);
    }

    func slot_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: Uint256
    ) -> (slot: Uint256) {
        assert_erc3525.uint256(index);

        let (count) = ERC3525SlotEnumerable_all_slot_len.read();
        let (is_lt) = uint256_lt(index, count);
        with_attr error_message("ERC3525SlotEnumerable: index out of bounds") {
            assert 1 = is_lt;
        }

        let (slot) = ERC3525SlotEnumerable_all_slots.read(index);
        return (slot=slot);
    }

    func token_supply_in_slot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        slot: Uint256
    ) -> (supply: Uint256) {
        assert_erc3525.uint256(slot);

        let (exists) = _slot_exists(slot);
        if (exists == FALSE) {
            return (supply=Uint256(0, 0));
        } else {
            let (supply) = ERC3525SlotEnumerable_slot_tokens_len.read(slot);
            return (supply=supply);
        }
    }

    func token_in_slot_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        slot: Uint256, index: Uint256
    ) -> (token_id: Uint256) {
        assert_erc3525.uint256(slot);
        assert_erc3525.uint256(index);

        return (token_id=Uint256(0, 0));
    }

    // Internal

    func _slot_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        slot: Uint256
    ) -> (exists: felt) {
        alloc_locals;
        let zero = Uint256(0, 0);
        let (local index) = ERC3525SlotEnumerable_all_slots_index.read(slot);
        let (is_index_zero) = uint256_eq(zero, index);
        return (exists=1 - is_index_zero);
    }
}
