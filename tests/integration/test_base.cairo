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
use cairo_erc_3525::presets::erc3525_mintable_burnable::{
    ERC3525MintableBurnable, IExternalDispatcher, IExternalDispatcherTrait
};
use super::constants;


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
    let ERC3525MintableBurnable_class_hash = declare("ERC3525MintableBurnable").unwrap();
    let mut ERC3525MintableBurnable_constructor_calldata = ArrayTrait::new();
    let value_decimals: u8 = 6;
    value_decimals.serialize(ref ERC3525MintableBurnable_constructor_calldata);
    let (contract_address, _) = ERC3525MintableBurnable_class_hash
        .deploy(@ERC3525MintableBurnable_constructor_calldata)
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
fn test_integration_supports_interface() {
    // Setup
    let (contract_address, _) = __setup__();
    let src5 = ISRC5Dispatcher { contract_address };
    assert(src5.supports_interface(ISRC5_ID), 'ISRC5 not supported');
    assert(src5.supports_interface(IERC721_ID), 'IERC721 not supported');
    assert(src5.supports_interface(IERC3525_ID), 'IERC3525 not supported');
}

#[test]
#[available_gas(100_000_000)]
fn test_integration_base_scenario() {
    // Setup
    let (contract_address, signers) = __setup__();
    let external = IExternalDispatcher { contract_address };
    let erc3525 = IERC3525Dispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };

    // Mint tokens
    let one = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let two = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let three = external.mint(signers.someone, constants::SLOT_1, constants::VALUE);
    let _four = external.mint(signers.anyone, constants::SLOT_1, constants::VALUE);
    let _five = external.mint(signers.operator, constants::SLOT_1, constants::VALUE);
    let six = external.mint(signers.owner, constants::SLOT_2, constants::VALUE);
    let seven = external.mint(signers.someone, constants::SLOT_2, constants::VALUE);
    let height = external.mint(signers.someone, constants::SLOT_2, constants::VALUE);
    let nine = external.mint(signers.anyone, constants::SLOT_2, constants::VALUE);

    // Asserts
    assert(erc3525.value_of(one) == constants::VALUE, 'Wrong value');
    assert(erc721.owner_of(one) == signers.owner, 'Wrong owner');

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

    // Burn value
    start_cheat_caller_address(contract_address, signers.owner);
    external.burn_value(one, 3);
    stop_cheat_caller_address(signers.owner);

    start_cheat_caller_address(contract_address, signers.someone);
    external.burn_value(height, 2);
    stop_cheat_caller_address(signers.someone);

    start_cheat_caller_address(contract_address, signers.anyone);
    external.burn_value(nine, 1);
    assert(erc3525.allowance(one, signers.anyone) == constants::VALUE / 2 - 2, 'Wrong allowance');
    assert(erc3525.value_of(one) == constants::VALUE - 2 - 3, 'Wrong value');
    assert(
        external.total_value(constants::SLOT_1) == 5 * constants::VALUE - 3, 'Wrong total value'
    );
    assert(
        external.total_value(constants::SLOT_2) == 4 * constants::VALUE - 3, 'Wrong total value'
    );
    stop_cheat_caller_address(signers.anyone);

    // Burn token
    start_cheat_caller_address(contract_address, signers.owner);
    external.burn(one);
    assert(
        external.total_value(constants::SLOT_1) == 4 * constants::VALUE + 2, 'Wrong total value'
    );
    assert(
        external.total_value(constants::SLOT_2) == 4 * constants::VALUE - 3, 'Wrong total value'
    );
    stop_cheat_caller_address(signers.owner);
}
