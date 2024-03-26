// Core deps
use result::ResultTrait;
use option::OptionTrait;
use array::ArrayTrait;
use traits::{Into, TryInto};

// Starknet deps
use starknet::{ContractAddress};
use starknet::testing;

// External deps
use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5_ID};
use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait, IERC721_ID};
use openzeppelin::presets::Account;

// Local deps
use cairo_erc_3525::interface::{IERC3525Dispatcher, IERC3525DispatcherTrait, IERC3525_ID};
use cairo_erc_3525::presets::erc3525_mintable_burnable_metadata::{
    ERC3525MintableBurnableMetadata, IExternalDispatcher, IExternalDispatcherTrait
};
use cairo_erc_3525::extensions::metadata::interface::{
    IERC3525MetadataDispatcher, IERC3525MetadataDispatcherTrait, IERC3525_METADATA_ID
};
use cairo_erc_3525::tests::integration::constants;

#[derive(Drop)]
struct Signers {
    owner: ContractAddress,
    someone: ContractAddress,
    anyone: ContractAddress,
    operator: ContractAddress,
}

fn deploy_contract(class_hash: starknet::class_hash::ClassHash) -> ContractAddress {
    let mut calldata: Array<felt252> = ArrayTrait::new();
    constants::NAME().serialize(ref calldata);
    constants::SYMBOL().serialize(ref calldata);
    constants::VALUE_DECIMALS.serialize(ref calldata);
    let (address, _) = starknet::deploy_syscall(class_hash, 0, calldata.span(), false).unwrap();
    address
}

fn deploy_account(
    class_hash: starknet::class_hash::ClassHash, public_key: felt252
) -> ContractAddress {
    let calldata: Array<felt252> = array![public_key];
    let (address, _) = starknet::deploy_syscall(class_hash, 0, calldata.span(), false).unwrap();
    address
}

fn __setup__() -> (ContractAddress, Signers) {
    let contract_address = deploy_contract(
        ERC3525MintableBurnableMetadata::TEST_CLASS_HASH.try_into().unwrap()
    );
    let class_hash = Account::TEST_CLASS_HASH.try_into().unwrap();
    let signer = Signers {
        owner: deploy_account(class_hash, 'OWNER'),
        someone: deploy_account(class_hash, 'SOMEONE'),
        anyone: deploy_account(class_hash, 'ANYONE'),
        operator: deploy_account(class_hash, 'OPERATOR'),
    };
    (contract_address, signer)
}

#[test]
#[available_gas(100_000_000)]
fn test_integration_metadata_supports_interface() {
    // Setup
    let (contract_address, _) = __setup__();
    let src5 = ISRC5Dispatcher { contract_address };
    assert(src5.supports_interface(ISRC5_ID), 'ISRC5 not supported');
    assert(src5.supports_interface(IERC721_ID), 'IERC721 not supported');
    assert(src5.supports_interface(IERC3525_ID), 'IERC3525 not supported');
    assert(src5.supports_interface(IERC3525_METADATA_ID), 'IMetadata not supported');
}

#[test]
#[available_gas(100_000_000)]
fn test_integration_metadata_scenario() {
    // Setup
    let (contract_address, signers) = __setup__();
    let external = IExternalDispatcher { contract_address };
    let _erc3525 = IERC3525Dispatcher { contract_address };
    let erc3525_metadata = IERC3525MetadataDispatcher { contract_address };
    let _erc721 = IERC721Dispatcher { contract_address };

    // Mint tokens
    let _one = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let _two = external.mint(signers.operator, constants::SLOT_1, constants::VALUE);

    // Assert metadata
    assert(erc3525_metadata.contract_uri() == 0, 'Wrong contract uri');
    assert(erc3525_metadata.slot_uri(constants::SLOT_1) == 0, 'Wrong slot uri');
    assert(erc3525_metadata.slot_uri(constants::SLOT_2) == 0, 'Wrong slot uri');

    // Set metadta
    external.set_contract_uri(constants::CONTRACT_URI);
    external.set_slot_uri(constants::SLOT_1, constants::SLOT_URI);

    // Assert metadata
    assert(erc3525_metadata.contract_uri() == constants::CONTRACT_URI, 'Wrong contract uri');
    assert(erc3525_metadata.slot_uri(constants::SLOT_1) == constants::SLOT_URI, 'Wrong slot uri');
    assert(erc3525_metadata.slot_uri(constants::SLOT_2) == 0, 'Wrong slot uri');
}
