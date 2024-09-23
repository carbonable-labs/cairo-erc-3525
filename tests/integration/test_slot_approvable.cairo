// Core deps
use result::ResultTrait;
use option::OptionTrait;
use array::ArrayTrait;
use traits::{Into, TryInto};

// snforge deps
use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address
};

// Starknet deps
use starknet::{ContractAddress};

// External deps
use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5_ID};
use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait, IERC721_ID};

// Local deps
use cairo_erc_3525::interface::{IERC3525Dispatcher, IERC3525DispatcherTrait, IERC3525_ID};
use cairo_erc_3525::presets::erc3525_mintable_burnable_metadata_slot_approvable::{
    ERC3525MintableBurnableMSA, IExternalDispatcher, IExternalDispatcherTrait
};
use cairo_erc_3525::extensions::slotapprovable::interface::{
    IERC3525SlotApprovableDispatcher, IERC3525SlotApprovableDispatcherTrait,
    IERC3525_SLOT_APPROVABLE_ID
};
use super::constants;

#[derive(Drop)]
struct Signers {
    owner: ContractAddress,
    operator: ContractAddress,
}

fn deploy_account(
    class_hash: snforge_std::cheatcodes::contract_class::ContractClass, public_key: felt252
) -> ContractAddress {
    let calldata: Array<felt252> = array![public_key];
    let (address, _) = class_hash.deploy(@calldata).unwrap();
    address
}

fn __setup__() -> (ContractAddress, Signers) {
    let ERC3525MintableBurnableMSA_class_hash = declare("ERC3525MintableBurnableMSA").unwrap();
    let mut ERC3525MintableBurnableMSA_constructor_calldata = ArrayTrait::new();
    constants::NAME().serialize(ref ERC3525MintableBurnableMSA_constructor_calldata);
    constants::SYMBOL().serialize(ref ERC3525MintableBurnableMSA_constructor_calldata);
    constants::BASE_URI().serialize(ref ERC3525MintableBurnableMSA_constructor_calldata);
    constants::VALUE_DECIMALS.serialize(ref ERC3525MintableBurnableMSA_constructor_calldata);
    let (contract_address, _) = ERC3525MintableBurnableMSA_class_hash
        .deploy(@ERC3525MintableBurnableMSA_constructor_calldata)
        .unwrap();

    let AccountUpgradeable_class_hash = declare("AccountUpgradeable").unwrap();
    let signer = Signers {
        owner: deploy_account(AccountUpgradeable_class_hash, 'OWNER'),
        operator: deploy_account(AccountUpgradeable_class_hash, 'OPERATOR'),
    };
    (contract_address, signer)
}

#[test]
#[available_gas(100_000_000)]
fn test_integration_slot_approvable_supports_interface() {
    // Setup
    let (contract_address, _) = __setup__();
    let src5 = ISRC5Dispatcher { contract_address };
    assert(src5.supports_interface(ISRC5_ID), 'ISRC5 not supported');
    assert(src5.supports_interface(IERC721_ID), 'IERC721 not supported');
    assert(src5.supports_interface(IERC3525_ID), 'IERC3525 not supported');
    assert(src5.supports_interface(IERC3525_SLOT_APPROVABLE_ID), 'ISlotApprovable not supported');
}

#[test]
#[available_gas(100_000_000)]
fn test_integration_slot_aprovable_scenario() {
    // Setup
    let (contract_address, signers) = __setup__();
    let external = IExternalDispatcher { contract_address };
    let erc3525 = IERC3525Dispatcher { contract_address };
    let erc3525_sa = IERC3525SlotApprovableDispatcher { contract_address };
    let _erc721 = IERC721Dispatcher { contract_address };

    // Mint tokens
    let one = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let two = external.mint(signers.operator, constants::SLOT_1, constants::VALUE);

    // Slot approvals
    start_cheat_caller_address(contract_address, signers.owner);
    erc3525_sa.set_approval_for_slot(signers.owner, constants::SLOT_1, signers.operator, true);
    stop_cheat_caller_address(signers.owner);

    // Transfer value
    start_cheat_caller_address(contract_address, signers.operator);
    erc3525.transfer_value_from(one, two, constants::ZERO(), 1);
    stop_cheat_caller_address(signers.operator)
}

