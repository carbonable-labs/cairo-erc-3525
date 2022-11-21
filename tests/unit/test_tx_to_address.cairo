%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256, ALL_ONES, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.safemath.library import SafeUint256
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
const TOKN3 = 3;
const INVALID_ID = 666;
const SLOT1 = 'slot1';
const SLOT2 = 'slot2';

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ERC721.initializer(NAME, SYMBOL);
    ERC721Enumerable.initializer();
    ERC3525.initializer(DECIMALS);
    ERC3525._mint(USER1, Uint256(TOKN1, 0), Uint256(SLOT1, 0), Uint256(42, 0));
    ERC3525._mint(USER2, Uint256(TOKN2, 0), Uint256(SLOT1, 0), Uint256(21, 0));
    ERC3525._mint(USER2, Uint256(TOKN3, 0), Uint256(SLOT2, 0), Uint256(21, 0));

    return ();
}

@view
func test_owner_can_transfer_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    let from_token_id = Uint256(TOKN1, 0);
    let to = USER3;
    let value = Uint256(10, 0);
    let caller = USER1;

    with caller {
        it.transfers(from_token_id, to, value);
    }

    return ();
}

@view
func test_approved_can_transfer_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to = USER2;
    let value = Uint256(10, 0);
    let caller = USER3;

    %{
        stop_prank = start_prank(ids.USER1)
        expect_events({"name": "Approval"})
    %}
    ERC721.approve(USER3, from_token_id);
    %{ stop_prank() %}

    with caller {
        it.transfers(from_token_id, to, value);
    }
    return ();
}

@view
func test_value_approved_can_transfer{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to = USER2;
    let value = Uint256(10, 0);
    let (approved_value) = SafeUint256.add(value, Uint256(1, 0));
    let caller = USER3;

    %{
        stop_prank = start_prank(ids.USER1)
        expect_events({"name": "ApprovalValue"})
    %}
    ERC3525.approve(from_token_id, USER3, approved_value);
    %{ stop_prank() %}

    let (local old_allowance: Uint256) = ERC3525.allowance(from_token_id, USER3);

    with caller {
        it.transfers(from_token_id, to, value);
    }

    let (allowance) = ERC3525.allowance(from_token_id, USER3);
    let (expected_allowance) = SafeUint256.sub_le(old_allowance, value);
    assert_that.allowance_is(from_token_id, USER3, expected_allowance);

    return ();
}

@view
func test_unlimited_value_approved_can_transfer{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to = USER2;
    let value = Uint256(10, 0);
    let unlimited_approved_value = Uint256(ALL_ONES, ALL_ONES);
    let caller = USER3;

    %{
        stop_prank = start_prank(ids.USER1)
        expect_events({"name": "ApprovalValue"})
    %}
    ERC3525.approve(from_token_id, USER3, unlimited_approved_value);
    %{ stop_prank() %}
    let (local allowance: Uint256) = ERC3525.allowance(from_token_id, USER3);

    with caller {
        it.transfers(from_token_id, to, value);
    }

    let (local new_allowance: Uint256) = ERC3525.allowance(from_token_id, USER3);
    let (is_unlimited) = uint256_eq(unlimited_approved_value, new_allowance);
    assert 1 = is_unlimited;

    return ();
}

@view
func test_approved_forall_can_transfer{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to = USER2;
    let value = Uint256(10, 0);
    let caller = USER3;

    %{
        stop_prank = start_prank(ids.USER1)
        expect_events({"name": "ApprovalForAll"})
    %}
    ERC721.set_approval_for_all(USER3, TRUE);
    %{ stop_prank() %}

    with caller {
        it.transfers(from_token_id, to, value);
    }

    return ();
}

@view
func test_owner_can_transfer_value_to_themselves{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to = USER1;
    let value: Uint256 = Uint256(10, 0);
    let caller = USER1;

    with caller {
        it.transfers_to_owner(from_token_id, to, value);
    }

    return ();
}

// Reverts
@view
func test_anyone_cannot_transfer_value{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to = USER2;
    let value = Uint256(10, 0);

    %{
        stop_prank = start_prank(ids.USER2) 
        expect_revert(error_message="ERC3525: insufficient allowance")
    %}
    ERC3525.transfer_from(from_token_id, Uint256(0, 0), to, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_transfer_value_exceeding_balance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to = USER2;
    let (local balance: Uint256) = ERC3525.balance_of(from_token_id);
    let (value) = SafeUint256.add(Uint256(1, 0), balance);

    %{
        stop_prank = start_prank(ids.USER1) 
        expect_revert(error_message="ERC3525: transfer amount exceeds balance")
    %}
    ERC3525.transfer_from(from_token_id, Uint256(0, 0), to, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_transfer_value_to_zero_address{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to = 0;
    let (local balance: Uint256) = ERC3525.balance_of(from_token_id);
    let (value) = SafeUint256.add(Uint256(1, 0), balance);

    %{
        stop_prank = start_prank(ids.USER1) 
        expect_revert(error_message="ERC3525: cannot transfer token zero or to zero address")
    %}
    ERC3525.transfer_from(from_token_id, Uint256(0, 0), to, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_transfer_when_value_exceeds_allowance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to = USER2;
    let value = Uint256(10, 0);
    let (approved_value) = SafeUint256.sub_le(value, Uint256(1, 0));

    %{
        stop_prank = start_prank(ids.USER1)
        expect_events({"name": "ApprovalValue"})
    %}
    ERC3525.approve(from_token_id, USER3, approved_value);
    %{
        stop_prank()
        stop_prank = start_prank(ids.USER3); 
        expect_revert(error_message="ERC3525: insufficient allowance")
    %}
    ERC3525.transfer_from(from_token_id, Uint256(0, 0), to, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_transfer_invalid_from_uint{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(-1, -1);  // invalid Uint256
    let to = USER2;
    let value = Uint256(10, 0);
    let (approved_value) = SafeUint256.sub_le(value, Uint256(1, 0));

    %{
        stop_prank = start_prank(ids.USER1); 
        expect_revert(error_message="ERC3525: value is not a valid Uint256")
    %}
    ERC3525.transfer_from(from_token_id, Uint256(0, 0), to, value);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_transfer_from_zero_id{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(0, 0);
    let to = USER2;
    let value = Uint256(10, 0);

    %{
        stop_prank = start_prank(ids.USER1); 
        expect_revert(error_message="ERC3525: token_id is zero")
    %}
    ERC3525.transfer_from(from_token_id, Uint256(0, 0), to, value);
    %{ stop_prank() %}

    return ();
}
