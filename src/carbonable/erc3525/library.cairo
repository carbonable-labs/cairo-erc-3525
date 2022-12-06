// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn_le, assert_not_zero, assert_not_equal
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_not, uint256_eq
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.introspection.erc165.IERC165 import IERC165
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.security.safemath.library import SafeUint256

from carbonable.erc3525.IERC3525Receiver import IERC3525Receiver
from carbonable.erc3525.utils.constants.library import (
    UINT8_MAX,
    IERC3525_ID,
    IERC3525_METADATA_ID,
    IERC3525_RECEIVER_ID,
    IACCOUNT_ID,
)

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

@storage_var
func ERC3525_values(token_id: Uint256) -> (value: Uint256) {
}

@storage_var
func ERC3525_approved_values(owner: felt, token_id: Uint256, operator: felt) -> (
    allowance: Uint256
) {
}

@storage_var
func ERC3525_slots(token_id: Uint256) -> (slot: Uint256) {
}

@storage_var
func ERC3525_slot_uri(slot: Uint256) -> (uri: felt) {
}

@storage_var
func ERC3525_contract_uri() -> (uri: felt) {
}

@storage_var
func ERC3525_total_minted_() -> (count: Uint256) {
}

namespace ERC3525 {
    //
    // Constructor
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        decimals: felt
    ) {
        with_attr error_message("ERC3525: decimals exceed 2^8") {
            assert_nn_le(decimals, UINT8_MAX);
        }
        ERC3525_value_decimals.write(decimals);
        ERC165.register_interface(IERC3525_ID);
        ERC165.register_interface(IERC3525_METADATA_ID);

        return ();
    }

    func value_decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        decimals: felt
    ) {
        return ERC3525_value_decimals.read();
    }

    func balance_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256
    ) -> (balance: Uint256) {
        assert_erc3525.uint256(token_id);
        assert_erc3525.minted(token_id);

        let (balance: Uint256) = ERC3525_values.read(token_id);
        return (balance=balance);
    }

    func slot_of{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256
    ) -> (slot: Uint256) {
        assert_erc3525.uint256(token_id);
        assert_erc3525.minted(token_id);

        return ERC3525_slots.read(token_id);
    }

    func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, to: felt, value: Uint256
    ) {
        assert_erc3525.uint256(token_id);
        assert_erc3525.uint256(value);

        with_attr error_message("ERC3525: cannot approve to the zero address") {
            assert_not_zero(to);
        }

        let (caller) = get_caller_address();
        with_attr error_message("ERC3525: cannot approve from the zero address") {
            assert_not_zero(caller);
        }

        let (owner) = ERC721.owner_of(token_id);
        with_attr error_message("ERC3525: approval to current owner") {
            assert_not_equal(owner, to);
        }

        let is_approved = ERC721._is_approved_or_owner(caller, token_id);
        with_attr error_message("ERC3525: approve caller is not owner nor approved") {
            assert_not_zero(is_approved);
        }
        _approve_value(token_id, to, value);
        return ();
    }

    func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, operator: felt
    ) -> (amount: Uint256) {
        assert_erc3525.uint256(token_id);
        let (owner) = ERC721.owner_of(token_id);
        let (value: Uint256) = ERC3525_approved_values.read(owner, token_id, operator);
        return (amount=value);
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
        with_attr error_message("ERC3525: caller is the zero address") {
            assert_not_zero(caller);
        }

        // Disambiguate function call:
        // only one of `to_token_id` and `̀to` must be set

        local to_set = is_not_zero(to);
        let (token_id_not_set) = uint256_eq(to_token_id, Uint256(0, 0));
        let arg_set = to_set + 1 - token_id_not_set;

        with_attr error_message("ERC3525: cannot transfer token zero or to zero address") {
            if (arg_set == 0) {
                assert 0 = 1;
            }
        }

        // Disambiguation consistency check
        with_attr error_message("ERC3525: cannot set both token_id and to") {
            assert 1 = arg_set;
        }

        if (to_set == TRUE) {
            return transfer_from_to(from_token_id, to, value);
        } else {
            // token_id_set == TRUE
            return transfer_from_token_id(from_token_id, to_token_id, value);
        }
    }

    func transfer_from_to{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_token_id: Uint256, to: felt, value: Uint256
    ) -> (to_token_id: Uint256) {
        alloc_locals;
        let (caller) = get_caller_address();
        _spend_allowance(caller, from_token_id, value);

        let (local new_token_id) = _get_new_token_id();
        let (slot) = slot_of(from_token_id);
        _mint(to, new_token_id, slot, Uint256(0, 0));
        _transfer_value(from_token_id, new_token_id, value);

        return (to_token_id=new_token_id);
    }

    func transfer_from_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_token_id: Uint256, to_token_id: Uint256, value: Uint256
    ) -> (to_token_id: Uint256) {
        let (caller) = get_caller_address();
        _spend_allowance(caller, from_token_id, value);
        _transfer_value(from_token_id, to_token_id, value);

        return (to_token_id=to_token_id);
    }

    func contract_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        uri: felt
    ) {
        return ERC3525_contract_uri.read();
    }

    func slot_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        slot: Uint256
    ) -> (uri: felt) {
        return ERC3525_slot_uri.read(slot);
    }

    //
    // Internal
    //

    func _approve_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, to: felt, value: Uint256
    ) {
        let (owner) = ERC721.owner_of(token_id);
        ERC3525_approved_values.write(owner, token_id, to, value);
        ApprovalValue.emit(token_id, to, value);
        return ();
    }

    func _spend_allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        spender: felt, token_id: Uint256, amount: Uint256
    ) {
        alloc_locals;
        let (owner) = ERC721.owner_of(token_id);
        let (current_allowance) = ERC3525_approved_values.read(owner, token_id, spender);
        let (infinity: Uint256) = uint256_not(Uint256(0, 0));
        let (is_infinite: felt) = uint256_eq(current_allowance, infinity);

        let is_approved = ERC721._is_approved_or_owner(spender, token_id);

        if (is_infinite == FALSE and is_approved == FALSE) {
            with_attr error_message("ERC3525: insufficient allowance") {
                let (new_allowance: Uint256) = SafeUint256.sub_le(current_allowance, amount);
            }
            _approve_value(token_id, spender, new_allowance);
            return ();
        }
        return ();
    }

    func _mint_new{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt, slot: Uint256, value: Uint256
    ) -> (token_id: Uint256) {
        alloc_locals;
        let (local token_id) = _get_new_token_id();
        _mint(to, token_id, slot, value);
        return (token_id=token_id);
    }

    func _mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt, token_id: Uint256, slot: Uint256, value: Uint256
    ) {
        assert_erc3525.uint256(token_id);

        let exists = ERC721._exists(token_id);
        with_attr error_message("ERC3525: token_id already exists") {
            assert FALSE = exists;
        }

        with_attr error_message("ERC3525: mint to the zero address") {
            assert_not_zero(to);
        }

        assert_erc3525.token_id_not_zero(token_id);

        __mint_token(to, token_id, slot);
        __mint_value(token_id, value);
        return ();
    }

    func __mint_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt, token_id: Uint256, slot: Uint256
    ) {
        let (total) = ERC3525_total_minted_.read();
        let (new_total) = SafeUint256.add(total, Uint256(1, 0));
        ERC3525_total_minted_.write(new_total);

        ERC721Enumerable._mint(to, token_id);
        ERC3525_slots.write(token_id, slot);
        SlotChanged.emit(token_id, Uint256(0, 0), slot);
        return ();
    }

    func _mint_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, value: Uint256
    ) {
        assert_erc3525.uint256(value);
        assert_erc3525.uint256(token_id);
        assert_erc3525.minted(token_id);
        __mint_value(token_id, value);
        return ();
    }

    func __mint_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, value: Uint256
    ) {
        let (balance) = ERC3525_values.read(token_id);
        let (new_balance) = SafeUint256.add(balance, value);
        ERC3525_values.write(token_id, new_balance);
        TransferValue.emit(Uint256(0, 0), token_id, value);
        return ();
    }

    func _get_new_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        new_token_id: Uint256
    ) {
        let (total: Uint256) = ERC3525_total_minted_.read();
        let (new_token_id: Uint256) = SafeUint256.add(total, Uint256(1, 0));
        return (new_token_id=new_token_id);
    }

    func _transfer_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_token_id: Uint256, to_token_id: Uint256, value: Uint256
    ) {
        assert_erc3525.minted(from_token_id);
        assert_erc3525.minted(to_token_id);
        assert_erc3525.token_id_not_zero(from_token_id);
        assert_erc3525.token_id_not_zero(to_token_id);

        let (from_slot) = ERC3525_slots.read(from_token_id);
        let (to_slot) = ERC3525_slots.read(to_token_id);

        with_attr error_message("ERC3525: transfer slot mismatch") {
            assert from_slot = to_slot;
        }

        let (from_balance) = ERC3525_values.read(from_token_id);
        with_attr error_message("ERC3525: transfer amount exceeds balance") {
            let (new_from_balance: Uint256) = SafeUint256.sub_le(from_balance, value);
        }
        ERC3525_values.write(from_token_id, new_from_balance);

        let (to_balance) = ERC3525_values.read(to_token_id);
        let (new_to_balance: Uint256) = SafeUint256.add(to_balance, value);
        ERC3525_values.write(to_token_id, new_to_balance);

        TransferValue.emit(from_token_id, to_token_id, value);

        let (to) = ERC721.owner_of(to_token_id);
        let (_) = _check_on_erc3525_received(
            from_token_id, to_token_id, to, value, 0, cast(0, felt*)
        );
        // Implementers should decide whether they can transfer to non-account addresses
        // with_attr error_message("ERC3525: transfer to non ERC3525Receiver implementer") {
        // assert_not_zero(success);
        // }

        return ();
    }

    func _burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: Uint256) {
        alloc_locals;
        assert_erc3525.uint256(token_id);
        assert_erc3525.minted(token_id);

        let (local value) = ERC3525_values.read(token_id);
        let (slot) = ERC3525_slots.read(token_id);

        ERC721Enumerable._burn(token_id);

        ERC3525_values.write(token_id, Uint256(0, 0));
        TransferValue.emit(token_id, Uint256(0, 0), value);

        ERC3525_slots.write(token_id, Uint256(0, 0));
        SlotChanged.emit(token_id, slot, Uint256(0, 0));
        return ();
    }

    func _burn_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, burn_value: Uint256
    ) {
        assert_erc3525.uint256(burn_value);
        assert_erc3525.uint256(token_id);
        assert_erc3525.minted(token_id);

        let (balance) = ERC3525_values.read(token_id);
        with_attr error_message("ERC3525: burn value exceeds balance") {
            let (new_balance: Uint256) = SafeUint256.sub_le(balance, burn_value);
        }
        ERC3525_values.write(token_id, new_balance);
        TransferValue.emit(token_id, Uint256(0, 0), burn_value);
        return ();
    }

    //
    // Metadata
    //

    func _set_contract_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        uri: felt
    ) {
        ERC3525_contract_uri.write(uri);
        return ();
    }

    func _set_slot_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        slot: Uint256, uri: felt
    ) {
        ERC3525_slot_uri.write(slot, uri);
        return ();
    }
}

