// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.bool import FALSE, TRUE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_eq

from starkware.starknet.common.syscalls import get_caller_address

// OpenZeppelin dependencies
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.safemath.library import SafeUint256

// Project dependencies
from carbonable.erc3525.library import assert_erc3525, SlotChanged, ERC3525
from carbonable.erc3525.utils.constants.library import IERC3525_SLOT_ENUMERABLE_ID

//
// Storage
//

@storage_var
func ERC3525SlotEnumerable_all_slots_len() -> (count: Uint256) {
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
    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        ERC165.register_interface(IERC3525_SLOT_ENUMERABLE_ID);
        return ();
    }

    //
    // Externals
    //

    // Convention: zero index is invalid, enumeration starts at 1

    func slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        count: Uint256
    ) {
        let (count) = ERC3525SlotEnumerable_all_slots_len.read();
        return (count=count);
    }

    func slot_by_index{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        index: Uint256
    ) -> (slot: Uint256) {
        assert_erc3525.uint256(index);

        let (count) = ERC3525SlotEnumerable_all_slots_len.read();

        let (is_le) = uint256_le(index, count);
        with_attr error_message("ERC3525SlotEnumerable: index out of bounds") {
            assert 1 = is_le;
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

        let (supply) = token_supply_in_slot(slot);

        let (is_le) = uint256_le(index, supply);
        with_attr error_message("ERC3525SlotEnumerable: slot token index out of bounds") {
            assert 1 = is_le;
        }

        let (token_id) = ERC3525SlotEnumerable_slot_tokens.read(slot, index);
        return (token_id=token_id);
    }

    func transfer_from{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_token_id: Uint256, to_token_id: Uint256, to: felt, value: Uint256
    ) -> (to_token_id: Uint256) {
        alloc_locals;

        assert_erc3525.uint256(from_token_id);
        assert_erc3525.uint256(to_token_id);
        assert_erc3525.uint256(value);
        assert_erc3525.token_id_not_zero(from_token_id);

        let (caller) = get_caller_address();
        with_attr error_message("ERC3525SlotEnumerable: caller is the zero address") {
            assert_not_zero(caller);
        }

        // Disambiguate function call:
        // only one of `to_token_id` and `̀to` must be set

        local to_set = is_not_zero(to);
        let (token_id_not_set) = uint256_eq(to_token_id, Uint256(0, 0));
        let arg_set = to_set + 1 - token_id_not_set;

        with_attr error_message(
                "ERC3525SlotEnumerable: cannot transfer token zero or to zero address") {
            if (arg_set == 0) {
                assert 0 = 1;
            }
        }

        // Disambiguation consistency check
        with_attr error_message("ERC3525SlotEnumerable: cannot set both token_id and to") {
            assert 1 = arg_set;
        }

        if (to_set == TRUE) {
            // Use overriden method
            return transfer_from_to(from_token_id, to, value);
        } else {
            // token_id_set == TRUE
            return ERC3525.transfer_from_token_id(from_token_id, to_token_id, value);
        }
    }

    func transfer_from_to{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_token_id: Uint256, to: felt, value: Uint256
    ) -> (to_token_id: Uint256) {
        alloc_locals;
        let (local new_token_id) = ERC3525.transfer_from_to(from_token_id, to, value);
        let (slot) = ERC3525.slot_of(from_token_id);
        _add_token_to_slot_enumeration(slot, new_token_id);
        return (to_token_id=new_token_id);
    }

    func _mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt, token_id: Uint256, slot: Uint256, value: Uint256
    ) {
        ERC3525._mint(to, token_id, slot, value);
        _add_token_to_slot_enumeration(slot, token_id);

        let (is_slot) = _slot_exists(slot);
        if (is_slot == 0) {
            _create_slot(slot);
            return ();
        }

        return ();
    }

    func _mint_new{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt, slot: Uint256, value: Uint256
    ) -> (token_id: Uint256) {
        alloc_locals;
        let (local token_id) = ERC3525._mint_new(to, slot, value);
        _add_token_to_slot_enumeration(slot, token_id);
        let (is_slot) = _slot_exists(slot);
        if (is_slot == 0) {
            _create_slot(slot);
            return (token_id=token_id);
        }

        return (token_id=token_id);
    }

    func _burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: Uint256) {
        let (slot) = ERC3525.slot_of(token_id);
        _remove_token_from_slot_enumeration(slot, token_id);
        ERC3525._burn(token_id);

        return ();
    }

    //
    // Internals
    //

    func _slot_exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        slot: Uint256
    ) -> (exists: felt) {
        alloc_locals;
        let zero = Uint256(0, 0);
        let (local index) = ERC3525SlotEnumerable_all_slots_index.read(slot);
        let (is_index_zero) = uint256_eq(zero, index);
        return (exists=1 - is_index_zero);
    }

    func _token_exists_in_slot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        slot: Uint256, token_id: Uint256
    ) -> (exists: felt) {
        alloc_locals;
        let zero = Uint256(0, 0);
        let (local index) = ERC3525SlotEnumerable_slot_tokens_index.read(slot, token_id);
        let (is_index_zero) = uint256_eq(zero, index);
        return (exists=1 - is_index_zero);
    }

    func _create_slot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        slot: Uint256
    ) {
        let (exists) = _slot_exists(slot);
        with_attr error_message("ERC3525SlotEnumerable: slot already exists") {
            assert 0 = exists;
        }
        _add_slot_to_all_slots_enumeration(slot);
        SlotChanged.emit(Uint256(0, 0), Uint256(0, 0), slot);
        return ();
    }

    func _before_value_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_: felt,
        to: felt,
        from_token_id: Uint256,
        to_token_id: Uint256,
        slot: Uint256,
        value: Uint256,
    ) {
        let zero = Uint256(0, 0);
        let (is_not_from_zero_addr) = is_not_zero(from_);
        let (is_zero_id) = uint256_eq(zero, from_token_id);
        let (is_slot) = _slot_exists(slot);

        // mint
        if (is_not_from_zero_addr == 0 and is_zero_id == 1 and is_slot == 0) {
            _create_slot(slot);
        }
        return ();
    }

    func _after_value_transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_: felt,
        to: felt,
        from_token_id: Uint256,
        to_token_id: Uint256,
        slot: Uint256,
        value: Uint256,
    ) {
        let zero = Uint256(0, 0);
        let (is_not_from_zero_addr) = is_not_zero(from_);
        let (is_not_to_zero_addr) = is_not_zero(to);
        let (is_from_zero_id) = uint256_eq(zero, from_token_id);
        let (is_to_zero_id) = uint256_eq(zero, from_token_id);
        let (is_from_token_in_slot) = _token_exists_in_slot(slot, from_token_id);
        let (is_to_token_in_slot) = _token_exists_in_slot(slot, to_token_id);
        let (is_slot) = _slot_exists(slot);

        // mint
        if (is_not_from_zero_addr == 0 and is_from_zero_id == 1 and is_to_token_in_slot == 0) {
            _add_token_to_slot_enumeration(slot, to_token_id);
            return ();
        }

        // burn
        if (is_not_to_zero_addr == 0 and is_to_zero_id == 1 and is_to_token_in_slot == 1) {
            _remove_token_from_slot_enumeration(slot, to_token_id);
            return ();
        }
        return ();
    }
}

