use starknet::testing::{set_caller_address, set_contract_address};
use array::ArrayTrait;
use cairo_erc_721::module::ERC721;
use cairo_erc_3525::module::ERC3525;
use cairo_erc_3525::tests::unit::constants::{
    STATE, VALUE_DECIMALS, TOKEN_ID_1, INVALID_TOKEN, SLOT_1, VALUE, ZERO, OWNER, OPERATOR, SOMEONE,
    ANYONE
};

// Settings

fn setup() -> ERC3525::ContractState {
    let mut state = STATE();
    ERC3525::InternalImpl::initializer(ref state, VALUE_DECIMALS);
    ERC3525::InternalImpl::_mint(ref state, OWNER(), TOKEN_ID_1, SLOT_1, 1 * VALUE);
    state
}

// Tests split

#[test]
#[available_gas(20000000)]
fn test_can_split_2() {
    let mut state = setup();
    let amounts: Array<u256> = array![VALUE / 2, VALUE / 3];
    set_caller_address(OWNER());
    let token_ids: Array<u256> = ERC3525::InternalImpl::_split(ref state, TOKEN_ID_1, @amounts);
    assert(token_ids.len() == 2, 'Wrong token ids length');
    assert(
        ERC3525::ERC3525Impl::value_of(@state, TOKEN_ID_1) == VALUE - VALUE / 2 - VALUE / 3,
        'Wrong value'
    );
    assert(*token_ids.at(0) == TOKEN_ID_1 + 1, 'Wrong token id');
    assert(ERC3525::ERC3525Impl::value_of(@state, *token_ids.at(0)) == VALUE / 2, 'Wrong value');
    assert(*token_ids.at(1) == TOKEN_ID_1 + 2, 'Wrong token id');
    assert(ERC3525::ERC3525Impl::value_of(@state, *token_ids.at(1)) == VALUE / 3, 'Wrong value');
}
// @view
// func test_can_split_2{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let user = 'bal7';
//     let token_id = Uint256(1337, 0);
//     let slot = Uint256(SLOT1, 0);
//     let value = Uint256(1 + 2, 0);

//     ERC3525SlotEnumerable._mint(user, token_id, slot, value);
//     local amounts: Uint256* = cast(new (Uint256(1, 0), Uint256(2, 0)), Uint256*);
//     %{
//         stop_prank = start_prank(ids.user) 
//         mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
//         mock_call(ids.user, "supportsInterface", [ids.TRUE])
//     %}
//     let (new_token_ids_len, new_token_ids) = split(token_id, 2, amounts);
//     %{ stop_prank() %}
//     assert_that.ERC3525_balance_of_is(Uint256(2, 0), Uint256(1, 0));
//     assert_that.ERC3525_balance_of_is(token_id, Uint256(2, 0));

//     assert_that.owner_is(Uint256(2, 0), user);
//     assert_that.owner_is(token_id, user);

//     return ();
// }

// @view
// func test_can_split{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let user = 'bal7';
//     let token_id = Uint256(1337, 0);
//     let slot = Uint256(SLOT1, 0);
//     let value = Uint256(1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9 + 10, 0);

