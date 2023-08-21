use result::ResultTrait;
use option::OptionTrait;
use traits::{Into, TryInto};
use starknet::ContractAddress;

use snforge_std::{declare, PreparedContract, deploy, start_prank, stop_prank};

use cairo_erc_721::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5_ID};
use cairo_erc_721::interface::{IERC721Dispatcher, IERC721DispatcherTrait, IERC721_ID};

use cairo_erc_3525::interface::{IERC3525Dispatcher, IERC3525DispatcherTrait, IERC3525_ID};
use cairo_erc_3525::presets::erc3525_mintable_burnable_metadata_enumerable_slot_approvable_slot_enumerable::{
    IExternalDispatcher, IExternalDispatcherTrait
};
use cairo_erc_3525::extensions::slotenumerable::interface::{
    IERC3525SlotEnumerableDispatcher, IERC3525SlotEnumerableDispatcherTrait,
    IERC3525_SLOT_ENUMERABLE_ID
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
    let class_hash = declare('ERC3525MintableBurnableEMSASE');
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
fn test_integration_scenario() {
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

    // Assert enuerable
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

    // Assert enuerable
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
}
