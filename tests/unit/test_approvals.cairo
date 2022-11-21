%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.library import ERC3525
from tests.unit.library import assert_that, it

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
    ERC3525._mint(USER1, Uint256(TOKN1, 0), Uint256(SLOT1, 0), Uint256(42, 0));
    ERC3525._mint(USER2, Uint256(TOKN2, 0), Uint256(SLOT1, 0), Uint256(21, 0));
    return ();
}

@view
func test_owner_can_approve_anyone_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let caller = USER1;
    with caller {
        it.approves(TOKN1, USER3, 20);
    }
    return ();
}

@view
func test_owner_can_approve_more_to_same{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let caller = USER1;
    with caller {
        it.approves(TOKN1, USER3, 20);
        it.approves(TOKN1, USER3, 30);
    }
    return ();
}

@view
func test_owner_can_approve_someone_else{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let caller = USER1;
    with caller {
        it.approves(TOKN1, USER3, 20);
        it.approves(TOKN1, USER2, 30);
    }
    return ();
}

@view
func test_721approved_for_all_can_approve_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    // Approve USER3
    %{ stop_prank = start_prank(ids.USER1) %}
    ERC721.set_approval_for_all(USER3, TRUE);
    %{ stop_prank() %}

    let caller = USER3;
    with caller {
        it.approves(TOKN1, USER2, 20);
    }
    return ();
}

@view
func test_721approved_can_approve_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN1, 0);
    let value = Uint256(10, 0);

    %{ stop_prank = start_prank(ids.USER1) %}
    ERC721.approve(USER3, token_id);
    %{ stop_prank() %}

    let caller = USER3;
    with caller {
        it.approves(TOKN1, USER2, 20);
    }

    return ();
}

// Reverts
@view
func test_cannot_approve_value_invalid_token_id{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(-1, 0);  // invalid Uint256
    let value = Uint256(10, 0);
    %{
        stop_prank = start_prank(ids.USER1)
        expect_revert(error_message="ERC3525: value is not a valid Uint256")
    %}
    ERC3525.approve(token_id, USER2, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_approve_value_to_zero_address{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN1, 0);
    let value = Uint256(10, 0);
    %{
        stop_prank = start_prank(ids.USER1)
        expect_revert(error_message="ERC3525: cannot approve to the zero address")
    %}
    ERC3525.approve(token_id, 0, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_approve_value_to_self{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN1, 0);
    let value = Uint256(10, 0);
    %{
        stop_prank = start_prank(ids.USER1)
        expect_revert(error_message="ERC3525: approval to current owner")
    %}
    ERC3525.approve(token_id, USER1, value);
    %{ stop_prank() %}
    return ();
}

@view
func test_anyone_cannot_approve_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN1, 0);
    let value = Uint256(10, 0);
    %{
        stop_prank = start_prank(ids.USER2) # USER2 doesn't own TOKN1
        expect_revert(error_message="ERC3525: approve caller is not owner nor approved")
    %}
    ERC3525.approve(token_id, USER2, value);
    %{ stop_prank() %}
    return ();
}

@view
func test_cannot_approve_value_nonexistent_token_id{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(INVALID_TOKEN, 0);
    let value = Uint256(10, 0);
    %{
        stop_prank = start_prank(ids.USER1) 
        expect_revert(error_message="ERC721: owner query for nonexistent token")
    %}
    ERC3525.approve(token_id, USER2, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_approve_invalid_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN1, 0);
    let value = Uint256(-1, 0);
    %{
        stop_prank = start_prank(ids.USER1) 
        expect_revert(error_message="ERC3525: value is not a valid Uint256")
    %}
    ERC3525.approve(token_id, USER2, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_zero_address_cannot_approve_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN1, 0);
    let value = Uint256(10, 0);
    %{ expect_revert(error_message="ERC3525: cannot approve from the zero address") %}
    ERC3525.approve(token_id, USER2, value);
    %{ stop_prank() %}

    return ();
}
