// Core imports

use debug::PrintTrait;

// Starknet imports

use starknet::testing::set_caller_address;

// External imports

use openzeppelin::token::erc721::erc721::ERC721;

// Local imports

use cairo_erc_3525::module::ERC3525;
use cairo_erc_3525::extensions::slotapprovable::module::ERC3525SlotApprovable;
use cairo_erc_3525::tests::unit::constants::{
    STATE, STATE_SLOT_APPROVABLE, VALUE_DECIMALS, TOKEN_ID_1, TOKEN_ID_2, SLOT_1, SLOT_2, VALUE,
    ZERO, OWNER, OPERATOR, SOMEONE
};

// Settings

fn setup() -> (ERC3525::ContractState, ERC3525SlotApprovable::ContractState) {
    let mut state = STATE();
    ERC3525::InternalImpl::initializer(ref state, VALUE_DECIMALS);
    let mut state_slot_approvable = STATE_SLOT_APPROVABLE();
    ERC3525SlotApprovable::InternalImpl::initializer(ref state_slot_approvable);
    (state, state_slot_approvable)
}

// Tests approvals

#[test]
#[available_gas(20000000)]
fn test_slot_approvable_owner_can_approve_slot() {
    let (mut state, mut state_slot_approvable) = setup();
    set_caller_address(OWNER());
    ERC3525SlotApprovable::ERC3525SlotApprovableImpl::set_approval_for_slot(
        ref state_slot_approvable, OWNER(), SLOT_1, OPERATOR(), true
    );
}

#[test]
#[available_gas(20000000)]
fn test_slot_approvable_operator_can_approve_value() {
    let (mut state, mut state_slot_approvable) = setup();
    set_caller_address(OWNER());
    ERC3525::InternalImpl::_mint(ref state, OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    ERC3525SlotApprovable::ERC3525SlotApprovableImpl::set_approval_for_slot(
        ref state_slot_approvable, OWNER(), SLOT_1, OPERATOR(), true
    );
    set_caller_address(OPERATOR());
    ERC3525SlotApprovable::ExternalImpl::approve_value(
        ref state_slot_approvable, TOKEN_ID_1, OPERATOR(), VALUE
    );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: caller not allowed',))]
fn test_slot_approvable_operator_cannot_approve_any_token() {
    let (mut state, mut state_slot_approvable) = setup();
    set_caller_address(OWNER());
    ERC3525::InternalImpl::_mint(ref state, OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    ERC3525SlotApprovable::ERC3525SlotApprovableImpl::set_approval_for_slot(
        ref state_slot_approvable, OWNER(), SLOT_2, OPERATOR(), true
    );
    set_caller_address(OPERATOR());
    ERC3525SlotApprovable::ExternalImpl::approve_value(
        ref state_slot_approvable, TOKEN_ID_1, OPERATOR(), VALUE
    );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: insufficient allowance',))]
fn test_slot_approvable_operator_cannot_transfer_anyones_value() {
    let (mut state, mut state_slot_approvable) = setup();
    set_caller_address(OWNER());
    ERC3525::InternalImpl::_mint(ref state, OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    ERC3525::InternalImpl::_mint(ref state, SOMEONE(), TOKEN_ID_2, SLOT_1, VALUE);
    ERC3525SlotApprovable::ERC3525SlotApprovableImpl::set_approval_for_slot(
        ref state_slot_approvable, OWNER(), SLOT_1, OPERATOR(), true
    );
    set_caller_address(OPERATOR());
    ERC3525SlotApprovable::ExternalImpl::transfer_value_from(
        ref state_slot_approvable, TOKEN_ID_2, 0, OPERATOR(), VALUE
    );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: slot mismatch',))]
fn test_slot_approvable_operator_transfer_value_revert_slot_mismatch() {
    let (mut state, mut state_slot_approvable) = setup();
    set_caller_address(OWNER());
    ERC3525::InternalImpl::_mint(ref state, OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    ERC3525::InternalImpl::_mint(ref state, SOMEONE(), TOKEN_ID_2, SLOT_2, VALUE);
    ERC3525SlotApprovable::ERC3525SlotApprovableImpl::set_approval_for_slot(
        ref state_slot_approvable, OWNER(), SLOT_1, OPERATOR(), true
    );
    set_caller_address(OPERATOR());
    ERC3525SlotApprovable::ExternalImpl::transfer_value_from(
        ref state_slot_approvable, TOKEN_ID_1, TOKEN_ID_2, ZERO(), VALUE
    );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC3525: caller not allowed',))]
fn test_slot_approvable_revoked_slot_operator_cannot_approve() {
    let (mut state, mut state_slot_approvable) = setup();
    set_caller_address(OWNER());
    ERC3525::InternalImpl::_mint(ref state, OWNER(), TOKEN_ID_1, SLOT_1, VALUE);
    ERC3525SlotApprovable::ERC3525SlotApprovableImpl::set_approval_for_slot(
        ref state_slot_approvable, OWNER(), SLOT_1, OPERATOR(), true
    );
    ERC3525SlotApprovable::ERC3525SlotApprovableImpl::set_approval_for_slot(
        ref state_slot_approvable, OWNER(), SLOT_1, OPERATOR(), false
    );
    set_caller_address(OPERATOR());
    ERC3525SlotApprovable::ExternalImpl::approve_value(
        ref state_slot_approvable, TOKEN_ID_1, OPERATOR(), VALUE
    );
}
