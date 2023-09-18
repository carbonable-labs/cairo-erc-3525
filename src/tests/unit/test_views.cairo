// Core imports

use integer::BoundedInt;
use debug::PrintTrait;

// Starknet imports

use starknet::ContractAddress;
use starknet::testing::set_caller_address;

// External imports

use openzeppelin::token::erc721::erc721::ERC721;

// Local imports

use cairo_erc_3525::module::ERC3525;
use cairo_erc_3525::tests::unit::constants::{
    STATE, VALUE_DECIMALS, TOKEN_ID_1, TOKEN_ID_2, SLOT_1, SLOT_2, VALUE, OWNER
};

// Settings

fn setup() -> ERC3525::ContractState {
    let mut state = STATE();
    ERC3525::InternalImpl::initializer(ref state, VALUE_DECIMALS);
    state
}

#[test]
#[available_gas(20000000)]
fn test_value_of() {
    let mut state = setup();
    set_caller_address(OWNER());
    ERC3525::InternalImpl::_mint(ref state, OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    let value = ERC3525::ERC3525Impl::value_of(@state, TOKEN_ID_1);
    assert(value == VALUE, 'Wrong value');
    // ERC721 setup
    let erc721_state = ERC721::unsafe_new_contract_state();
    let balance = ERC721::ERC721Impl::balance_of(@erc721_state, OWNER());
    assert(balance == 1, 'Wrong balance');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token not minted',))]
fn test_value_of_revert_token_not_minted() {
    let mut state = setup();
    ERC3525::ERC3525Impl::value_of(@state, TOKEN_ID_1);
}

#[test]
#[available_gas(20000000)]
fn test_slot_of() {
    let mut state = setup();
    set_caller_address(OWNER());
    ERC3525::InternalImpl::_mint(ref state, OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    let slot = ERC3525::ERC3525Impl::slot_of(@state, TOKEN_ID_1);
    assert(slot == SLOT_1, 'Wrong slot');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token not minted',))]
fn test_slot_of_revert_token_not_minted() {
    let mut state = setup();
    set_caller_address(OWNER());
    ERC3525::ERC3525Impl::slot_of(@state, TOKEN_ID_1);
}

#[test]
#[available_gas(20000000)]
fn test_total_value() {
    let mut state = setup();
    set_caller_address(OWNER());
    ERC3525::InternalImpl::_mint(ref state, OWNER(), 1, SLOT_1, 1 * VALUE);
    ERC3525::InternalImpl::_mint(ref state, OWNER(), 2, SLOT_1, 2 * VALUE);
    ERC3525::InternalImpl::_mint(ref state, OWNER(), 3, SLOT_2, 3 * VALUE);
    ERC3525::InternalImpl::_mint(ref state, OWNER(), 4, SLOT_2, 4 * VALUE);
    assert(ERC3525::InternalImpl::_total_value(@state, SLOT_1) == 3 * VALUE, 'Wrong total value');
    assert(ERC3525::InternalImpl::_total_value(@state, SLOT_2) == 7 * VALUE, 'Wrong total value');
}
