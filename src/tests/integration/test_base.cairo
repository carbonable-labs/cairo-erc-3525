use result::ResultTrait;
use option::OptionTrait;
use traits::{Into, TryInto};
use starknet::ContractAddress;

use snforge_std::{ declare, PreparedContract, deploy, start_prank, stop_prank };

use cairo_erc_721::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5_ID};
use cairo_erc_721::interface::{IERC721Dispatcher, IERC721DispatcherTrait, IERC721_ID};

use cairo_erc_3525::interface::{IERC3525Dispatcher, IERC3525DispatcherTrait, IERC3525_ID};
use cairo_erc_3525::presets::erc3525_mintable_burnable::{IExternalDispatcher, IExternalDispatcherTrait};
use cairo_erc_3525::tests::integration::constants;

#[derive(Drop)]
struct Signers {
    owner: ContractAddress,
    someone: ContractAddress,
    anyone: ContractAddress,
    operator: ContractAddress,
}

fn deploy_contract(class_hash: starknet::class_hash::ClassHash) -> ContractAddress {
    let constructor_calldata : Array<felt252> = array![constants::VALUE_DECIMALS.into()];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @constructor_calldata };
    deploy(prepared).unwrap()
}

fn deploy_account(class_hash: starknet::class_hash::ClassHash, public_key: felt252) -> ContractAddress {
    let constructor_calldata : Array<felt252> = array![public_key];
    let prepared = PreparedContract { class_hash: class_hash, constructor_calldata: @constructor_calldata };
    deploy(prepared).unwrap()
}

fn __setup__() -> (ContractAddress, Signers) {
    let class_hash = declare('ERC3525MintableBurnable');
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
fn test_integration_supports_interface() {
    // Setup
    let (contract_address, _) = __setup__();
    let src5 = ISRC5Dispatcher { contract_address };
    assert(src5.supports_interface(ISRC5_ID), 'ISRC5 not supported');
    assert(src5.supports_interface(IERC721_ID), 'IERC721 not supported');
    assert(src5.supports_interface(IERC3525_ID), 'IERC3525 not supported');
}

#[test]
fn test_integration_scenario() {
    // Setup
    let (contract_address, signers) = __setup__();
    let external = IExternalDispatcher { contract_address };
    let erc3525 = IERC3525Dispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };

    // Mint tokens
    let one = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let two = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let three = external.mint(signers.someone, constants::SLOT_1, constants::VALUE);
    let four = external.mint(signers.anyone, constants::SLOT_1, constants::VALUE);
    let five = external.mint(signers.operator, constants::SLOT_1, constants::VALUE);
    let six = external.mint(signers.owner, constants::SLOT_2, constants::VALUE);
    let seven = external.mint(signers.someone, constants::SLOT_2, constants::VALUE);
    let height = external.mint(signers.someone, constants::SLOT_2, constants::VALUE);
    let nine = external.mint(signers.anyone, constants::SLOT_2, constants::VALUE);
    
    // Asserts
    assert(erc3525.value_of(one) == constants::VALUE, 'Wrong value');
    assert(erc721.owner_of(one) == signers.owner, 'Wrong owner');
    
    // Approve
    start_prank(contract_address, signers.owner);
    erc3525.approve_value(one, signers.anyone, constants::VALUE / 2);
    erc3525.approve_value(two, signers.anyone, constants::VALUE / 2);
    erc3525.approve_value(six, signers.anyone, constants::VALUE / 2);

    // Transfers to token id
    start_prank(contract_address, signers.anyone);
    erc3525.transfer_value_from(one, three, constants::ZERO(), 1);
    erc3525.transfer_value_from(two, three, constants::ZERO(), 1);
    erc3525.transfer_value_from(six, seven, constants::ZERO(), 1);

    // Transfer to
    let ten = erc3525.transfer_value_from(one, 0, signers.operator, 1);
    assert(ten == 10, 'Wrong id');
    assert(erc3525.allowance(one, signers.anyone) == constants::VALUE / 2 - 2, 'Wrong allowance');
    assert(erc3525.value_of(one) == constants::VALUE - 2, 'Wrong value');
    assert(external.total_value(constants::SLOT_1) == 5 * constants::VALUE, 'Wrong total value');
    assert(external.total_value(constants::SLOT_2) == 4 * constants::VALUE, 'Wrong total value');

    // Burn value
    start_prank(contract_address, signers.owner);
    external.burn_value(one, 3);
    start_prank(contract_address, signers.someone);
    external.burn_value(height, 2);
    start_prank(contract_address, signers.anyone);
    external.burn_value(nine, 1);
    assert(erc3525.allowance(one, signers.anyone) == constants::VALUE / 2 - 2, 'Wrong allowance');
    assert(erc3525.value_of(one) == constants::VALUE - 2 - 3, 'Wrong value');
    assert(external.total_value(constants::SLOT_1) == 5 * constants::VALUE - 3, 'Wrong total value');
    assert(external.total_value(constants::SLOT_2) == 4 * constants::VALUE - 3, 'Wrong total value');

    // Burn token
    start_prank(contract_address, signers.owner);
    external.burn(one);
    assert(external.total_value(constants::SLOT_1) == 4 * constants::VALUE + 2, 'Wrong total value');
    assert(external.total_value(constants::SLOT_2) == 4 * constants::VALUE - 3, 'Wrong total value');
}