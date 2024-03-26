// Core imports

use integer::BoundedInt;
use debug::PrintTrait;

// Starknet imports

use starknet::ContractAddress;
use starknet::testing::set_caller_address;

// External imports

use openzeppelin::token::erc721::erc721::ERC721Component::{ ERC721Impl, InternalImpl as ERC721InternalImpl };
use openzeppelin::token::erc721::erc721::ERC721Component;
use openzeppelin::presets::Account;

// Local imports

use cairo_erc_3525::module::ERC3525Component::{ ERC3525Impl, InternalImpl };
use cairo_erc_3525::module::ERC3525Component;
use cairo_erc_3525::extensions::slotenumerable::module::ERC3525SlotEnumerableComponent::{
    ERC3525SlotEnumerableImpl, InternalImpl as ERC3525SlotEnumerableInternalImpl
};
use cairo_erc_3525::extensions::slotenumerable::module::ERC3525SlotEnumerableComponent;
use cairo_erc_3525::tests::unit::constants::{
    ERC3525SlotEnumerableComponentState,
    CONTRACT_STATE, COMPONENT_STATE_SLOT_ENUMERABLE,
    VALUE_DECIMALS, TOKEN_ID_1, TOKEN_ID_2, SLOT_1, SLOT_2, VALUE,
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


fn setup() -> (ERC3525SlotEnumerableComponentState, ContractAddress) {
    let class_hash = Account::TEST_CLASS_HASH.try_into().unwrap();
    let receiver = deploy_account(class_hash, 'RECEIVER');
    let mut state = COMPONENT_STATE_SLOT_ENUMERABLE();
    let mut mock_state = CONTRACT_STATE();
    mock_state.erc3525.initializer(VALUE_DECIMALS);
    state.initializer();
    (state, receiver)
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_slot_count() {
    let (mut state, _) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    state._mint(OWNER(), TOKEN_ID_2, SLOT_2, 0
    );
    let count = state.slot_count();
    assert(count == 2, 'Wrong slot count');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_slot_by_index() {
    let (mut state, _) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._mint(OWNER(), TOKEN_ID_2, SLOT_2, 0);
    let slot = state.slot_by_index(0);
    assert(slot == SLOT_1, 'Wrong slot');
    let slot = state.slot_by_index(1);
    assert(slot == SLOT_2, 'Wrong slot');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: index out of bounds',))]
fn test_slot_enumerable_slot_by_index_revert_out_of_bounds() {
    let (mut state, _) = setup();
    state.slot_by_index(0);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: index out of bounds',))]
fn test_slot_enumerable_slot_by_index_revert_overflow() {
    let (mut state, _) = setup();
    state.slot_by_index(BoundedInt::max()
    );
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot() {
    let (mut state, _) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    state._mint(OWNER(), TOKEN_ID_2, SLOT_2, 0
    );
    let supply = state.token_supply_in_slot(SLOT_1
    );
    assert(supply == 1, 'Wrong token supply');
    let supply = state.token_supply_in_slot(SLOT_2
    );
    assert(supply == 1, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot_is_empty() {
    let (mut state, _) = setup();
    let supply = state.token_supply_in_slot(SLOT_1
    );
    assert(supply == 0, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot_after_transfer() {
    let (mut state, _) = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE
    );
    // ERC721 setup
    mock_state.erc721.transfer_from(OWNER(), SOMEONE(), TOKEN_ID_1);
    // [Assert] Token supply in slot
    let supply = state.token_supply_in_slot(SLOT_1
    );
    assert(supply == 1, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot_after_transfer_to_address() {
    let (mut state, receiver) = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    // [Effect] Transfer value to address
    let new_token_id = mock_state.erc3525.transfer_value_from(
        TOKEN_ID_1, 0, receiver, VALUE
    );
    state._after_transfer_value_from(new_token_id);
    // [Assert] Token supply in slot
    let supply = state.token_supply_in_slot(SLOT_1
    );
    assert(supply == 2, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_supply_in_slot_after_transfer_to_token() {
    let (mut state, receiver) = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._mint(receiver, TOKEN_ID_2, SLOT_1, VALUE);
    // [Effect] Transfer value to address
    mock_state.erc3525.transfer_value_from(TOKEN_ID_1, TOKEN_ID_2, ZERO(), VALUE);
    state._after_transfer_value_from(TOKEN_ID_2);
    // [Assert] Token supply in slot
    let supply = state.token_supply_in_slot(SLOT_1
    );
    assert(supply == 2, 'Wrong token supply');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_in_slot_by_index() {
    let (mut state, receiver) = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._mint(receiver, TOKEN_ID_2, SLOT_2, VALUE);
    // [Assert] Token in slot by index
    let token_id = state.token_in_slot_by_index(SLOT_1, 0);
    assert(token_id == TOKEN_ID_1, 'Wrong token id');
    let token_id = state.token_in_slot_by_index(SLOT_2, 0);
    assert(token_id == TOKEN_ID_2, 'Wrong token id');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: index out of bounds',))]
fn test_slot_enumerable_token_in_slot_by_index_revert_out_of_bounds() {
    let (mut state, _) = setup();
    // [Assert] Token in slot by index
    state.token_in_slot_by_index(SLOT_1, 0);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: index out of bounds',))]
fn test_slot_enumerable_token_in_slot_by_index_revert_overflow() {
    let (mut state, _) = setup();
    // [Assert] Token in slot by index
    state.token_in_slot_by_index(SLOT_1, BoundedInt::max()
    );
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_in_slot_by_index_after_transfer() {
    let (mut state, _) = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    // ERC721 setup
    mock_state.erc721.transfer_from(OWNER(), SOMEONE(), TOKEN_ID_1);
    // [Assert] Token in slot by index
    let token_id = state.token_in_slot_by_index(SLOT_1, 0
    );
    assert(token_id == TOKEN_ID_1, 'Wrong token id');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_in_slot_by_index_after_transfer_to_address() {
    let (mut state, receiver) = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    // [Effect] Transfer value to address
    let new_token_id = mock_state.erc3525.transfer_value_from(
        TOKEN_ID_1, 0, receiver, VALUE
    );
    state._after_transfer_value_from(new_token_id);
    // [Assert] Token in slot by index
    let token_id = state.token_in_slot_by_index(SLOT_1, 0);
    assert(token_id == TOKEN_ID_1, 'Wrong token id');
}

#[test]
#[available_gas(20000000)]
fn test_slot_enumerable_token_in_slot_by_index_after_transfer_to_token() {
    let (mut state, receiver) = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._mint(receiver, TOKEN_ID_2, SLOT_1, VALUE);
    // [Effect] Transfer value to address
    mock_state.erc3525.transfer_value_from(TOKEN_ID_1, TOKEN_ID_2, ZERO(), VALUE);
    state._after_transfer_value_from(TOKEN_ID_2);
    // [Assert] Token in slot by index
    let token_id = state.token_in_slot_by_index(SLOT_1, 0);
    assert(token_id == TOKEN_ID_1, 'Wrong token id');
}
