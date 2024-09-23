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
use cairo_erc_3525::presets::erc3525_mintable_burnable_metadata_slot_approvable_slot_enumerable::{
    ERC3525MintableBurnableMSASE, IExternalDispatcher, IExternalDispatcherTrait
};
use cairo_erc_3525::extensions::slotenumerable::interface::{
    IERC3525SlotEnumerableDispatcher, IERC3525SlotEnumerableDispatcherTrait,
    IERC3525_SLOT_ENUMERABLE_ID
};
use super::constants;

use debug::PrintTrait;

#[derive(Drop)]
struct Signers {
    owner: ContractAddress,
    someone: ContractAddress,
    anyone: ContractAddress,
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
    let ERC3525MintableBurnableMSASE_class_hash = declare("ERC3525MintableBurnableMSASE").unwrap();
    let mut ERC3525MintableBurnableMSASE_constructor_calldata = ArrayTrait::new();
    constants::NAME().serialize(ref ERC3525MintableBurnableMSASE_constructor_calldata);
    constants::SYMBOL().serialize(ref ERC3525MintableBurnableMSASE_constructor_calldata);
    constants::BASE_URI().serialize(ref ERC3525MintableBurnableMSASE_constructor_calldata);
    constants::VALUE_DECIMALS.serialize(ref ERC3525MintableBurnableMSASE_constructor_calldata);
    let (contract_address, _) = ERC3525MintableBurnableMSASE_class_hash
        .deploy(@ERC3525MintableBurnableMSASE_constructor_calldata)
        .unwrap();

    let AccountUpgradeable_class_hash = declare("AccountUpgradeable").unwrap();
    let signer = Signers {
        owner: deploy_account(AccountUpgradeable_class_hash, 'OWNER'),
        someone: deploy_account(AccountUpgradeable_class_hash, 'SOMEONE'),
        anyone: deploy_account(AccountUpgradeable_class_hash, 'ANYONE'),
        operator: deploy_account(AccountUpgradeable_class_hash, 'OPERATOR'),
    };
    (contract_address, signer)
}

#[test]
#[available_gas(100_000_000)]
fn test_integration_slot_enumerable_supports_interface() {
    // Setup
    let (contract_address, _) = __setup__();
    let src5 = ISRC5Dispatcher { contract_address };
    assert(src5.supports_interface(ISRC5_ID), 'ISRC5 not supported');
    assert(src5.supports_interface(IERC721_ID), 'IERC721 not supported');
    assert(src5.supports_interface(IERC3525_ID), 'IERC3525 not supported');
    assert(src5.supports_interface(IERC3525_SLOT_ENUMERABLE_ID), 'ISlotEnumerable not supported');
}
#[test]
#[available_gas(100_000_000)]
fn test_integration_slot_enumerable_scenario() {
    // Setup
    let (contract_address, signers) = __setup__();
    let external = IExternalDispatcher { contract_address };
    let erc3525 = IERC3525Dispatcher { contract_address };
    let erc3525_se = IERC3525SlotEnumerableDispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };

    // Mint tokens
    let one = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let two = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let three = external.mint(signers.someone, constants::SLOT_1, constants::VALUE);
    let four = external.mint(signers.anyone, constants::SLOT_1, constants::VALUE);
    let five = external.mint(signers.operator, constants::SLOT_1, constants::VALUE);

    // Assert enumerable
    assert(erc3525_se.slot_count() == 1, 'Wrong slot count');
    assert(erc3525_se.slot_by_index(0) == constants::SLOT_1, 'Wrong slot at index');
    assert(erc3525_se.token_supply_in_slot(constants::SLOT_1) == 5, 'Wrong toke supply in slot');
    assert(
        erc3525_se.token_in_slot_by_index(constants::SLOT_1, 0) == one,
        'Wrong token in slot at index'
    );
    assert(
        erc3525_se.token_in_slot_by_index(constants::SLOT_1, 1) == two,
        'Wrong token in slot at index'
    );
    assert(
        erc3525_se.token_in_slot_by_index(constants::SLOT_1, 2) == three,
        'Wrong token in slot at index'
    );
    assert(
        erc3525_se.token_in_slot_by_index(constants::SLOT_1, 3) == four,
        'Wrong token in slot at index'
    );
    assert(
        erc3525_se.token_in_slot_by_index(constants::SLOT_1, 4) == five,
        'Wrong token in slot at index'
    );

    // Mint tokens
    let six = external.mint(signers.owner, constants::SLOT_2, constants::VALUE);
    let seven = external.mint(signers.someone, constants::SLOT_2, constants::VALUE);
    let height = external.mint(signers.someone, constants::SLOT_2, constants::VALUE);
    let nine = external.mint(signers.anyone, constants::SLOT_2, constants::VALUE);

    // Assert enumerable
    assert(erc3525_se.slot_count() == 2, 'Wrong slot count');
    assert(erc3525_se.slot_by_index(1) == constants::SLOT_2, 'Wrong slot at index');
    assert(erc3525_se.token_supply_in_slot(constants::SLOT_2) == 4, 'Wrong toke supply in slot');
    assert(
        erc3525_se.token_in_slot_by_index(constants::SLOT_2, 0) == six,
        'Wrong token in slot at index'
    );
    assert(
        erc3525_se.token_in_slot_by_index(constants::SLOT_2, 1) == seven,
        'Wrong token in slot at index'
    );
    assert(
        erc3525_se.token_in_slot_by_index(constants::SLOT_2, 2) == height,
        'Wrong token in slot at index'
    );
    assert(
        erc3525_se.token_in_slot_by_index(constants::SLOT_2, 3) == nine,
        'Wrong token in slot at index'
    );

    // Approve
    start_cheat_caller_address(contract_address, signers.owner);
    erc721.approve(signers.owner, one);
    erc721.approve(signers.owner, two);
    erc721.approve(signers.owner, six);
    erc3525.approve_value(one, signers.anyone, constants::VALUE / 2);
    erc3525.approve_value(two, signers.anyone, constants::VALUE / 2);
    erc3525.approve_value(six, signers.anyone, constants::VALUE / 2);
    stop_cheat_caller_address(signers.owner);

    // Transfers to token id
    start_cheat_caller_address(contract_address, signers.anyone);
    erc3525.transfer_value_from(one, three, constants::ZERO(), 1);
    erc3525.transfer_value_from(two, three, constants::ZERO(), 1);
    erc3525.transfer_value_from(six, seven, constants::ZERO(), 1);
    stop_cheat_caller_address(signers.anyone);

    // Transfer to
    let ten = erc3525.transfer_value_from(one, 0, signers.operator, 1);
    assert(ten == 10, 'Wrong id');
    assert(erc3525.allowance(one, signers.anyone) == constants::VALUE / 2 - 2, 'Wrong allowance');
    assert(erc3525.value_of(one) == constants::VALUE - 2, 'Wrong value');
    assert(external.total_value(constants::SLOT_1) == 5 * constants::VALUE, 'Wrong total value');
    assert(external.total_value(constants::SLOT_2) == 4 * constants::VALUE, 'Wrong total value');
}
