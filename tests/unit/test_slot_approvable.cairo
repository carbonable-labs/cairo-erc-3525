// Core imports
use debug::PrintTrait;

// snforge deps
use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address,
    test_address, spy_events, EventSpyAssertionsTrait
};

// External imports
use openzeppelin::token::erc721::ERC721Component;

// Local imports
use cairo_erc_3525::module::ERC3525Component::{InternalTrait, ERC3525Impl};
use cairo_erc_3525::module::ERC3525Component;
use cairo_erc_3525::extensions::slotapprovable::module::ERC3525SlotApprovableComponent::{
    ERC3525SlotApprovableImpl, InternalTrait as ERC3525SlotApprovableInternalTrait,
    ExternalTrait as ERC3525SlotApprovableExternalTrait
};
use cairo_erc_3525::extensions::slotapprovable::module::ERC3525SlotApprovableComponent;
use super::constants::{
    ERC3525SlotApprovableComponentState, CONTRACT_STATE, COMPONENT_STATE_SLOT_APPROVABLE,
    VALUE_DECIMALS, TOKEN_ID_1, TOKEN_ID_2, SLOT_1, SLOT_2, VALUE, ZERO, OWNER, OPERATOR, SOMEONE
};

// Settings

fn setup() -> ERC3525SlotApprovableComponentState {
    let mut state = COMPONENT_STATE_SLOT_APPROVABLE();
    let mut mock_state = CONTRACT_STATE();
    mock_state.erc3525.initializer(VALUE_DECIMALS);
    state.initializer();
    state
}
// fn setup() -> (ERC3525::ContractState, ERC3525SlotApprovable::ContractState) {
//     let mut state = STATE();
//     mock_state.initializer(VALUE_DECIMALS);
//     let mut state_slot_approvable = STATE_SLOT_APPROVABLE();
//     state.initializer(ref state_slot_approvable);
//     (state, state_slot_approvable)
// }

// Tests approvals
#[test]
#[available_gas(20000000)]
fn test_slot_approvable_owner_can_approve_slot() {
    let mut state = setup();
    start_cheat_caller_address(test_address(), OWNER());
    state.set_approval_for_slot(OWNER(), SLOT_1, OPERATOR(), true);
    stop_cheat_caller_address(OWNER());
}

#[test]
#[available_gas(20000000)]
fn test_slot_approvable_operator_can_approve_value() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    mock_state.erc3525._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state.set_approval_for_slot(OWNER(), SLOT_1, OPERATOR(), true);
    stop_cheat_caller_address(OWNER());
    start_cheat_caller_address(test_address(), OPERATOR());
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    stop_cheat_caller_address(OPERATOR());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: caller not allowed',))]
fn test_slot_approvable_operator_cannot_approve_any_token() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    mock_state.erc3525._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state.set_approval_for_slot(OWNER(), SLOT_2, OPERATOR(), true);
    stop_cheat_caller_address(OWNER());
    start_cheat_caller_address(test_address(), OPERATOR());
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    stop_cheat_caller_address(OPERATOR());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: insufficient allowance',))]
fn test_slot_approvable_operator_cannot_transfer_anyones_value() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    mock_state.erc3525._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    mock_state.erc3525._mint(SOMEONE(), TOKEN_ID_2, SLOT_1, VALUE);
    state.set_approval_for_slot(OWNER(), SLOT_1, OPERATOR(), true);
    stop_cheat_caller_address(OWNER());
    start_cheat_caller_address(test_address(), OPERATOR());
    state.transfer_value_from(TOKEN_ID_2, 0, OPERATOR(), VALUE);
    stop_cheat_caller_address(OPERATOR());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: slot mismatch',))]
fn test_slot_approvable_operator_transfer_value_revert_slot_mismatch() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    mock_state.erc3525._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    mock_state.erc3525._mint(SOMEONE(), TOKEN_ID_2, SLOT_2, VALUE);
    state.set_approval_for_slot(OWNER(), SLOT_1, OPERATOR(), true);
    stop_cheat_caller_address(OWNER());
    start_cheat_caller_address(test_address(), OPERATOR());
    state.transfer_value_from(TOKEN_ID_1, TOKEN_ID_2, ZERO(), VALUE);
    stop_cheat_caller_address(OPERATOR());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: caller not allowed',))]
fn test_slot_approvable_revoked_slot_operator_cannot_approve() {
    let mut state = setup();
    let mut mock_state = CONTRACT_STATE();
    start_cheat_caller_address(test_address(), OWNER());
    mock_state.erc3525._mint(OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    state.set_approval_for_slot(OWNER(), SLOT_1, OPERATOR(), true);
    state.set_approval_for_slot(OWNER(), SLOT_1, OPERATOR(), false);
    stop_cheat_caller_address(OWNER());
    start_cheat_caller_address(test_address(), OPERATOR());
    state.approve_value(TOKEN_ID_1, OPERATOR(), VALUE);
    stop_cheat_caller_address(OPERATOR());
}