func _check_on_erc3525_received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_token_id: Uint256,
    to_token_id: Uint256,
    to: felt,
    value: Uint256,
    data_len: felt,
    data: felt*,
) -> (success: felt) {
    let (caller) = get_caller_address();
    let (is_supported) = IERC165.supportsInterface(to, IERC3525_RECEIVER_ID);
    if (is_supported == TRUE) {
        let (selector) = IERC3525Receiver.onERC3525Received(
            to, caller, from_token_id, to_token_id, value, data_len, data
        );

        with_attr error_message("ERC3525: ERC3525Receiver rejected tokens") {
            assert selector = IERC3525_RECEIVER_ID;
        }
        return (success=TRUE);
    }
    let (is_account) = IERC165.supportsInterface(to, IACCOUNT_ID);
    return (success=is_account);
}

// Assert helpers
namespace assert_erc3525 {
    func minted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256
    ) {
        let exists = ERC721._exists(token_id);
        with_attr error_message("ERC3525: query for nonexistent token") {
            assert exists = TRUE;
        }
        return ();
    }

    func uint256{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: Uint256) {
        with_attr error_message("ERC3525: value is not a valid Uint256") {
            uint256_check(value);
        }
        return ();
    }

    func token_id_not_zero{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        value: Uint256
    ) {
        let (is_zero) = uint256_eq(Uint256(0, 0), value);
        with_attr error_message("ERC3525: token_id is zero") {
            assert FALSE = is_zero;
        }
        return ();
    }
}
