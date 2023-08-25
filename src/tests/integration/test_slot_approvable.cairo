use result::ResultTrait;
use option::OptionTrait;
use array::ArrayTrait;
use traits::{Into, TryInto};
use starknet::ContractAddress;
use starknet::testing;

use cairo_erc_721::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5_ID};
use cairo_erc_721::interface::{IERC721Dispatcher, IERC721DispatcherTrait, IERC721_ID};

use cairo_erc_3525::interface::{IERC3525Dispatcher, IERC3525DispatcherTrait, IERC3525_ID};
use cairo_erc_3525::presets::erc3525_mintable_burnable_metadata_slot_approvable::{
    ERC3525MintableBurnableMSA, IExternalDispatcher, IExternalDispatcherTrait
};
use cairo_erc_3525::extensions::slotapprovable::interface::{
    IERC3525SlotApprovableDispatcher, IERC3525SlotApprovableDispatcherTrait,
    IERC3525_SLOT_APPROVABLE_ID
};
use cairo_erc_3525::tests::integration::constants;
use cairo_erc_3525::tests::mocks::account::Account;

#[derive(Drop)]
struct Signers {
    owner: ContractAddress,
    operator: ContractAddress,
}

fn deploy_contract(class_hash: starknet::class_hash::ClassHash) -> ContractAddress {
    let calldata: Array<felt252> = array![constants::NAME, constants::SYMBOL, constants::VALUE_DECIMALS.into()];
    let (address, _) = starknet::deploy_syscall(class_hash, 0, calldata.span(), false).expect('Deploy contract failed');
    address
}

fn deploy_account(
    class_hash: starknet::class_hash::ClassHash, public_key: felt252
) -> ContractAddress {
    let calldata: Array<felt252> = array![public_key];
    let (address, _) = starknet::deploy_syscall(class_hash, 0, calldata.span(), false).expect('Deploy account failed');
    address
}

fn __setup__() -> (ContractAddress, Signers) {
    let contract_address = deploy_contract(ERC3525MintableBurnableMSA::TEST_CLASS_HASH.try_into().unwrap());
    let class_hash = Account::TEST_CLASS_HASH.try_into().unwrap();
    let signer = Signers {
        owner: deploy_account(class_hash, 'OWNER'),
        operator: deploy_account(class_hash, 'OPERATOR'),
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
    let erc721 = IERC721Dispatcher { contract_address };

    // Mint tokens
    let one = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
    let two = external.mint(signers.operator, constants::SLOT_1, constants::VALUE);

    // Slot approvals
    testing::set_contract_address(signers.owner);
    erc3525_sa.set_approval_for_slot(signers.owner, constants::SLOT_1, signers.operator, true);

    // Transfer value
    testing::set_contract_address(signers.operator);
    erc3525.transfer_value_from(one, two, constants::ZERO(), 1);
}

