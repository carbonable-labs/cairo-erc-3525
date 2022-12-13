%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.extensions.slotenumerable.library import ERC3525SlotEnumerable
from carbonable.erc3525.library import ERC3525
from carbonable.erc3525.utils.constants.library import IERC3525_RECEIVER_ID

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
    ERC3525SlotEnumerable._mint_new(USER1, Uint256(SLOT1, 0), Uint256(42, 0));  // id #1
    ERC3525SlotEnumerable._mint_new(USER2, Uint256(SLOT1, 0), Uint256(21, 0));  // id #2
    ERC3525SlotEnumerable._mint_new(USER1, Uint256(SLOT2, 0), Uint256(21, 0));  // id #3
    ERC3525SlotEnumerable._mint_new(USER2, Uint256(SLOT2, 0), Uint256(11, 0));  // id #4
    return ();
}

@view
func test_returns_slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assert_that.slot_count_is(2);
    return ();
}

@view
func test_returns_valid_slots_by_id{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    assert_that.slot_by_index_is(1, SLOT1);
    assert_that.slot_by_index_is(2, SLOT2);
    return ();
}

// / it reverts if index too high
@view
func test_reverts_invalid_slot_too_high{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ expect_revert(error_message="ERC3525SlotEnumerable: index out of bounds") %}
    assert_that.slot_by_index_is(3, SLOT1);
    return ();
}

@view
func test_reverts_invalid_slot_negative{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ expect_revert(error_message="ERC3525SlotEnumerable: index out of bounds") %}
    assert_that.slot_by_index_is(2 ** 128 - 1, 0);
    return ();
}

// token supply in slots
// / it returns the numbers of tokens in slot
@view
func test_returns_token_supply_in_slot{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    assert_that.token_supply_in_slot_is(SLOT1, 2);
    assert_that.token_supply_in_slot_is(SLOT2, 2);
    return ();
}

// / when there are NO tokens in slot
// // it returns zeros
@view
func test_returns_zero_if_slot_empty{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    assert_that.token_supply_in_slot_is('nonexistent slot', 0);
    return ();
}

// / stays the same after 721 tranfer
@view
func test_721_tx_keeps_tokens_in_slot{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ stop_prank = start_prank(ids.USER1) %}
    ERC721Enumerable.transfer_from(USER1, USER2, Uint256(TOKN1, 0));
    %{ stop_prank() %}
    assert_that.token_supply_in_slot_is(SLOT1, 2);
    return ();
}

// / stays the same after token2token tx
@view
func test_tx_token_to_token_keeps_tokens_in_slot{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let value = Uint256(1, 0);
    %{
        stop_prank = start_prank(ids.USER1) 
        mock_call(ids.USER2, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.USER2, "supportsInterface", [ids.TRUE])
    %}
    ERC3525SlotEnumerable.transfer_from(Uint256(TOKN1, 0), Uint256(TOKN2, 0), 0, value);
    %{ stop_prank() %}
    assert_that.token_supply_in_slot_is(SLOT1, 2);
    return ();
}

// / adjust after tx token2addr
@view
func test_tx_token_to_address_adjusts_tokens_in_slot{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let value = Uint256(1, 0);
    %{
        stop_prank = start_prank(ids.USER1) 
        mock_call(ids.USER2, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.USER2, "supportsInterface", [ids.TRUE])
    %}
    ERC3525SlotEnumerable.transfer_from(Uint256(TOKN1, 0), Uint256(0, 0), USER2, value);
    %{ stop_prank() %}
    assert_that.token_supply_in_slot_is(SLOT1, 3);
    return ();
}

// tokenInSlotByIndex
// / returns ID when index is in range
@view
func test_token_index_returns_token_id_if_index_valid{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    assert_that.token_in_slot_by_index_is(SLOT1, 1, 1);
    assert_that.token_in_slot_by_index_is(SLOT1, 2, 2);
    assert_that.token_in_slot_by_index_is(SLOT2, 1, 3);
    assert_that.token_in_slot_by_index_is(SLOT2, 2, 4);
    return ();
}

// / reverts when index not in range
@view
func test_token_index_reverts_if_index_too_high{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ expect_revert(error_message="ERC3525SlotEnumerable: slot token index out of bounds") %}
    assert_that.token_in_slot_by_index_is(SLOT1, 3, 666);
    return ();
}

@view
func test_token_index_reverts_if_index_invalid{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ expect_revert(error_message="ERC3525SlotEnumerable: slot token index out of bounds") %}
    assert_that.token_in_slot_by_index_is(SLOT1, 2 ** 127 - 123, 666);
    return ();
}

@view
func test_token_index_zero_nonexistent{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    assert_that.token_in_slot_by_index_is('nonexistent slot', 0, 0);
    return ();
}

@view
func test_token_index_stays_the_same_after_721_tx{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ stop_prank = start_prank(ids.USER1) %}
    ERC721Enumerable.transfer_from(USER1, USER2, Uint256(TOKN1, 0));
    %{ stop_prank() %}
    assert_that.token_in_slot_by_index_is(SLOT1, TOKN1, 1);
    return ();
}

@view
func test_token_index_stays_after_tx_token_to_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let value = Uint256(1, 0);
    %{
        stop_prank = start_prank(ids.USER1) 
        mock_call(ids.USER2, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.USER2, "supportsInterface", [ids.TRUE])
    %}
    ERC3525SlotEnumerable.transfer_from(Uint256(TOKN1, 0), Uint256(TOKN2, 0), 0, value);
    %{ stop_prank() %}
    assert_that.token_in_slot_by_index_is(SLOT1, 1, 1);
    assert_that.token_in_slot_by_index_is(SLOT1, 2, 2);
    return ();
}

@view
func test_token_index_adjusts_after_tx_token_to_address{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let value = Uint256(1, 0);
    %{
        stop_prank = start_prank(ids.USER1) 
        mock_call(ids.USER2, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.USER2, "supportsInterface", [ids.TRUE])
    %}
    ERC3525SlotEnumerable.transfer_from(Uint256(TOKN1, 0), Uint256(0, 0), USER2, value);
    %{ stop_prank() %}
    assert_that.token_in_slot_by_index_is(SLOT1, 1, 1);
    assert_that.token_in_slot_by_index_is(SLOT1, 2, 2);
    assert_that.token_in_slot_by_index_is(SLOT1, 3, 5);
    return ();
}

@view
func test_token_index_adjusts_after_burn{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let value = Uint256(1, 0);
    %{
        stop_prank = start_prank(ids.USER1) 
        mock_call(ids.USER2, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.USER2, "supportsInterface", [ids.TRUE])
    %}
    ERC3525SlotEnumerable._burn(Uint256(TOKN1, 0));
    %{ stop_prank() %}
    assert_that.token_in_slot_by_index_is(SLOT1, 1, 2);
    assert_that.token_supply_in_slot_is(SLOT1, 1);
    return ();
}
