%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.library import ERC3525

const NAME = 'Carbonable Project';
const SYMBOL = 'CP';
const DECIMALS = 18;
const ADMIN = 'admin';
const USER1 = 'user1';
const USER2 = 'user2';
const USER3 = 'user3';
const TOKN1 = 1;
const TOKN2 = 2;
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
func test_can_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);
    let ZERO = Uint256(0, 0);

    %{
        expect_events(
        {"name": "Transfer"}, {"name": "TransferValue"},{"name": "SlotChanged"}
        )
    %}
    ERC3525._mint(user, token_id, slot, Uint256(420, 0));
    return ();
}

@view
func test_query_balance_nonexistent_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);
    let ZERO = Uint256(0, 0);

    %{ expect_revert(error_message="ERC3525: balance query for nonexistent token") %}
    let (bal: Uint256) = ERC3525.balance_of(token_id);

    return ();
}

@view
func test_query_balance_valid_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);
    let ZERO = Uint256(0, 0);

    ERC3525._mint(user, token_id, slot, Uint256(42, 0));

    let (bal: Uint256) = ERC3525.balance_of(token_id);
    assert 42 = bal.low;

    let (bal721) = ERC721.balance_of(user);
    assert 1 = bal721.low;

    return ();
}

@view
func test_query_slot_valid_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    let token_id = Uint256(TOKN1, 0);
    let (slot: Uint256) = ERC3525.slot_of(token_id);
    assert SLOT1 = slot.low;
    return ();
}

@view
func test_query_slot_nonexistent_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(666, 0);
    %{ expect_revert(error_message="ERC3525: slot query for nonexistent token") %}
    let (slot: Uint256) = ERC3525.slot_of(token_id);
    assert SLOT1 = slot.low;
    return ();
}

@view
func test_anyone_cannot_transfer_value_token_to_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to_token_id = Uint256(TOKN2, 0);
    let value_felt = 10;
    let value = Uint256(value_felt, 0);

    let (local bal1: Uint256) = ERC3525.balance_of(from_token_id);
    let (local bal2: Uint256) = ERC3525.balance_of(to_token_id);

    %{
        stop_prank = start_prank(ids.USER2); 
        expect_revert(error_message="ERC3525: insufficient allowance")
    %}
    ERC3525.transfer_from_token_id(from_token_id, to_token_id, value);
    %{ stop_prank() %}

    let (local new_bal1: Uint256) = ERC3525.balance_of(from_token_id);
    let (local new_bal2: Uint256) = ERC3525.balance_of(to_token_id);

    let diff = bal1.low - new_bal1.low;
    assert 0 = diff;
    let diff = new_bal2.low - bal2.low;
    assert 0 = diff;

    return ();
}

@view
func test_cannot_transfer_to_zero_address{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to_token_id = Uint256(TOKN2, 0);
    let value_felt = 10;
    let value = Uint256(value_felt, 0);

    %{ expect_revert(error_message="ERC3525: cannot transfer token zero or to zero address") %}
    ERC3525.transfer_from(from_token_id, Uint256(0, 0), 0, value);

    return ();
}

@view
func test_disambiguation_fails_if_invalid_parameters{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to_token_id = Uint256(TOKN2, 0);
    let value_felt = 10;
    let value = Uint256(value_felt, 0);

    %{ expect_revert(error_message="ERC3525: cannot set both token_id and to") %}
    ERC3525.transfer_from(from_token_id, to_token_id, 'some_address', value);

    return ();
}

@view
func test_owner_can_transfer_value_token_to_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to_token_id = Uint256(TOKN2, 0);
    let value_felt = 10;
    let value = Uint256(value_felt, 0);

    let (local bal1: Uint256) = ERC3525.balance_of(from_token_id);
    let (local bal2: Uint256) = ERC3525.balance_of(to_token_id);

    %{
        stop_prank = start_prank(ids.USER1); 
        expect_events({"name": "TransferValue"})
    %}
    ERC3525.transfer_from_token_id(from_token_id, to_token_id, value);

    %{ stop_prank() %}

    let (local new_bal1: Uint256) = ERC3525.balance_of(from_token_id);
    let (local new_bal2: Uint256) = ERC3525.balance_of(to_token_id);

    let diff = bal1.low - new_bal1.low;
    assert value_felt = diff;
    let diff = new_bal2.low - bal2.low;
    assert value_felt = diff;

    return ();
}

@view
func _test_tmp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let token_id = Uint256(TOKN1, 0);
    let (local owner) = ERC721.owner_of(token_id);
    %{ print(f'owner={ids.owner}') %}
    let is_approved = ERC721._is_approved_or_owner(0, token_id);
    let (is_approved) = ERC721.is_approved_for_all(owner, 0);
    %{ print("approved(0, token) =", ids.is_approved) %}
    let (approved) = ERC721.get_approved(token_id);
    %{ print("get_approved =", ids.approved) %}
    return ();
}

@view
func template_test{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    return ();
}
