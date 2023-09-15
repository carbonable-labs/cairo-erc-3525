use starknet::testing::set_caller_address;
use openzeppelin::token::erc721::erc721::ERC721;
use cairo_erc_3525::module::ERC3525;
use cairo_erc_3525::tests::unit::constants::{
    STATE, VALUE_DECIMALS, TOKEN_ID_1, INVALID_TOKEN, SLOT_1, VALUE, ZERO, OWNER, OPERATOR, SOMEONE,
    ANYONE
};

// Settings

fn setup() -> ERC3525::ContractState {
    let mut state = STATE();
    ERC3525::InternalImpl::initializer(ref state, VALUE_DECIMALS);
    ERC3525::InternalImpl::_mint(ref state, OWNER(), TOKEN_ID_1, SLOT_1, 1 * VALUE);
    state
}

// Tests approvals

#[test]
#[available_gas(20000000)]
fn test_owner_can_approve_operator_value() {
    let mut state = setup();
    set_caller_address(OWNER());
    let allowance = ERC3525::ERC3525Impl::allowance(@state, TOKEN_ID_1, OPERATOR());
    assert(allowance == 0, 'Wrong allowance');
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = ERC3525::ERC3525Impl::allowance(@state, TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
}

#[test]
#[available_gas(20000000)]
fn test_owner_can_approve_more_to_same() {
    let mut state = setup();
    set_caller_address(OWNER());
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OPERATOR(), VALUE);
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OPERATOR(), 2 * VALUE);
    let allowance = ERC3525::ERC3525Impl::allowance(@state, TOKEN_ID_1, OPERATOR());
    assert(allowance == 2 * VALUE, 'Wrong allowance');
}

#[test]
#[available_gas(20000000)]
fn test_owner_can_approve_less_to_same() {
    let mut state = setup();
    set_caller_address(OWNER());
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OPERATOR(), 2 * VALUE);
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = ERC3525::ERC3525Impl::allowance(@state, TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
}

#[test]
#[available_gas(20000000)]
fn test_owner_can_approve_someone_else() {
    let mut state = setup();
    set_caller_address(OWNER());
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = ERC3525::ERC3525Impl::allowance(@state, TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, SOMEONE(), 2 * VALUE);
    let allowance = ERC3525::ERC3525Impl::allowance(@state, TOKEN_ID_1, SOMEONE());
    assert(allowance == 2 * VALUE, 'Wrong allowance');
}

#[test]
#[available_gas(20000000)]
fn test_721approved_for_all_can_approve_value() {
    let mut state = setup();
    set_caller_address(OWNER());
    // ERC721 setup
    let mut erc721_state = ERC721::unsafe_new_contract_state();
    ERC721::ERC721Impl::set_approval_for_all(ref erc721_state, SOMEONE(), true);
    // ERC3525 test
    set_caller_address(SOMEONE()); // Prank
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = ERC3525::ERC3525Impl::allowance(@state, TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
}

#[test]
#[available_gas(20000000)]
fn test_721approved_can_approve_value() {
    let mut state = setup();
    set_caller_address(OWNER());
    // ERC721 setup
    let mut erc721_state = ERC721::unsafe_new_contract_state();
    ERC721::ERC721Impl::approve(ref erc721_state, SOMEONE(), TOKEN_ID_1);
    // ERC3525 test
    set_caller_address(SOMEONE()); // Prank
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OPERATOR(), VALUE);
    let allowance = ERC3525::ERC3525Impl::allowance(@state, TOKEN_ID_1, OPERATOR());
    assert(allowance == VALUE, 'Wrong allowance');
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_cannot_approve_value_to_zero_address() {
    let mut state = setup();
    set_caller_address(OWNER());
    // ERC3525 test
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, ZERO(), VALUE);
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_cannot_approve_value_to_self() {
    let mut state = setup();
    set_caller_address(OWNER());
    // ERC3525 test
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OWNER(), VALUE);
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_anyone_cannot_approve_value() {
    let mut state = setup();
    set_caller_address(ANYONE());
    // ERC3525 test
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, ANYONE(), VALUE);
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_cannot_approve_value_nonexistent_token_id() {
    let mut state = setup();
    set_caller_address(OWNER());
    // ERC3525 test
    ERC3525::ERC3525Impl::approve_value(ref state, INVALID_TOKEN, OPERATOR(), VALUE);
}

#[test]
#[should_panic]
#[available_gas(20000000)]
fn test_zero_address_cannot_approve_value() {
    let mut state = setup();
    set_caller_address(ZERO());
    // ERC3525 test
    ERC3525::ERC3525Impl::approve_value(ref state, TOKEN_ID_1, OPERATOR(), VALUE);
}