//     ERC3525SlotEnumerable._mint(user, token_id, slot, value);
//     local amounts: Uint256* = cast(
//         new (
//             Uint256(1, 0),
//             Uint256(2, 0),
//             Uint256(3, 0),
//             Uint256(4, 0),
//             Uint256(5, 0),
//             Uint256(6, 0),
//             Uint256(7, 0),
//             Uint256(8, 0),
//             Uint256(9, 0),
//             Uint256(10, 0),
//         ),
//         Uint256*,
//     );
//     %{
//         stop_prank = start_prank(ids.user) 
//         mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
//         mock_call(ids.user, "supportsInterface", [ids.TRUE])
//     %}
//     let (new_token_ids_len, new_token_ids) = split(token_id, 10, amounts);
//     %{ stop_prank() %}
//     assert_that.ERC3525_balance_of_is(Uint256(2, 0), Uint256(1, 0));
//     assert_that.ERC3525_balance_of_is(Uint256(3, 0), Uint256(2, 0));
//     assert_that.ERC3525_balance_of_is(Uint256(4, 0), Uint256(3, 0));
//     assert_that.ERC3525_balance_of_is(Uint256(5, 0), Uint256(4, 0));
//     assert_that.ERC3525_balance_of_is(Uint256(6, 0), Uint256(5, 0));
//     assert_that.ERC3525_balance_of_is(Uint256(7, 0), Uint256(6, 0));
//     assert_that.ERC3525_balance_of_is(Uint256(8, 0), Uint256(7, 0));
//     assert_that.ERC3525_balance_of_is(Uint256(9, 0), Uint256(8, 0));
//     assert_that.ERC3525_balance_of_is(Uint256(10, 0), Uint256(9, 0));
//     assert_that.ERC3525_balance_of_is(token_id, Uint256(10, 0));

//     assert_that.owner_is(Uint256(2, 0), user);
//     assert_that.owner_is(Uint256(3, 0), user);
//     assert_that.owner_is(Uint256(4, 0), user);
//     assert_that.owner_is(Uint256(5, 0), user);
//     assert_that.owner_is(Uint256(6, 0), user);
//     assert_that.owner_is(Uint256(7, 0), user);
//     assert_that.owner_is(Uint256(8, 0), user);
//     assert_that.owner_is(Uint256(9, 0), user);
//     assert_that.owner_is(Uint256(10, 0), user);
//     assert_that.owner_is(token_id, user);

//     return ();
// }

// @view
// func test_can_merge{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let user = 'bal7';
//     let slot = Uint256(SLOT1, 0);

//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(1, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(2, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(3, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(4, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(5, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(6, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(7, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(8, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(9, 0));

//     local token_ids: Uint256* = cast(
//         new (
//             Uint256(1, 0),
//             Uint256(2, 0),
//             Uint256(3, 0),
//             Uint256(4, 0),
//             Uint256(5, 0),
//             Uint256(6, 0),
//             Uint256(7, 0),
//             Uint256(8, 0),
//             Uint256(9, 0),
//         ),
//         Uint256*,
//     );
//     %{
//         stop_prank = start_prank(ids.user) 
//         mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
//         mock_call(ids.user, "supportsInterface", [ids.TRUE])
//     %}
//     merge(9, token_ids);
//     %{ stop_prank() %}

//     assert_that.ERC3525_balance_of_is(Uint256(9, 0), Uint256(1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9, 0));

//     assert_that.token_id_is_nonexistent(Uint256(1, 0));
//     assert_that.token_id_is_nonexistent(Uint256(2, 0));
//     assert_that.token_id_is_nonexistent(Uint256(3, 0));
//     assert_that.token_id_is_nonexistent(Uint256(4, 0));
//     assert_that.token_id_is_nonexistent(Uint256(5, 0));
//     assert_that.token_id_is_nonexistent(Uint256(6, 0));
//     assert_that.token_id_is_nonexistent(Uint256(7, 0));
//     assert_that.token_id_is_nonexistent(Uint256(8, 0));
//     assert_that.owner_is(Uint256(9, 0), user);

//     return ();
// }

// @view
// func test_can_merge_2{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let user = 'bal7';
//     let slot = Uint256(SLOT1, 0);

//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(1, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(2, 0));

//     local token_ids: Uint256* = cast(new (Uint256(1, 0), Uint256(2, 0)), Uint256*);
//     %{
//         stop_prank = start_prank(ids.user) 
//         mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
//         mock_call(ids.user, "supportsInterface", [ids.TRUE])
//     %}
//     merge(2, token_ids);
//     %{ stop_prank() %}

//     assert_that.ERC3525_balance_of_is(Uint256(2, 0), Uint256(1 + 2, 0));

