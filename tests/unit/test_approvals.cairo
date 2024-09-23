// Starknet imports
use starknet::testing::set_caller_address;

// snforge deps
use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address,
    test_address,
};

// External imports
use openzeppelin::token::erc721::erc721::ERC721Component::ERC721Impl;
use openzeppelin::token::erc721::erc721::ERC721Component;

// Local imports
use cairo_erc_3525::module::ERC3525Component::{ERC3525Impl, InternalImpl};
use cairo_erc_3525::module::ERC3525Component;
use super::constants::{
    ERC3525ComponentState, COMPONENT_STATE, CONTRACT_STATE, VALUE_DECIMALS, TOKEN_ID_1,
    INVALID_TOKEN, SLOT_1, VALUE, ZERO, OWNER, OPERATOR, SOMEONE, ANYONE
};

// Settings
fn setup() -> ERC3525ComponentState {
    let mut state = COMPONENT_STATE();
    state.initializer(VALUE_DECIMALS);
    state._mint(OWNER(), TOKEN_ID_1, SLOT_1, 1 * VALUE);
    state
}

// Tests approvals

#[test]
#[available_gas(20000000)]
fn test_owner_can_approve_operator_value() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    let allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    assert(allowance == 0, 'Wrong allowance');
    mock_state.erc721.approve(OWNER(), TOKEN_ID_1);
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
    stop_cheat_caller_address(OWNER());
}

#[test]
#[available_gas(20000000)]
fn test_owner_can_approve_more_to_same() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    mock_state.erc721.approve(OWNER(), TOKEN_ID_1);
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    state.approve_value(TOKEN_ID_1, OPERATOR(), 2 * VALUE);
    let allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    assert(allowance == 2 * VALUE, 'Wrong allowance');
    stop_cheat_caller_address(OWNER());
}

#[test]
#[available_gas(20000000)]
fn test_owner_can_approve_less_to_same() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    mock_state.erc721.approve(OWNER(), TOKEN_ID_1);
    state.approve_value(TOKEN_ID_1, OPERATOR(), 2 * VALUE);
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
    stop_cheat_caller_address(OWNER());
}

#[test]
#[available_gas(20000000)]
fn test_owner_can_approve_someone_else() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    mock_state.erc721.approve(OWNER(), TOKEN_ID_1);
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
    state.approve_value(TOKEN_ID_1, SOMEONE(), 2 * VALUE);
    let allowance = state.allowance(TOKEN_ID_1, SOMEONE());
    assert(allowance == 2 * VALUE, 'Wrong allowance');
    stop_cheat_caller_address(OWNER());
}

#[test]
#[available_gas(20000000)]
fn test_721approved_for_all_can_approve_value() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    // ERC721 setup
    mock_state.erc721.set_approval_for_all(SOMEONE(), true);
    mock_state.erc721.approve(SOMEONE(), TOKEN_ID_1);
    stop_cheat_caller_address(OWNER());
    // ERC3525 test
    start_cheat_caller_address(test_address(), SOMEONE());
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
    stop_cheat_caller_address(SOMEONE());
}

#[test]
#[available_gas(20000000)]
fn test_721approved_can_approve_value() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    // ERC721 setup
    mock_state.erc721.approve(SOMEONE(), TOKEN_ID_1);
    stop_cheat_caller_address(OWNER());
    // ERC3525 test
    start_cheat_caller_address(test_address(), SOMEONE());
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = state.allowance(TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
    stop_cheat_caller_address(SOMEONE());
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_cannot_approve_value_to_zero_address() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());
    // ERC3525 test
    state.approve_value(TOKEN_ID_1, ZERO(), VALUE);
    stop_cheat_caller_address(OWNER());
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_cannot_approve_value_to_self() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());
    // ERC3525 test
    state.approve_value(TOKEN_ID_1, OWNER(), VALUE);
    stop_cheat_caller_address(OWNER());
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_anyone_cannot_approve_value() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), ANYONE());
    // ERC3525 test
    state.approve_value(TOKEN_ID_1, ANYONE(), VALUE);
    stop_cheat_caller_address(ANYONE());
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_cannot_approve_value_nonexistent_token_id() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());
    // ERC3525 test
    state.approve_value(INVALID_TOKEN, OPERATOR(), VALUE);
    stop_cheat_caller_address(OWNER());
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_zero_address_cannot_approve_value() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), ZERO());
    // ERC3525 test
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    stop_cheat_caller_address(ZERO());
}

