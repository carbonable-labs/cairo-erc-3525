// Core imports

use integer::BoundedInt;
use debug::PrintTrait;

// Starknet imports

use starknet::ContractAddress;
use starknet::testing::set_caller_address;

// External imports

use openzeppelin::token::erc721::erc721::ERC721Component::{ ERC721Impl, InternalImpl as ERC721InternalImpl };
use openzeppelin::token::erc721::erc721::ERC721Component;

// Local imports

use cairo_erc_3525::tests::mocks::account::Account;
use cairo_erc_3525::module::ERC3525Component::{ ERC3525Impl, InternalImpl };
use cairo_erc_3525::module::ERC3525Component;
use cairo_erc_3525::tests::unit::constants::{
    ERC3525ComponentState,
    COMPONENT_STATE, CONTRACT_STATE, VALUE_DECIMALS, TOKEN_ID_1, TOKEN_ID_2, SLOT_1, VALUE, ZERO, OWNER, OPERATOR
};

// Settings

fn deploy_account(
    class_hash: starknet::class_hash::ClassHash, public_key: felt252
) -> ContractAddress {
    let calldata: Array<felt252> = array![public_key];
    let (address, _) = starknet::deploy_syscall(class_hash, 0, calldata.span(), false).unwrap();
    address
}

fn setup() -> (ERC3525ComponentState, ContractAddress) {
    let mut state = COMPONENT_STATE();
    let class_hash = Account::TEST_CLASS_HASH.try_into().unwrap();
    let receiver = deploy_account(class_hash, 'RECEIVER');
    state.initializer(VALUE_DECIMALS);
    (state, receiver)
}

#[test]
#[available_gas(20000000)]
fn test_transfer_to_address() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state.transfer_value_from(TOKEN_ID_1, 0, receiver, VALUE);
}

#[test]
#[available_gas(20000000)]
fn test_transfer_to_address_approved_can_transfer() {
    let (mut state, receiver) = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    // ERC721 setup
    mock_state.erc721.approve(OPERATOR(), TOKEN_ID_1);
    // ERC3525 
    set_caller_address(OPERATOR());
    state.transfer_value_from(TOKEN_ID_1, 0, receiver, VALUE);
}

#[test]
#[available_gas(20000000)]
fn test_transfer_to_address_value_approved_can_transfer() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, 2 * VALUE);
    state.approve_value(TOKEN_ID_1, OPERATOR(), 2 * VALUE);
    // // ERC3525
    let initial_allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    set_caller_address(OPERATOR());
    state.transfer_value_from(TOKEN_ID_1, 0, receiver, VALUE);
    let final_allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    assert(initial_allowance == VALUE + final_allowance, 'Wrong allowance');
}

#[test]
#[available_gas(20000000)]
fn test_transfer_to_address_unlimited_value_approved_can_transfer() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state.approve_value(TOKEN_ID_1, OPERATOR(), BoundedInt::max());
    // // ERC3525
    set_caller_address(OPERATOR());
    state.transfer_value_from(TOKEN_ID_1, 0, receiver, VALUE);
    let final_allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    assert(final_allowance == BoundedInt::max(), 'Wrong allowance');
}

#[test]
#[available_gas(20000000)]
fn test_transfer_to_address_approved_for_all_can_transfer() {
    let (mut state, receiver) = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    // ERC721 setup
    mock_state.erc721.set_approval_for_all(OPERATOR(), true);
    // // ERC3525
    set_caller_address(OPERATOR());
    state.transfer_value_from(TOKEN_ID_1, 0, receiver, VALUE);
}

#[test]
#[available_gas(20000000)]
fn test_transfer_to_address_owner_can_transfer_value_to_himself() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(receiver, TOKEN_ID_1, SLOT_1, VALUE);
    // // ERC3525
    set_caller_address(receiver);
    state.transfer_value_from(TOKEN_ID_1, 0, receiver, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: insufficient allowance',))]
fn test_transfer_to_address_not_approved_cannot_transfer_value() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    // // ERC3525
    set_caller_address(OPERATOR());
    state.transfer_value_from(TOKEN_ID_1, 0, receiver, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: value exceeds balance',))]
fn test_transfer_to_address_revert_value_exceeds_balance() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    // // ERC3525
    state.transfer_value_from(TOKEN_ID_1, 0, receiver, VALUE + 1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: insufficient allowance',))]
fn test_transfer_to_address_revert_insufficient_allowance() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE - 1);
    // // ERC3525
    set_caller_address(OPERATOR());
    state.transfer_value_from(TOKEN_ID_1, 0, receiver, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: invalid from token id',))]
fn test_transfer_to_address_revert_invalid_from_token_id() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state.transfer_value_from(0, 0, receiver, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: mutually excl args set',))]
fn test_transfer_to_address_revert_both_unset() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state.transfer_value_from(TOKEN_ID_1, 0, ZERO(), VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: mutually excl args set',))]
fn test_transfer_to_address_revert_both_set() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state.transfer_value_from(TOKEN_ID_1, TOKEN_ID_2, receiver, VALUE);
}
