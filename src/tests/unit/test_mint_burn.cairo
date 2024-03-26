// Core imports

use debug::PrintTrait;

// Starknet imports

use starknet::get_contract_address;
use starknet::testing::set_caller_address;

// External imports

use openzeppelin::token::erc721::erc721::ERC721Component::{ ERC721Impl, InternalImpl as ERC721InternalImpl };
use openzeppelin::token::erc721::erc721::ERC721Component;

// Local imports

use cairo_erc_3525::module::ERC3525Component::{ ERC3525Impl, InternalImpl };
use cairo_erc_3525::module::ERC3525Component;
use cairo_erc_3525::tests::utils;
use cairo_erc_3525::tests::unit::constants::{
    ERC3525ComponentState,
    COMPONENT_STATE, CONTRACT_STATE, VALUE_DECIMALS, TOKEN_ID_1, SLOT_1, VALUE, ZERO, OWNER
};

// Settings

fn setup() -> ERC3525ComponentState {
    let mut state = COMPONENT_STATE();
    state.initializer(VALUE_DECIMALS);
    state
}

// Tests approvals

#[test]
#[available_gas(20000000)]
fn test_mint() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);

    let balance = mock_state.balance_of(OWNER());
    assert(balance == 1, 'Wrong balance');
    let slot = state.slot_of(TOKEN_ID_1);
    assert(slot == SLOT_1, 'Wrong slot');
    let owner = mock_state.owner_of(TOKEN_ID_1);
    assert(owner == OWNER(), 'Wrong owner');

    // [Assert] Events
    let event = utils::pop_log::<ERC721Component::Event>(get_contract_address()).unwrap();
    match event {
        ERC721Component::Event::Transfer(event) => {
            assert(event.from == ZERO(), 'Wrong event from');
            assert(event.to == OWNER(), 'Wrong event to');
            assert(event.token_id == TOKEN_ID_1, 'Wrong event token_id');
        },
        _ => panic!("Wrong event type"),
    }
    let event = starknet::testing::pop_log::<ERC3525Component::SlotChanged>(get_contract_address()).unwrap();
    assert(event.token_id == TOKEN_ID_1, 'Wrong event from_token_id');
    assert(event.old_slot == 0, 'Wrong event old_slot');
    assert(event.new_slot == SLOT_1, 'Wrong new_slot value');
    let event = starknet::testing::pop_log::<ERC3525Component::TransferValue>(get_contract_address())
        .unwrap();
    assert(event.from_token_id == 0, 'Wrong event from_token_id');
    assert(event.to_token_id == TOKEN_ID_1, 'Wrong event to_token_id');
    assert(event.value == VALUE, 'Wrong event value');
}

#[test]
#[available_gas(20000000)]
fn test_mint_value_with_previous_balance() {
    let mut state = setup();
    set_caller_address(OWNER());

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._mint_value(TOKEN_ID_1, VALUE);
    let value = state.value_of(TOKEN_ID_1);
    assert(value == 2 * VALUE, 'Wrong value');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token not minted',))]
fn test_mint_value_revert_not_minted() {
    let mut state = setup();
    set_caller_address(OWNER());

    state._mint_value(TOKEN_ID_1, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: invalid token_id',))]
fn test_mint_revert_zero_token_id() {
    let mut state = setup();
    set_caller_address(OWNER());
    let token_id: u256 = 0;

    state._mint(OWNER(), token_id, SLOT_1, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: invalid address',))]
fn test_mint_revert_zero_address() {
    let mut state = setup();
    set_caller_address(OWNER());

    state._mint(ZERO(), TOKEN_ID_1, SLOT_1, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token already minted',))]
fn test_mint_revert_existing_id() {
    let mut state = setup();
    set_caller_address(OWNER());

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token not minted',))]
fn test_burn() {
    let mut state = setup();
    set_caller_address(OWNER());

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._burn(TOKEN_ID_1);

    // [Setup] mint Transfer, SlotChanged and TransferValue events
    let _event = starknet::testing::pop_log::<ERC721Component::Transfer>(get_contract_address()).unwrap();
    let _event = starknet::testing::pop_log::<ERC3525Component::SlotChanged>(get_contract_address()).unwrap();
    let _event = starknet::testing::pop_log::<ERC3525Component::TransferValue>(get_contract_address())
        .unwrap();

    // [Assert] Events
    let event = utils::pop_log::<ERC721Component::Event>(get_contract_address()).unwrap();
    match event {
        ERC721Component::Event::Transfer(event) => {
            assert(event.from == OWNER(), 'Wrong event from');
            assert(event.to == ZERO(), 'Wrong event to');
            assert(event.token_id == TOKEN_ID_1, 'Wrong event token_id');
        },
        _ => panic!("Wrong event type"),
    }
    let event = starknet::testing::pop_log::<ERC3525Component::TransferValue>(get_contract_address())
        .unwrap();
    assert(event.from_token_id == TOKEN_ID_1, 'Wrong event from_token_id');
    assert(event.to_token_id == 0, 'Wrong event to_token_id');
    assert(event.value == VALUE, 'Wrong event value');
    let event = starknet::testing::pop_log::<ERC3525Component::SlotChanged>(get_contract_address()).unwrap();
    assert(event.token_id == TOKEN_ID_1, 'Wrong event from_token_id');
    assert(event.old_slot == SLOT_1, 'Wrong event old_slot');
    assert(event.new_slot == 0, 'Wrong new_slot value');

    // [Assert] Token does not exist anymore
    let _value = state.value_of(TOKEN_ID_1);
}

#[test]
#[available_gas(20000000)]
fn test_burn_value() {
    let mut state = setup();
    set_caller_address(OWNER());

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._burn_value(TOKEN_ID_1, VALUE);

    // [Setup] mint Transfer, SlotChanged and TransferValue events
    let _event = starknet::testing::pop_log::<ERC721Component::Transfer>(get_contract_address()).unwrap();
    let _event = starknet::testing::pop_log::<ERC3525Component::SlotChanged>(get_contract_address()).unwrap();
    let _event = starknet::testing::pop_log::<ERC3525Component::TransferValue>(get_contract_address())
        .unwrap();

    // [Assert] Events
    let event = starknet::testing::pop_log::<ERC3525Component::TransferValue>(get_contract_address())
        .unwrap();
    assert(event.from_token_id == TOKEN_ID_1, 'Wrong event from_token_id');
    assert(event.to_token_id == 0, 'Wrong event to_token_id');
    assert(event.value == VALUE, 'Wrong event value');

    // [Assert] Token value
    let value = state.value_of(TOKEN_ID_1);
    assert(value == 0, 'Wrong value');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token not minted',))]
fn test_burn_revert_not_minted() {
    let mut state = setup();
    set_caller_address(OWNER());

    state._burn(TOKEN_ID_1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: value exceeds balance',))]
fn test_burn_value_revert_exceeds_balance() {
    let mut state = setup();
    set_caller_address(OWNER());

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._burn_value(TOKEN_ID_1, 2 * VALUE);
}
