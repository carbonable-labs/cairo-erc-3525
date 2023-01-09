%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.extensions.slotenumerable.library import ERC3525SlotEnumerable
from carbonable.erc3525.library import ERC3525
from carbonable.erc3525.presets.ERC3525Full import split, merge
from carbonable.erc3525.utils.constants.library import IERC3525_RECEIVER_ID

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
    ERC3525SlotEnumerable.initializer();
    return ();
}

@view
func test_can_split_2{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(1 + 2, 0);

    ERC3525SlotEnumerable._mint(user, token_id, slot, value);
    local amounts: Uint256* = cast(new (Uint256(1, 0), Uint256(2, 0)), Uint256*);
    %{
        stop_prank = start_prank(ids.user) 
        mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.user, "supportsInterface", [ids.TRUE])
    %}
    let (new_token_ids_len, new_token_ids) = split(token_id, 2, amounts);
    %{ stop_prank() %}
    assert_that.ERC3525_balance_of_is(Uint256(2, 0), Uint256(1, 0));
    assert_that.ERC3525_balance_of_is(token_id, Uint256(2, 0));

    assert_that.owner_is(Uint256(2, 0), user);
    assert_that.owner_is(token_id, user);

    return ();
}

@view
func test_can_split{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10, 0);

    ERC3525SlotEnumerable._mint(user, token_id, slot, value);
    local amounts: Uint256* = cast(
        new (
            Uint256(1, 0),
            Uint256(2, 0),
            Uint256(3, 0),
            Uint256(4, 0),
            Uint256(5, 0),
            Uint256(6, 0),
            Uint256(7, 0),
            Uint256(8, 0),
            Uint256(9, 0),
            Uint256(10, 0),
        ),
        Uint256*,
    );
    %{
        stop_prank = start_prank(ids.user) 
        mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.user, "supportsInterface", [ids.TRUE])
    %}
    let (new_token_ids_len, new_token_ids) = split(token_id, 10, amounts);
    %{ stop_prank() %}
    assert_that.ERC3525_balance_of_is(Uint256(2, 0), Uint256(1, 0));
    assert_that.ERC3525_balance_of_is(Uint256(3, 0), Uint256(2, 0));
    assert_that.ERC3525_balance_of_is(Uint256(4, 0), Uint256(3, 0));
    assert_that.ERC3525_balance_of_is(Uint256(5, 0), Uint256(4, 0));
    assert_that.ERC3525_balance_of_is(Uint256(6, 0), Uint256(5, 0));
    assert_that.ERC3525_balance_of_is(Uint256(7, 0), Uint256(6, 0));
    assert_that.ERC3525_balance_of_is(Uint256(8, 0), Uint256(7, 0));
    assert_that.ERC3525_balance_of_is(Uint256(9, 0), Uint256(8, 0));
    assert_that.ERC3525_balance_of_is(Uint256(10, 0), Uint256(9, 0));
    assert_that.ERC3525_balance_of_is(token_id, Uint256(10, 0));

    assert_that.owner_is(Uint256(2, 0), user);
    assert_that.owner_is(Uint256(3, 0), user);
    assert_that.owner_is(Uint256(4, 0), user);
    assert_that.owner_is(Uint256(5, 0), user);
    assert_that.owner_is(Uint256(6, 0), user);
    assert_that.owner_is(Uint256(7, 0), user);
    assert_that.owner_is(Uint256(8, 0), user);
    assert_that.owner_is(Uint256(9, 0), user);
    assert_that.owner_is(Uint256(10, 0), user);
    assert_that.owner_is(token_id, user);

    return ();
}

