%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.library import ERC3525
from tests.unit.library import assert_that

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

//
// Minting
//

@view
func test_can_mint_fresh{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(420, 0);

    %{ expect_events({"name": "Transfer"}, {"name": "TransferValue"},{"name": "SlotChanged"}) %}
    ERC3525._mint(user, token_id, slot, value);

    assert_that.ERC3525_balance_of_is(token_id, value);
    assert_that.slot_of_is(token_id, slot);
    assert_that.owner_is(token_id, user);

    return ();
}

@view
func test_can_mint_value_with_previous_balance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let user = USER1;
    let token_id = Uint256(TOKN1, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(69, 0);

    let (local old_balance) = ERC3525.balance_of(token_id);
    %{ expect_events({"name": "Transfer"}, {"name": "TransferValue"},{"name": "SlotChanged"}) %}
    ERC3525._mint_value(token_id, value);

    let (expected_balance) = SafeUint256.add(old_balance, value);
    assert_that.ERC3525_balance_of_is(token_id, expected_balance);
    assert_that.slot_of_is(token_id, slot);
    assert_that.owner_is(token_id, user);

    return ();
}

@view
func test_cannot_mint_invalid_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let user = 'bal7';
    let token_id = Uint256(-1, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(420, 0);

    %{ expect_revert(error_message="ERC3525: value is not a valid Uint256") %}
    ERC3525._mint(user, token_id, slot, value);
    return ();
}

@view
func test_cannot_mint_zero_token_id{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(0, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(420, 0);

    %{ expect_revert(error_message="ERC3525: token_id is zero") %}
    ERC3525._mint(USER1, token_id, slot, value);
    return ();
}

@view
func test_cannot_mint_to_zero_address{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(0, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(420, 0);

    %{ expect_revert(error_message="ERC3525: mint to the zero address") %}
    ERC3525._mint(0, token_id, slot, value);
    return ();
}

@view
func test_cannot_mint_existing_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    let token_id = Uint256(TOKN1, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(420, 0);

    %{ expect_revert(error_message="ERC3525: token_id already exists") %}
    ERC3525._mint(USER1, token_id, slot, value);
    return ();
}

//
// Burning
//

@view
func test_can_burn_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let token_id = Uint256(TOKN1, 0);

    %{ expect_events({"name": "Transfer"}, {"name": "TransferValue"},{"name": "SlotChanged"}) %}
    ERC3525._burn(token_id);

    %{ expect_revert(error_message="ERC3525: query for nonexistent token") %}
    let (_) = ERC3525.balance_of(token_id);
    return ();
}

@view
func test_can_burn_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let token_id = Uint256(TOKN1, 0);
    let value = Uint256(10, 0);

    %{ expect_events({"name": "Transfer"}, {"name": "TransferValue"},{"name": "SlotChanged"}) %}
    ERC3525._burn_value(token_id, value);

    return ();
}

// Reverts
@view
func test_cannot_burn_nonexistent_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(INVALID_TOKEN, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(420, 0);

    %{ expect_revert(error_message="ERC3525: query for nonexistent token") %}
    ERC3525._burn(token_id);
    return ();
}

@view
func test_cannot_burn_value_exceeding_balance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(TOKN1, 0);
    let slot = Uint256(SLOT1, 0);
    let (balance) = ERC3525.balance_of(token_id);
    let (value) = SafeUint256.add(Uint256(1, 0), balance);

    %{
        stop_prank = start_prank(ids.USER1)
        expect_revert(error_message="ERC3525: burn value exceeds balance")
    %}
    ERC3525._burn_value(token_id, value);
    return ();
}
