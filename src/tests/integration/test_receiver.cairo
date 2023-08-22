use result::ResultTrait;
use option::OptionTrait;
use traits::{Into, TryInto};
use starknet::ContractAddress;

use snforge_std::{declare, PreparedContract, deploy, start_prank, stop_prank};

use cairo_erc_721::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5_ID};
use cairo_erc_721::interface::{IERC721Dispatcher, IERC721DispatcherTrait, IERC721_ID};

use cairo_erc_3525::interface::{IERC3525Dispatcher, IERC3525DispatcherTrait, IERC3525_ID};
use cairo_erc_3525::presets::erc3525_mintable_burnable::{
    IExternalDispatcher, IExternalDispatcherTrait
};
use cairo_erc_3525::tests::integration::constants;
use cairo_erc_3525::tests::mocks::receiver::{IReceiverDispatcher, IReceiverDispatcherTrait};

#[derive(Drop)]
struct Signers {
    owner: ContractAddress,
}

fn deploy_contract(class_hash: starknet::class_hash::ClassHash) -> ContractAddress {
    let constructor_calldata: Array<felt252> = array![constants::VALUE_DECIMALS.into()];
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

fn deploy_receiver(class_hash: starknet::class_hash::ClassHash) -> ContractAddress {
    let constructor_calldata: Array<felt252> = array![];
    let prepared = PreparedContract {
        class_hash: class_hash, constructor_calldata: @constructor_calldata
    };
    deploy(prepared).unwrap()
}

fn __setup__() -> (ContractAddress, Signers, ContractAddress) {
    let class_hash = declare('ERC3525MintableBurnable');
    let contract_address = deploy_contract(class_hash);
    let class_hash = declare('Account');
    let signer = Signers { owner: deploy_account(class_hash, 'OWNER') };
    let class_hash = declare('Receiver');
    let receiver_address = deploy_receiver(class_hash);

    (contract_address, signer, receiver_address)
}

#[test]
fn test_integration_receiver_scenario() {
    // Setup
    let (contract_address, signers, receiver_address) = __setup__();
    let receiver = IReceiverDispatcher { contract_address: receiver_address };
    let external = IExternalDispatcher { contract_address };
    let erc3525 = IERC3525Dispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };

    // Mint tokens
    let one = external.mint(signers.owner, constants::SLOT_1, constants::VALUE);

    // Assert receiver
    assert(receiver.called() == false, 'Wrong receiver called');

    // Transfer to
    start_prank(contract_address, signers.owner);
    let _ = erc3525.transfer_value_from(one, 0, receiver_address, 1);

    // Assert receiver
    assert(receiver.called() == true, 'Wrong receiver called');
}
