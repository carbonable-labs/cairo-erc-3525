// Core imports

use integer::BoundedInt;
use debug::PrintTrait;

// Starknet imports

use starknet::ContractAddress;
use starknet::testing::set_caller_address;

// External imports

use openzeppelin::token::erc721::erc721::ERC721Component::{
    ERC721Impl, InternalImpl as ERC721InternalImpl
};
use openzeppelin::token::erc721::erc721::ERC721Component;

// Local imports

use cairo_erc_3525::module::ERC3525Component::{ERC3525Impl, InternalImpl};
use cairo_erc_3525::module::ERC3525Component;
use cairo_erc_3525::tests::unit::constants::{
    ERC3525ComponentState, COMPONENT_STATE, CONTRACT_STATE, VALUE_DECIMALS, TOKEN_ID_1, TOKEN_ID_2,
    SLOT_1, SLOT_2, VALUE, OWNER
};

// Settings

fn setup() -> ERC3525ComponentState {
    let mut state = COMPONENT_STATE();
    state.initializer(VALUE_DECIMALS);
    state
}

#[test]
#[available_gas(20000000)]
fn test_value_of() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    let value = state.value_of(TOKEN_ID_1);
    assert(value == VALUE, 'Wrong value');
    // ERC721 setup
    let balance = mock_state.balance_of(OWNER());
    assert(balance == 1, 'Wrong balance');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token not minted',))]
fn test_value_of_revert_token_not_minted() {
    let mut state = setup();
    state.value_of(TOKEN_ID_1);
}

#[test]
#[available_gas(20000000)]
fn test_slot_of() {
    let mut state = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    let slot = state.slot_of(TOKEN_ID_1);
    assert(slot == SLOT_1, 'Wrong slot');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token not minted',))]
fn test_slot_of_revert_token_not_minted() {
    let mut state = setup();
    set_caller_address(OWNER());
    state.slot_of(TOKEN_ID_1);
}

#[test]
#[available_gas(20000000)]
fn test_total_value() {
    let mut state = setup();
    set_caller_address(OWNER());
    state._mint(OWNER(), 1, SLOT_1, 1 * VALUE);
    state._mint(OWNER(), 2, SLOT_1, 2 * VALUE);
    state._mint(OWNER(), 3, SLOT_2, 3 * VALUE);
    state._mint(OWNER(), 4, SLOT_2, 4 * VALUE);
    assert(state._total_value(SLOT_1) == 3 * VALUE, 'Wrong total value');
    assert(state._total_value(SLOT_2) == 7 * VALUE, 'Wrong total value');
}
