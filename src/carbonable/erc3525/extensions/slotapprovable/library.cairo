// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.uint256 import Uint256, uint256_eq, uint256_not
from starkware.starknet.common.syscalls import get_caller_address

// OpenZeppelin dependencies
from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc721.library import ERC721

// Project dependencies
from carbonable.erc3525.library import ERC3525, assert_erc3525
from carbonable.erc3525.utils.constants.library import IERC3525_SLOT_APPROVABLE_ID

//
// Events
//

@event
func ApprovalForSlot(owner: felt, slot: Uint256, operator: felt, approved: felt) {
}

//
// Storage
//

@storage_var
func ERC3525SlotApprovable_slot_approvals(owner: felt, slot: Uint256, operator: felt) -> (
    approved: felt
) {
}

namespace ERC3525SlotApprovable {
    //
    // Initializer
    //

    func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        ERC165.register_interface(IERC3525_SLOT_APPROVABLE_ID);
        return ();
    }

    //
    // Externals
    //

    func set_approval_for_slot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, slot: Uint256, operator: felt, approved: felt
    ) {
        assert_erc3525.uint256(slot);

        let (caller) = get_caller_address();
        let caller_not_owner = is_not_zero(caller - owner);
        let (is_approved_for_all) = ERC721.is_approved_for_all(operator, owner);

        with_attr error_message("ERC3525: caller is neither owner nor approved for all") {
            assert 0 = caller_not_owner * (1 - is_approved_for_all);
        }

        with_attr error_message(
                "ERC3525SlotApprovable: either the caller or operator is the zero address") {
            assert_not_zero(caller * operator);
        }

        with_attr error_message("ERC3525SlotApprovable: approve to caller") {
            assert_not_equal(caller, operator);
        }

        with_attr error_message("ERC3525SlotApprovable: approved is not a Cairo boolean") {
            assert 0 = approved * (1 - approved);
        }

        ERC3525SlotApprovable_slot_approvals.write(owner, slot, operator, approved);
        ApprovalForSlot.emit(owner, slot, operator, approved);
        return ();
    }

    func is_approved_for_slot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, slot: Uint256, operator: felt
    ) -> (approved: felt) {
        assert_erc3525.uint256(slot);
        let (approved) = ERC3525SlotApprovable_slot_approvals.read(owner, slot, operator);
        return (approved=approved);
    }

    func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        to: felt, token_id: Uint256
    ) {
        assert_erc3525.uint256(token_id);

        let (owner) = ERC721.owner_of(token_id);

        with_attr error_message("ERC3525SlotApprovable: approve to owner") {
            assert_not_equal(to, owner);
        }

        let (caller) = get_caller_address();
        let is_approved = _is_approved_or_owner(caller, token_id);
        with_attr error_message(
                "ERC3525SlotApprovable: approve caller is not owner nor approved for all/slot") {
            assert 1 = is_approved;
        }

        ERC721._approve(to, token_id);
        return ();
    }

    func approve_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, to: felt, value: Uint256
    ) {
        assert_erc3525.uint256(token_id);
        let (slot) = ERC3525.slot_of(token_id);
        let (owner) = ERC721.owner_of(token_id);

        with_attr error_message("ERC3525SlotApprovable: approve to owner") {
            assert_not_equal(to, owner);
        }
        let (caller) = get_caller_address();
        let is_approved = _is_approved_or_owner(caller, token_id);
        with_attr error_message(
                "ERC3525SlotApprovable: approve caller is not owner nor approved for all/slot") {
            assert 1 = is_approved;
        }

        ERC3525._approve_value(token_id, to, value);
        return ();
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

        let (local new_token_id) = ERC3525._get_new_token_id();
        let (slot) = ERC3525.slot_of(from_token_id);
        ERC3525._mint(to, new_token_id, slot, Uint256(0, 0));
        ERC3525._transfer_value(from_token_id, new_token_id, value);

        return (to_token_id=new_token_id);
    }

    func transfer_from_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        from_token_id: Uint256, to_token_id: Uint256, value: Uint256
    ) -> (to_token_id: Uint256) {
        let (caller) = get_caller_address();
        _spend_allowance(caller, from_token_id, value);
        ERC3525._transfer_value(from_token_id, to_token_id, value);

        return (to_token_id=to_token_id);
    }

    //
    // Internals
    //

    func _spend_allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        spender: felt, token_id: Uint256, amount: Uint256
    ) {
        alloc_locals;
        let (current_allowance) = ERC3525.allowance(token_id, spender);
        let (infinity: Uint256) = uint256_not(Uint256(0, 0));
        let (is_infinite: felt) = uint256_eq(current_allowance, infinity);

        let is_approved = _is_approved_or_owner(spender, token_id);

        if (is_infinite == FALSE and is_approved == FALSE) {
            with_attr error_message("ERC3525: insufficient allowance") {
                let (new_allowance: Uint256) = SafeUint256.sub_le(current_allowance, amount);
            }
            ERC3525._approve_value(token_id, spender, new_allowance);
            return ();
        }
        return ();
    }

    func _is_approved_or_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        operator: felt, token_id: Uint256
    ) -> felt {
        alloc_locals;
        let (local owner) = ERC721.owner_of(token_id);

        let operator_not_owner = is_not_zero(operator - owner);
        let (approved_for_all) = ERC721.is_approved_for_all(operator, owner);
        let (slot) = ERC3525.slot_of(token_id);
        let (slot_approved) = is_approved_for_slot(owner, slot, operator);
        let approved = is_le(1, 1 - operator_not_owner + approved_for_all + slot_approved);

        return (approved);
    }
}