//     assert_that.token_id_is_nonexistent(Uint256(1, 0));
//     assert_that.owner_is(Uint256(2, 0), user);

//     return ();
// }

// //
// // Reverts
// //

// @view
// func test_cannot_split_more_than_balance{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
// }() {
//     alloc_locals;
//     let user = 'bal7';
//     let token_id = Uint256(1337, 0);
//     let slot = Uint256(SLOT1, 0);
//     let value = Uint256(1 + 2 + 3 + 4 + 5 + 6 + 7 + 8 + 9, 0);

//     ERC3525SlotEnumerable._mint(user, token_id, slot, value);
//     local amounts: Uint256* = cast(
//         new (
//             Uint256(1, 0),
//             Uint256(2, 0),
//             Uint256(3, 0),
//             Uint256(4, 0),
//             Uint256(5, 0),
//             Uint256(6, 0),
//             Uint256(7, 0),
//             Uint256(8, 0),
//             Uint256(9, 0),
//             Uint256(10, 0),
//         ),
//         Uint256*,
//     );
//     %{
//         stop_prank = start_prank(ids.user) 
//         mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
//         mock_call(ids.user, "supportsInterface", [ids.TRUE])
//         expect_revert(error_message="ERC3525: Split amounts do not sum to balance")
//     %}
//     let (new_token_ids_len, new_token_ids) = split(token_id, 10, amounts);
//     %{ stop_prank() %}

//     return ();
// }

// @view
// func test_cannot_split_1{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let user = 'bal7';
//     let token_id = Uint256(1337, 0);
//     let slot = Uint256(SLOT1, 0);
//     let value = Uint256(1, 0);

//     ERC3525SlotEnumerable._mint(user, token_id, slot, value);
//     local amounts: Uint256* = cast(new (Uint256(1, 0)), Uint256*);
//     %{
//         stop_prank = start_prank(ids.user) 
//         mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
//         mock_call(ids.user, "supportsInterface", [ids.TRUE])
//         expect_revert(error_message="ERC3525: split length too low")
//     %}
//     let (new_token_ids_len, new_token_ids) = split(token_id, 1, amounts);
//     %{ stop_prank() %}

//     return ();
// }

// @view
// func test_cannot_merge_if_not_owner{
//     syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
// }() {
//     alloc_locals;
//     let user = 'bal7';
//     let token_id = Uint256(1337, 0);
//     let slot = Uint256(SLOT1, 0);

//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(1, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(2, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(3, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(4, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(5, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(6, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(7, 0));
//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(8, 0));
//     ERC3525SlotEnumerable._mint_new(USER1, slot, Uint256(9, 0));

//     local token_ids: Uint256* = cast(
//         new (
//             Uint256(1, 0),
//             Uint256(2, 0),
//             Uint256(3, 0),
//             Uint256(4, 0),
//             Uint256(5, 0),
//             Uint256(6, 0),
//             Uint256(7, 0),
//             Uint256(8, 0),
//             Uint256(9, 0),
//         ),
//         Uint256*,
//     );
//     %{
//         stop_prank = start_prank(ids.user) 
//         mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
//         mock_call(ids.user, "supportsInterface", [ids.TRUE])

//         expect_revert(error_message="ERC3525: merge tokens not from owner")
//     %}
//     merge(9, token_ids);
//     %{ stop_prank() %}

//     return ();
// }

// @view
// func test_cannot_merge_1{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let user = 'bal7';
//     let slot = Uint256(SLOT1, 0);

//     ERC3525SlotEnumerable._mint_new(user, slot, Uint256(1, 0));

//     local token_ids: Uint256* = cast(new (Uint256(1, 0)), Uint256*);
//     %{
//         stop_prank = start_prank(ids.user) 
//         mock_call(ids.user, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
//         mock_call(ids.user, "supportsInterface", [ids.TRUE])
//         expect_revert(error_message="ERC3525: merge length too low")
//     %}
//     merge(1, token_ids);
//     %{ stop_prank() %}

//     return ();
// }

