// Core imports
use debug::PrintTrait;

// Starknet imports
use starknet::get_contract_address;

// snforge deps
use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address,
    test_address, spy_events, EventSpyAssertionsTrait
};

// External imports
use openzeppelin::token::erc721::ERC721Component::{ERC721Impl, InternalImpl as ERC721InternalImpl};
use openzeppelin::token::erc721::ERC721Component;

// Local imports
use cairo_erc_3525::module::ERC3525Component::{ERC3525Impl, InternalImpl};
use cairo_erc_3525::module::ERC3525Component;
use cairo_erc_3525::test_helpers::utils;
use super::constants::{
    ERC3525ComponentState, COMPONENT_STATE, CONTRACT_STATE, VALUE_DECIMALS, TOKEN_ID_1, SLOT_1,
    VALUE, ZERO, OWNER
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
    start_cheat_caller_address(test_address(), OWNER());

    let mut spy = spy_events();

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);

    let balance = mock_state.balance_of(OWNER());
    assert(balance == 1, 'Wrong balance');
    let slot = state.slot_of(TOKEN_ID_1);
    assert(slot == SLOT_1, 'Wrong slot');
    let owner = mock_state.owner_of(TOKEN_ID_1);
    assert(owner == OWNER(), 'Wrong owner');

    spy
        .assert_emitted(
            @array![
                (
                    test_address(),
                    ERC721Component::Event::Transfer(
                        ERC721Component::Transfer {
                            from: ZERO(), to: OWNER(), token_id: TOKEN_ID_1
                        }
                    )
                ),
            ]
        );

    spy
        .assert_emitted(
            @array![
                (
                    test_address(),
                    ERC3525Component::Event::TransferValue(
                        ERC3525Component::TransferValue {
                            from_token_id: 0, to_token_id: TOKEN_ID_1, value: VALUE
                        }
                    )
                )
            ]
        );
}

#[test]
#[available_gas(20000000)]
fn test_mint_value_with_previous_balance() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());

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
    start_cheat_caller_address(test_address(), OWNER());

    state._mint_value(TOKEN_ID_1, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: invalid token_id',))]
fn test_mint_revert_zero_token_id() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());
    let token_id: u256 = 0;

    state._mint(OWNER(), token_id, SLOT_1, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: invalid address',))]
fn test_mint_revert_zero_address() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());

    state._mint(ZERO(), TOKEN_ID_1, SLOT_1, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token already minted',))]
fn test_mint_revert_existing_id() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token not minted',))]
fn test_burn() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());

    let mut spy = spy_events();

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._burn(TOKEN_ID_1);

    spy
        .assert_emitted(
            @array![
                (
                    test_address(),
                    ERC721Component::Event::Transfer(
                        ERC721Component::Transfer {
                            from: OWNER(), to: ZERO(), token_id: TOKEN_ID_1
                        }
                    )
                ),
            ]
        );

    spy
        .assert_emitted(
            @array![
                (
                    test_address(),
                    ERC3525Component::Event::SlotChanged(
                        ERC3525Component::SlotChanged {
                            token_id: TOKEN_ID_1, old_slot: SLOT_1, new_slot: 0
                        }
                    )
                )
            ]
        );

    spy
        .assert_emitted(
            @array![
                (
                    test_address(),
                    ERC3525Component::Event::TransferValue(
                        ERC3525Component::TransferValue {
                            from_token_id: TOKEN_ID_1, to_token_id: 0, value: VALUE
                        }
                    )
                )
            ]
        );

    let _value = state.value_of(TOKEN_ID_1);
}

#[test]
#[available_gas(20000000)]
fn test_burn_value() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());

    let mut spy = spy_events();

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._burn_value(TOKEN_ID_1, VALUE);

    spy
        .assert_emitted(
            @array![
                (
                    test_address(),
                    ERC3525Component::Event::TransferValue(
                        ERC3525Component::TransferValue {
                            from_token_id: TOKEN_ID_1, to_token_id: 0, value: VALUE
                        }
                    )
                )
            ]
        );

    // [Assert] Token value
    let value = state.value_of(TOKEN_ID_1);
    assert(value == 0, 'Wrong value');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: token not minted',))]
fn test_burn_revert_not_minted() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());

    state._burn(TOKEN_ID_1);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: value exceeds balance',))]
fn test_burn_value_revert_exceeds_balance() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());

    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state._burn_value(TOKEN_ID_1, 2 * VALUE);
}
