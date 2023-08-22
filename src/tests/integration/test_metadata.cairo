use result::ResultTrait;
use option::OptionTrait;
use traits::{Into, TryInto};
use starknet::ContractAddress;

use snforge_std::{declare, PreparedContract, deploy, start_prank, stop_prank};

use cairo_erc_721::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5_ID};
use cairo_erc_721::interface::{IERC721Dispatcher, IERC721DispatcherTrait, IERC721_ID};

use cairo_erc_3525::interface::{IERC3525Dispatcher, IERC3525DispatcherTrait, IERC3525_ID};
use cairo_erc_3525::presets::erc3525_mintable_burnable_metadata::{
    IExternalDispatcher, IExternalDispatcherTrait
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
    let constructor_calldata: Array<felt252> = array![
        constants::NAME, constants::SYMBOL, constants::VALUE_DECIMALS.into()
    ];
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    deploy(prepared).unwrap()
}

fn deploy_account(
    class_hash: starknet::class_hash::ClassHash, public_key: felt252
) -> ContractAddress {
    let constructor_calldata: Array<felt252> = array![public_key];
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    deploy(prepared).unwrap()
}

fn __setup__() -> (ContractAddress, Signers) {
    let class_hash = declare('ERC3525MintableBurnableMetadata');
    let contract_address = deploy_contract(class_hash);
    let class_hash = declare('Account');
    let signer = Signers {
        owner: deploy_account(class_hash, 'OWNER'),
        someone: deploy_account(class_hash, 'SOMEONE'),
        anyone: deploy_account(class_hash, 'ANYONE'),
        operator: deploy_account(class_hash, 'OPERATOR'),
    };
    (contract_address, signer)
}

#[test]
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
fn test_integration_scenario() {
    // Setup
    let (contract_address, signers) = __setup__();
    let external = IExternalDispatcher { contract_address };
    let erc3525 = IERC3525Dispatcher { contract_address };
    let erc3525_metadata = IERC3525MetadataDispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };

    // Mint tokens
    let one = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let two = external.mint(signers.operator, constants::SLOT_1, constants::VALUE);

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
