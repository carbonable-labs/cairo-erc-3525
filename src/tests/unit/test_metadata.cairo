// Core imports

use integer::BoundedInt;
use debug::PrintTrait;

// Starknet imports

use starknet::ContractAddress;
use starknet::testing::set_caller_address;

// External imports

use openzeppelin::token::erc721::erc721::ERC721;

// Local imports

use cairo_erc_3525::tests::mocks::account::Account;
use cairo_erc_3525::module::ERC3525;
use cairo_erc_3525::extensions::metadata::module::ERC3525Metadata;
use cairo_erc_3525::tests::unit::constants::{STATE, STATE_METADATA, VALUE_DECIMALS, SLOT_1, SLOT_2};

// Settings

fn setup() -> ERC3525Metadata::ContractState {
    let mut state_metadata = STATE_METADATA();
    ERC3525Metadata::InternalImpl::initializer(ref state_metadata);
    state_metadata
}

#[test]
#[available_gas(20000000)]
fn test_metadata_contract_uri() {
    let mut state_metadata = setup();
    let uri = ERC3525Metadata::ERC3525MetadataImpl::contract_uri(@state_metadata);
    assert(uri == 0, 'Wrong contract URI');
    let new_uri = 'https://example.com';
    ERC3525Metadata::InternalImpl::_set_contract_uri(ref state_metadata, new_uri);
    let uri = ERC3525Metadata::ERC3525MetadataImpl::contract_uri(@state_metadata);
    assert(uri == new_uri, 'Wrong contract URI');
}

#[test]
#[available_gas(20000000)]
fn test_metadata_slot_uri() {
    let mut state_metadata = setup();
    let uri = ERC3525Metadata::ERC3525MetadataImpl::slot_uri(@state_metadata, SLOT_1);
    assert(uri == 0, 'Wrong contract URI');
    let new_uri = 'https://example.com';
    ERC3525Metadata::InternalImpl::_set_slot_uri(ref state_metadata, SLOT_1, new_uri);
    let uri = ERC3525Metadata::ERC3525MetadataImpl::slot_uri(@state_metadata, SLOT_1);
    assert(uri == new_uri, 'Wrong contract URI');
    let uri = ERC3525Metadata::ERC3525MetadataImpl::slot_uri(@state_metadata, SLOT_2);
    assert(uri == 0, 'Wrong contract URI');
}
