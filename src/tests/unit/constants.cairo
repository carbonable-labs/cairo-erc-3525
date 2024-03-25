// Core imports

use zeroable::Zeroable;

// Starknet imports

use starknet::ContractAddress;
use starknet::contract_address_const;

// Local imports

use cairo_erc_3525::module::ERC3525Component;
use cairo_erc_3525::extensions::metadata::module::ERC3525MetadataComponent;
use cairo_erc_3525::extensions::slotapprovable::module::ERC3525SlotApprovableComponent;
use cairo_erc_3525::extensions::slotenumerable::module::ERC3525SlotEnumerableComponent;
use cairo_erc_3525::tests::mocks::contracts::{
    DualCaseERC3525Mock, DualCaseERC3525MetadataMock, DualCaseERC3525SlotApprovableMock, DualCaseERC3525SlotEnumerableMock
};

// Setup

pub type ERC3525ComponentState = ERC3525Component::ComponentState<DualCaseERC3525Mock::ContractState>;
pub type ERC3525MetadataComponentState = ERC3525MetadataComponent::ComponentState<DualCaseERC3525MetadataMock::ContractState>;
pub type ERC3525SlotApprovableComponentState = ERC3525SlotApprovableComponent::ComponentState<DualCaseERC3525SlotApprovableMock::ContractState>;
pub type ERC3525SlotEnumerableComponentState = ERC3525SlotEnumerableComponent::ComponentState<DualCaseERC3525SlotEnumerableMock::ContractState>;

// State

fn COMPONENT_STATE() -> ERC3525ComponentState {
    ERC3525Component::component_state_for_testing()
}

fn CONTRACT_STATE() -> DualCaseERC3525Mock::ContractState {
    DualCaseERC3525Mock::contract_state_for_testing()
}

fn COMPONENT_STATE_METADATA() -> ERC3525MetadataComponentState {
    ERC3525MetadataComponent::component_state_for_testing()
}

fn CONTRACT_STATE_METADATA() -> DualCaseERC3525MetadataMock::ContractState {
    DualCaseERC3525MetadataMock::contract_state_for_testing()
}

fn COMPONENT_STATE_SLOT_APPROVABLE() -> ERC3525SlotApprovableComponentState {
    ERC3525SlotApprovableComponent::component_state_for_testing()
}

fn CONTRACT_STATE_SLOT_APPROVABLE() -> DualCaseERC3525SlotApprovableMock::ContractState {
    DualCaseERC3525SlotApprovableMock::contract_state_for_testing()
}

fn COMPONENT_STATE_SLOT_ENUMERABLE() -> ERC3525SlotEnumerableComponentState {
    ERC3525SlotEnumerableComponent::component_state_for_testing()
}

fn CONTRACT_STATE_SLOT_ENUMERABLE() -> DualCaseERC3525SlotEnumerableMock::ContractState {
    DualCaseERC3525SlotEnumerableMock::contract_state_for_testing()
}

// Constants

const NAME: felt252 = 'NAME';
const SYMBOL: felt252 = 'SYMBOL';
const VALUE_DECIMALS: u8 = 6;
const TOKEN_ID_1: u256 = 1;
const TOKEN_ID_2: u256 = 2;
const INVALID_TOKEN: u256 = 666;
const SLOT_1: u256 = 'SLOT1';
const SLOT_2: u256 = 'SLOT2';
const VALUE: u256 = 1000;

// Addresses

fn ZERO() -> ContractAddress {
    Zeroable::zero()
}

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

fn RECIPIENT() -> ContractAddress {
    contract_address_const::<'RECIPIENT'>()
}

fn SPENDER() -> ContractAddress {
    contract_address_const::<'SPENDER'>()
}

fn OPERATOR() -> ContractAddress {
    contract_address_const::<'OPERATOR'>()
}

fn SOMEONE() -> ContractAddress {
    contract_address_const::<'SOMEONE'>()
}

fn ANYONE() -> ContractAddress {
    contract_address_const::<'ANYONE'>()
}
