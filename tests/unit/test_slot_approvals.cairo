%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.extensions.slotapprovable.library import ERC3525SlotApprovable
from carbonable.erc3525.library import ERC3525

from tests.unit.library import assert_that, it, with_slots_it

const NAME = 'Carbonable Project';
const SYMBOL = 'CP';
const DECIMALS = 18;
const ADMIN = 'admin';
const USER1 = 'user1';
const USER2 = 'user2';
const USER3 = 'user3';
const TOKN1 = 1;
const TOKN2 = 2;
const INVALID_TOKEN = 666;
const SLOT1 = 'slot1';
const SLOT2 = 'slot2';

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ERC721.initializer(NAME, SYMBOL);
    ERC721Enumerable.initializer();
    ERC3525.initializer(DECIMALS);
    ERC3525._mint_new(USER1, Uint256(SLOT1, 0), Uint256(42, 0));
    ERC3525._mint_new(USER2, Uint256(SLOT1, 0), Uint256(21, 0));
    ERC3525._mint_new(USER1, Uint256(SLOT2, 0), Uint256(21, 0));
    return ();
}

@view
func test_owner_can_approve_slot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    let caller = USER1;
    with caller {
        with_slots_it.sets_slot_approval(USER1, SLOT1, USER3, TRUE);
    }
    return ();
}

@view
func test_slot_operator_can_approve_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let caller = USER1;
    with caller {
        with_slots_it.sets_slot_approval(USER1, SLOT1, USER3, TRUE);
    }
    let caller = USER3;
    with caller {
        with_slots_it.approves(TOKN1, USER3, 30);
    }
    return ();
}

@view
func test_slot_operator_can_transfer_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let caller = USER1;
    with caller {
        with_slots_it.sets_slot_approval(USER1, SLOT1, USER3, TRUE);
    }
    let caller = USER3;
    with caller {
        with_slots_it.transfers(TOKN1, USER3, 30);
    }
    return ();
}

// Reverts
@view
func test_slot_operator_cannot_approve_any_token_in_slot{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN2, 0);
    let value = Uint256(3, 0);

    let caller = USER1;
    with caller {
        with_slots_it.sets_slot_approval(USER1, SLOT1, USER3, TRUE);
    }

    %{
        stop_prank = start_prank(ids.USER3)
        expect_revert(error_message="ERC3525SlotApprovable: approve caller is not owner nor approved for all/slot")
    %}
    ERC3525SlotApprovable.approve_value(token_id, USER3, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_slot_operator_cannot_approve_any_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN2, 0);
    let value = Uint256(3, 0);

    let caller = USER1;
    with caller {
        with_slots_it.sets_slot_approval(USER1, SLOT1, USER3, TRUE);
    }

    %{
        stop_prank = start_prank(ids.USER3)
        expect_revert(error_message="ERC3525SlotApprovable: approve caller is not owner nor approved for all/slot")
    %}
    ERC3525SlotApprovable.approve_value(token_id, USER3, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_slot_operator_cannot_transfer_anyones_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let caller = USER1;
    with caller {
        with_slots_it.sets_slot_approval(USER1, SLOT1, USER3, TRUE);
    }
    let token_id = Uint256(TOKN2, 0);  // owner is USER2
    let value = Uint256(1, 0);
    %{
        stop_prank = start_prank(ids.USER3)
        expect_revert(error_message="ERC3525: insufficient allowance")
    %}
    ERC3525SlotApprovable.transfer_from(token_id, Uint256(0, 0), USER3, value);
    %{ stop_prank() %}
    return ();
}

@view
func test_slot_operator_cannot_transfer_value_to_other_slot{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let caller = USER1;
    with caller {
        with_slots_it.sets_slot_approval(USER1, SLOT1, USER3, TRUE);
    }
    let from_token_id = Uint256(TOKN1, 0);
    let to_token_id = Uint256(3, 0);  // In slot 2
    let value = Uint256(1, 0);
    %{
        stop_prank = start_prank(ids.USER3)
        expect_revert(error_message="ERC3525: transfer slot mismatch")
    %}
    ERC3525SlotApprovable.transfer_from(from_token_id, to_token_id, 0, value);
    %{ stop_prank() %}
    return ();
}

@view
func test_revoked_slot_operator_cannot_approve{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN1, 0);  // In SLOT1
    let value = Uint256(3, 0);

    let caller = USER1;
    with caller {
        with_slots_it.sets_slot_approval(USER1, SLOT1, USER3, TRUE);
    }

    let caller = USER1;
    with caller {
        with_slots_it.sets_slot_approval(USER1, SLOT1, USER3, FALSE);
    }

    %{
        stop_prank = start_prank(ids.USER3)
        expect_revert(error_message="ERC3525SlotApprovable: approve caller is not owner nor approved for all/slot")
    %}
    ERC3525SlotApprovable.approve_value(token_id, USER3, value);
    %{ stop_prank() %}

    return ();
}
