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

// Local deps
use cairo_erc_3525::interface::{IERC3525Dispatcher, IERC3525DispatcherTrait, IERC3525_ID};
use cairo_erc_3525::presets::erc3525_mintable_burnable::{
    ERC3525MintableBurnable, IExternalDispatcher, IExternalDispatcherTrait
};
use cairo_erc_3525::tests::integration::constants;
use cairo_erc_3525::tests::mocks::receiver::{IReceiverDispatcher, IReceiverDispatcherTrait};
use cairo_erc_3525::tests::mocks::account::Account;
use cairo_erc_3525::tests::mocks::receiver::Receiver;

#[derive(Drop)]
struct Signers {
    owner: ContractAddress,
}

fn deploy_contract(class_hash: starknet::class_hash::ClassHash) -> ContractAddress {
    let calldata: Array<felt252> = array![constants::VALUE_DECIMALS.into()];
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

fn deploy_receiver(class_hash: starknet::class_hash::ClassHash) -> ContractAddress {
    let calldata: Array<felt252> = array![];
    let (address, _) = starknet::deploy_syscall(class_hash, 0, calldata.span(), false).unwrap();
    address
}

fn __setup__() -> (ContractAddress, Signers, ContractAddress) {
    let contract_address = deploy_contract(
        ERC3525MintableBurnable::TEST_CLASS_HASH.try_into().unwrap()
    );
    let class_hash = Account::TEST_CLASS_HASH.try_into().unwrap();
    let signer = Signers { owner: deploy_account(class_hash, 'OWNER') };
    let class_hash = Receiver::TEST_CLASS_HASH.try_into().unwrap();
    let receiver_address = deploy_receiver(class_hash);

    (contract_address, signer, receiver_address)
}

#[test]
#[available_gas(100_000_000)]
fn test_integration_receiver_scenario() {
    // Setup
    let (contract_address, signers, receiver_address) = __setup__();
    let _receiver = IReceiverDispatcher { contract_address: receiver_address };
    let external = IExternalDispatcher { contract_address };
    let _erc3525 = IERC3525Dispatcher { contract_address };
    let _erc721 = IERC721Dispatcher { contract_address };

    // Mint tokens
    let _one = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);
// // Assert receiver
// assert(receiver.called() == false, 'Wrong receiver called');

// // Transfer to
// testing::set_contract_address(signers.owner);
// let _ = erc3525.transfer_value_from(one, 0, receiver_address, 1);

// // Assert receiver
// assert(receiver.called() == true, 'Wrong receiver called');
}