//
// Private
//

func _add_slot_to_all_slots_enumeration{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(slot: Uint256) {
    alloc_locals;
    let (count) = ERC3525SlotEnumerable_all_slots_len.read();
    let (local new_count) = SafeUint256.add(Uint256(1, 0), count);
    ERC3525SlotEnumerable_all_slots_len.write(new_count);
    ERC3525SlotEnumerable_all_slots.write(new_count, slot);
    ERC3525SlotEnumerable_all_slots_index.write(slot, new_count);
    return ();
}

func _add_token_to_slot_enumeration{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(slot: Uint256, token_id: Uint256) {
    alloc_locals;
    let (supply) = ERC3525SlotEnumerable_slot_tokens_len.read(slot);
    let (local new_supply) = SafeUint256.add(Uint256(1, 0), supply);
    ERC3525SlotEnumerable_slot_tokens_len.write(slot, new_supply);
    ERC3525SlotEnumerable_slot_tokens.write(slot, new_supply, token_id);
    ERC3525SlotEnumerable_slot_tokens_index.write(slot, token_id, new_supply);
    return ();
}

func _remove_token_from_slot_enumeration{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(slot: Uint256, token_id: Uint256) {
    alloc_locals;
    let (local last_index) = ERC3525SlotEnumerable_slot_tokens_len.read(slot);
    let (local last_token_id) = ERC3525SlotEnumerable_slot_tokens.read(slot, last_index);
    let (local token_index) = ERC3525SlotEnumerable_slot_tokens_index.read(slot, token_id);
    let (new_supply) = SafeUint256.sub_le(last_index, Uint256(1, 0));
    ERC3525SlotEnumerable_slot_tokens_len.write(slot, new_supply);

    // overwrite token with last token
    ERC3525SlotEnumerable_slot_tokens.write(slot, token_index, last_token_id);
    ERC3525SlotEnumerable_slot_tokens_index.write(slot, last_token_id, token_index);
    // Remove last token index
    ERC3525SlotEnumerable_slot_tokens.write(slot, last_index, Uint256(0, 0));
    // Remove token_id index
    ERC3525SlotEnumerable_slot_tokens_index.write(slot, token_id, Uint256(0, 0));
    return ();
}
