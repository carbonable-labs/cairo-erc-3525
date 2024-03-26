// Core imports

use integer::BoundedInt;
use debug::PrintTrait;

// Starknet imports

use starknet::ContractAddress;
use starknet::testing::set_caller_address;

// External imports

use openzeppelin::token::erc721::erc721::ERC721Component;
use openzeppelin::presets::Account;

// Local imports

use cairo_erc_3525::module::ERC3525Component;
use cairo_erc_3525::extensions::metadata::module::ERC3525MetadataComponent::{ ERC3525MetadataImpl, InternalImpl };
use cairo_erc_3525::extensions::metadata::module::ERC3525MetadataComponent;
use cairo_erc_3525::tests::unit::constants::{
    ERC3525MetadataComponentState,
    COMPONENT_STATE, COMPONENT_STATE_METADATA, VALUE_DECIMALS, SLOT_1, SLOT_2
};

// Settings

fn setup() -> ERC3525MetadataComponentState {
    let mut state_metadata = COMPONENT_STATE_METADATA();
    state_metadata.initializer();
    state_metadata
}

#[test]
#[available_gas(20000000)]
fn test_metadata_contract_uri() {
    let mut state_metadata = setup();
    let uri = state_metadata.contract_uri();
    assert(uri == 0, 'Wrong contract URI');
    let new_uri = 'https://example.com';
    state_metadata._set_contract_uri(new_uri);
    let uri = state_metadata.contract_uri();
    assert(uri == new_uri, 'Wrong contract URI');
}

#[test]
#[available_gas(20000000)]
fn test_metadata_slot_uri() {
    let mut state_metadata = setup();
    let uri = state_metadata.slot_uri(SLOT_1);
    assert(uri == 0, 'Wrong contract URI');
    let new_uri = 'https://example.com';
    state_metadata._set_slot_uri(SLOT_1, new_uri);
    let uri = state_metadata.slot_uri(SLOT_1);
    assert(uri == new_uri, 'Wrong contract URI');
    let uri = state_metadata.slot_uri(SLOT_2);
    assert(uri == 0, 'Wrong contract URI');
}
