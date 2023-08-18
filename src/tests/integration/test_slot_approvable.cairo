use result::ResultTrait;
use option::OptionTrait;
use traits::{Into, TryInto};
use starknet::ContractAddress;

use snforge_std::{declare, PreparedContract, deploy, start_prank, stop_prank};

use cairo_erc_721::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5_ID};
use cairo_erc_721::interface::{IERC721Dispatcher, IERC721DispatcherTrait, IERC721_ID};

use cairo_erc_3525::interface::{IERC3525Dispatcher, IERC3525DispatcherTrait, IERC3525_ID};
use cairo_erc_3525::presets::erc3525_mintable_burnable_metadata_slot_approvable::{
    IExternalDispatcher, IExternalDispatcherTrait
};
use cairo_erc_3525::extensions::slotapprovable::interface::{
    IERC3525SlotApprovableDispatcher, IERC3525SlotApprovableDispatcherTrait,
    IERC3525_SLOT_APPROVABLE_ID
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
    let class_hash = declare('ERC3525MintableBurnableMSA');
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
fn test_integration_slot_approvable_supports_interface() {
    // Setup
    let (contract_address, _) = __setup__();
    let src5 = ISRC5Dispatcher { contract_address };
    assert(src5.supports_interface(ISRC5_ID), 'ISRC5 not supported');
    assert(src5.supports_interface(IERC721_ID), 'IERC721 not supported');
    assert(src5.supports_interface(IERC3525_ID), 'IERC3525 not supported');
    assert(src5.supports_interface(IERC3525_SLOT_APPROVABLE_ID), 'ISlotApprovable not supported');
}