@view
func test_can_merge{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let user = 'bal7';
    let slot = Uint256(SLOT1, 0);

    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(1, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(2, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(3, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(4, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(5, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(6, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(7, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(8, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(9, 0));

    local token_ids: Uint256* = cast(
        new (
            Uint256(1, 0),
            Uint256(2, 0),
            Uint256(3, 0),
            Uint256(4, 0),
            Uint256(5, 0),
            Uint256(6, 0),
            Uint256(7, 0),
            Uint256(8, 0),
            Uint256(9, 0),
        ),
        Uint256*,
    );
    %{
        stop_prank = start_prank(ids.user) 
        mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.user, "supportsInterface", [ids.TRUE])
    %}
    merge(9, token_ids);
    %{ stop_prank() %}

    assert_that.ERC3525_balance_of_is(Uint256(9, 0), Uint256(1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9, 0));

    assert_that.token_id_is_nonexistent(Uint256(1, 0));
    assert_that.token_id_is_nonexistent(Uint256(2, 0));
    assert_that.token_id_is_nonexistent(Uint256(3, 0));
    assert_that.token_id_is_nonexistent(Uint256(4, 0));
    assert_that.token_id_is_nonexistent(Uint256(5, 0));
    assert_that.token_id_is_nonexistent(Uint256(6, 0));
    assert_that.token_id_is_nonexistent(Uint256(7, 0));
    assert_that.token_id_is_nonexistent(Uint256(8, 0));
    assert_that.owner_is(Uint256(9, 0), user);

    return ();
}

@view
func test_can_merge_2{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let user = 'bal7';
    let slot = Uint256(SLOT1, 0);

    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(1, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(2, 0));

    local token_ids: Uint256* = cast(new (Uint256(1, 0), Uint256(2, 0)), Uint256*);
    %{
        stop_prank = start_prank(ids.user) 
        mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.user, "supportsInterface", [ids.TRUE])
    %}
    merge(2, token_ids);
    %{ stop_prank() %}

    assert_that.ERC3525_balance_of_is(Uint256(2, 0), Uint256(1 + 2, 0));

    assert_that.token_id_is_nonexistent(Uint256(1, 0));
    assert_that.owner_is(Uint256(2, 0), user);

    return ();
}

//
// Reverts
//

@view
func test_cannot_split_more_than_balance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9, 0);

    ERC3525SlotEnumerable._mint(user, token_id, slot, value);
    local amounts: Uint256* = cast(
        new (
            Uint256(1, 0),
            Uint256(2, 0),
            Uint256(3, 0),
            Uint256(4, 0),
            Uint256(5, 0),
            Uint256(6, 0),
            Uint256(7, 0),
            Uint256(8, 0),
            Uint256(9, 0),
            Uint256(10, 0),
        ),
        Uint256*,
    );
    %{
        stop_prank = start_prank(ids.user) 
        mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.user, "supportsInterface", [ids.TRUE])
        expect_revert(error_message="ERC3525: Split amounts do not sum to balance")
    %}
    let (new_token_ids_len, new_token_ids) = split(token_id, 10, amounts);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_split_1{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);
    let value = Uint256(1, 0);

    ERC3525SlotEnumerable._mint(user, token_id, slot, value);
    local amounts: Uint256* = cast(new (Uint256(1, 0)), Uint256*);
    %{
        stop_prank = start_prank(ids.user) 
        mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.user, "supportsInterface", [ids.TRUE])
        expect_revert(error_message="ERC3525: split length too low")
    %}
    let (new_token_ids_len, new_token_ids) = split(token_id, 1, amounts);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_merge_if_not_owner{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);

    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(1, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(2, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(3, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(4, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(5, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(6, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(7, 0));
    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(8, 0));
    ERC3525SlotEnumerable._mint_new(USER1, slot, Uint256(9, 0));

    local token_ids: Uint256* = cast(
        new (
            Uint256(1, 0),
            Uint256(2, 0),
            Uint256(3, 0),
            Uint256(4, 0),
            Uint256(5, 0),
            Uint256(6, 0),
            Uint256(7, 0),
            Uint256(8, 0),
            Uint256(9, 0),
        ),
        Uint256*,
    );
    %{
        stop_prank = start_prank(ids.user) 
        mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.user, "supportsInterface", [ids.TRUE])

        expect_revert(error_message="ERC3525: merge tokens not from owner")
    %}
    merge(9, token_ids);
    %{ stop_prank() %}

    return ();
}

@view
func test_can_merge_1{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let user = 'bal7';
    let slot = Uint256(SLOT1, 0);

    ERC3525SlotEnumerable._mint_new(user, slot, Uint256(1, 0));

    local token_ids: Uint256* = cast(new (Uint256(1, 0)), Uint256*);
    %{
        stop_prank = start_prank(ids.user) 
        mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
        mock_call(ids.user, "supportsInterface", [ids.TRUE])
        expect_revert(error_message="ERC3525: merge length too low")
    %}
    merge(1, token_ids);
    %{ stop_prank() %}

    return ();
}
