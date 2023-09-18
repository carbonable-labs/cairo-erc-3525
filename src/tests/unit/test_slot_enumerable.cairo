// Core imports

use integer::BoundedInt;
use debug::PrintTrait;

// Starknet imports

use starknet::ContractAddress;
use starknet::testing::set_caller_address;

// External imports

use openzeppelin::token::erc721::erc721::ERC721;

// Local imports

use cairo_erc_3525::tests::mocks::account::Account;
use cairo_erc_3525::module::ERC3525;
use cairo_erc_3525::extensions::slotenumerable::module::ERC3525SlotEnumerable;
use cairo_erc_3525::tests::unit::constants::{
    STATE, STATE_SLOT_ENUMERABLE, VALUE_DECIMALS, TOKEN_ID_1, TOKEN_ID_2, SLOT_1, SLOT_2, VALUE,
    ZERO, OWNER, SOMEONE
};

// Settings

fn deploy_account(
    class_hash: starknet::class_hash::ClassHash, public_key: felt252
) -> ContractAddress {
    let calldata: Array<felt252> = array![public_key];
    let (address, _) = starknet::deploy_syscall(class_hash, 0, calldata.span(), false).unwrap();
    address
}


fn setup() -> (ERC3525::ContractState, ERC3525SlotEnumerable::ContractState, ContractAddress) {
    let class_hash = Account::TEST_CLASS_HASH.try_into().unwrap();
    let receiver = deploy_account(class_hash, 'RECEIVER');
    let mut state = STATE();
    ERC3525::InternalImpl::initializer(ref state, VALUE_DECIMALS);
    let mut state_slot_enumerable = STATE_SLOT_ENUMERABLE();
    ERC3525SlotEnumerable::InternalImpl::initializer(ref state_slot_enumerable);
    (state, state_slot_enumerable, receiver)
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_slot_count() {
    let (mut state, mut state_slot_enumerable, _) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_2, SLOT_2, 0
    );
    let count = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::slot_count(
        @state_slot_enumerable
    );
    assert(count == 2, 'Wrong slot count');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_slot_by_index() {
    let (mut state, mut state_slot_enumerable, _) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_2, SLOT_2, 0
    );
    let slot = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::slot_by_index(
        @state_slot_enumerable, 0
    );
    assert(slot == SLOT_1, 'Wrong slot');
    let slot = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::slot_by_index(
        @state_slot_enumerable, 1
    );
    assert(slot == SLOT_2, 'Wrong slot');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: index out of bounds',))]
fn test_slot_enumerable_slot_by_index_revert_out_of_bounds() {
    let (mut state, mut state_slot_enumerable, _) = setup();
    ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::slot_by_index(@state_slot_enumerable, 0);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: index out of bounds',))]
fn test_slot_enumerable_slot_by_index_revert_overflow() {
    let (mut state, mut state_slot_enumerable, _) = setup();
    ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::slot_by_index(
        @state_slot_enumerable, BoundedInt::max()
    );
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot() {
    let (mut state, mut state_slot_enumerable, _) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_2, SLOT_2, 0
    );
    let supply = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_supply_in_slot(
        @state_slot_enumerable, SLOT_1
    );
    assert(supply == 1, 'Wrong token supply');
    let supply = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_supply_in_slot(
        @state_slot_enumerable, SLOT_2
    );
    assert(supply == 1, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot_is_empty() {
    let (mut state, mut state_slot_enumerable, _) = setup();
    let supply = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_supply_in_slot(
        @state_slot_enumerable, SLOT_1
    );
    assert(supply == 0, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot_after_transfer() {
    let (mut state, mut state_slot_enumerable, _) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    // ERC721 setup
    let mut erc721_state = ERC721::unsafe_new_contract_state();
    ERC721::ERC721Impl::transfer_from(ref erc721_state, OWNER(), SOMEONE(), TOKEN_ID_1);
    // [Assert] Token supply in slot
    let supply = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_supply_in_slot(
        @state_slot_enumerable, SLOT_1
    );
    assert(supply == 1, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot_after_transfer_to_address() {
    let (mut state, mut state_slot_enumerable, receiver) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    // [Effect] Transfer value to address
    let new_token_id = ERC3525::ERC3525Impl::transfer_value_from(
        ref state, TOKEN_ID_1, 0, receiver, VALUE
    );
    ERC3525SlotEnumerable::InternalImpl::_after_transfer_value_from(
        ref state_slot_enumerable, new_token_id
    );
    // [Assert] Token supply in slot
    let supply = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_supply_in_slot(
        @state_slot_enumerable, SLOT_1
    );
    assert(supply == 2, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot_after_transfer_to_token() {
    let (mut state, mut state_slot_enumerable, receiver) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, receiver, TOKEN_ID_2, SLOT_1, VALUE
    );
    // [Effect] Transfer value to address
    ERC3525::ERC3525Impl::transfer_value_from(ref state, TOKEN_ID_1, TOKEN_ID_2, ZERO(), VALUE);
    ERC3525SlotEnumerable::InternalImpl::_after_transfer_value_from(
        ref state_slot_enumerable, TOKEN_ID_2
    );
    // [Assert] Token supply in slot
    let supply = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_supply_in_slot(
        @state_slot_enumerable, SLOT_1
    );
    assert(supply == 2, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_in_slot_by_index() {
    let (mut state, mut state_slot_enumerable, receiver) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, receiver, TOKEN_ID_2, SLOT_2, VALUE
    );
    // [Assert] Token in slot by index
    let token_id = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_in_slot_by_index(
        @state_slot_enumerable, SLOT_1, 0
    );
    assert(token_id == TOKEN_ID_1, 'Wrong token id');
    let token_id = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_in_slot_by_index(
        @state_slot_enumerable, SLOT_2, 0
    );
    assert(token_id == TOKEN_ID_2, 'Wrong token id');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: index out of bounds',))]
fn test_slot_enumerable_token_in_slot_by_index_revert_out_of_bounds() {
    let (mut state, mut state_slot_enumerable, receiver) = setup();
    // [Assert] Token in slot by index
    ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_in_slot_by_index(
        @state_slot_enumerable, SLOT_1, 0
    );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: index out of bounds',))]
fn test_slot_enumerable_token_in_slot_by_index_revert_overflow() {
    let (mut state, mut state_slot_enumerable, receiver) = setup();
    // [Assert] Token in slot by index
    ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_in_slot_by_index(
        @state_slot_enumerable, SLOT_1, BoundedInt::max()
    );
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_in_slot_by_index_after_transfer() {
    let (mut state, mut state_slot_enumerable, _) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    // ERC721 setup
    let mut erc721_state = ERC721::unsafe_new_contract_state();
    ERC721::ERC721Impl::transfer_from(ref erc721_state, OWNER(), SOMEONE(), TOKEN_ID_1);
    // [Assert] Token in slot by index
    let token_id = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_in_slot_by_index(
        @state_slot_enumerable, SLOT_1, 0
    );
    assert(token_id == TOKEN_ID_1, 'Wrong token id');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_in_slot_by_index_after_transfer_to_address() {
    let (mut state, mut state_slot_enumerable, receiver) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    // [Effect] Transfer value to address
    let new_token_id = ERC3525::ERC3525Impl::transfer_value_from(
        ref state, TOKEN_ID_1, 0, receiver, VALUE
    );
    ERC3525SlotEnumerable::InternalImpl::_after_transfer_value_from(
        ref state_slot_enumerable, new_token_id
    );
    // [Assert] Token in slot by index
    let token_id = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_in_slot_by_index(
        @state_slot_enumerable, SLOT_1, 0
    );
    assert(token_id == TOKEN_ID_1, 'Wrong token id');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_in_slot_by_index_after_transfer_to_token() {
    let (mut state, mut state_slot_enumerable, receiver) = setup();
    set_caller_address(OWNER());
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    ERC3525SlotEnumerable::InternalImpl::_mint(
        ref state_slot_enumerable, receiver, TOKEN_ID_2, SLOT_1, VALUE
    );
    // [Effect] Transfer value to address
    ERC3525::ERC3525Impl::transfer_value_from(ref state, TOKEN_ID_1, TOKEN_ID_2, ZERO(), VALUE);
    ERC3525SlotEnumerable::InternalImpl::_after_transfer_value_from(
        ref state_slot_enumerable, TOKEN_ID_2
    );
    // [Assert] Token in slot by index
    let token_id = ERC3525SlotEnumerable::ERC3525SlotEnumerableImpl::token_in_slot_by_index(
        @state_slot_enumerable, SLOT_1, 0
    );
    assert(token_id == TOKEN_ID_1, 'Wrong token id');
}
