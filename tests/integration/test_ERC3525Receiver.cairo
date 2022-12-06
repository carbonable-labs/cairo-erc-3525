%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.introspection.erc165.IERC165 import IERC165
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc721.IERC721Metadata import IERC721Metadata

from carbonable.erc3525.IERC3525Full import IERC3525Full as IERC3525
from carbonable.erc3525.IERC3525Metadata import IERC3525Metadata
from carbonable.erc3525.utils.constants.library import (
    ON_ERC3525_RECEIVED_SELECTOR,
    IACCOUNT_ID,
    IERC3525_RECEIVER_ID,
)

from tests.integration.library import assert_that

@contract_interface
namespace IERC3525Receiver {
    func onERC3525Received(
        operator: felt,
        fromTokenId: Uint256,
        toTokenId: Uint256,
        value: Uint256,
        data_len: felt,
        data: felt*,
    ) -> (selector: felt) {
    }
}

//
// Constants
//

const NAME = 'Carbonable Project';
const SYMBOL = 'CP';
const DECIMALS = 18;
const USER1 = 'user1';
const USER2 = 'user2';
const USER3 = 'user3';
const USER4 = 'user4';
const TOKN1 = 1;
const TOKN2 = 2;
const INVALID_TOKEN = 666;
const SLOT1 = 'slot1';
const SLOT2 = 'slot2';

@external
func __setup__() {
    %{
        context.erc3525_contract = deploy_contract("./src/carbonable/erc3525/presets/ERC3525MintableBurnable.cairo",
            [ids.NAME, ids.SYMBOL, ids.DECIMALS]).contract_address
    %}

    return ();
}

@external
func test_account_receiver{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local instance) = contract_access.deployed();

    let receiver = TRUE;
    let account = TRUE;
    let success_value = ON_ERC3525_RECEIVED_SELECTOR;
    let (address) = contract_access.deploy(receiver, account, success_value);
    let slot = Uint256(1, 0);
    let value = Uint256(42, 0);

    let (token_id: Uint256) = IERC3525.mintNew(instance, USER1, slot, value);
    %{
        stop_prank = start_prank(caller_address=ids.USER1, target_contract_address=ids.instance)
        expect_call(ids.address, "onERC3525Received", [ids.USER1, 1,0, 2,0, 3,0, 0])
        expect_call(ids.address, "supportsInterface", [ids.ON_ERC3525_RECEIVED_SELECTOR])
        expect_events({"name": "Transfer"}, {"name": "SlotChanged"}, {"name": "TransferValue"})
    %}
    IERC3525.transferValueFrom(instance, token_id, Uint256(0, 0), address, Uint256(3, 0));
    %{ stop_prank() %}
    return ();
}

@external
func test_account{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local instance) = contract_access.deployed();

    let receiver = FALSE;
    let account = TRUE;
    let success_value = TRUE;  // Not used
    let (address) = contract_access.deploy(receiver, account, success_value);
    let slot = Uint256(1, 0);
    let value = Uint256(42, 0);

    let (token_id) = IERC3525.mintNew(instance, USER1, slot, value);
    %{
        stop_prank = start_prank(caller_address=ids.USER1, target_contract_address=ids.instance)
        expect_call(ids.address, "supportsInterface", [ids.IERC3525_RECEIVER_ID])
        expect_call(ids.address, "supportsInterface", [ids.IACCOUNT_ID])
        expect_events({"name": "Transfer"}, {"name": "SlotChanged"}, {"name": "TransferValue"})
    %}
    IERC3525.transferValueFrom(instance, token_id, Uint256(0, 0), address, Uint256(3, 0));
    %{ stop_prank() %}
    return ();
}

@external
func test_receiver{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local instance) = contract_access.deployed();

    let receiver = TRUE;
    let account = FALSE;
    let success_value = ON_ERC3525_RECEIVED_SELECTOR;
    let (address) = contract_access.deploy(receiver, account, success_value);
    let slot = Uint256(1, 0);
    let value = Uint256(42, 0);

    let (token_id) = IERC3525.mintNew(instance, USER1, slot, value);
    %{
        stop_prank = start_prank(caller_address=ids.USER1, target_contract_address=ids.instance)
        expect_call(ids.address, "supportsInterface", [ids.ON_ERC3525_RECEIVED_SELECTOR])
        expect_call(ids.address, "onERC3525Received", [ids.USER1, 1,0, 2,0, 3,0, 0])
        expect_events({"name": "Transfer"}, {"name": "SlotChanged"}, {"name": "TransferValue"})
    %}
    IERC3525.transferValueFrom(instance, token_id, Uint256(0, 0), address, Uint256(3, 0));
    %{ stop_prank() %}
    return ();
}

@external
func test_not_account_nor_receiver{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    // Behavior is undefined in implementation.
    // Implementoors should decide whether they accept to send tokens to addresses with no deployed account.
    alloc_locals;
    let (local instance) = contract_access.deployed();

    let receiver = FALSE;
    let account = FALSE;
    let success_value = 1;  // Not used
    let (address) = contract_access.deploy(receiver, account, success_value);
    let slot = Uint256(1, 0);
    let value = Uint256(42, 0);

    let (token_id) = IERC3525.mintNew(instance, USER1, slot, value);
    %{
        stop_prank = start_prank(caller_address=ids.USER1, target_contract_address=ids.instance)
        expect_call(ids.address, "supportsInterface", [ids.IERC3525_RECEIVER_ID])
        expect_call(ids.address, "supportsInterface", [ids.IACCOUNT_ID])
        expect_events({"name": "Transfer"}, {"name": "SlotChanged"}, {"name": "TransferValue"})
    %}
    IERC3525.transferValueFrom(instance, token_id, Uint256(0, 0), address, Uint256(3, 0));
    %{ stop_prank() %}
    return ();
}

@external
func test_receiver_rejected{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local instance) = contract_access.deployed();

    let receiver = TRUE;
    let account = FALSE;
    let success_value = 1;  // Should be ON_ERC3525_RECEIVED_SELECTOR
    let (address) = contract_access.deploy(receiver, account, success_value);
    let slot = Uint256(1, 0);
    let value = Uint256(42, 0);

    let (token_id) = IERC3525.mintNew(instance, USER1, slot, value);
    %{
        stop_prank = start_prank(caller_address=ids.USER1, target_contract_address=ids.instance) 
        expect_call(ids.address, "supportsInterface", [ids.ON_ERC3525_RECEIVED_SELECTOR])
        expect_call(ids.address, "onERC3525Received", [ids.USER1, 1,0, 2,0, 3,0, 0])
        expect_revert(error_message="ERC3525: ERC3525Receiver rejected tokens")
    %}
    IERC3525.transferValueFrom(instance, token_id, Uint256(0, 0), address, Uint256(3, 0));
    %{ stop_prank() %}
    return ();
}

namespace contract_access {
    func deployed() -> (address: felt) {
        tempvar erc3525_contract;
        %{ ids.erc3525_contract = context.erc3525_contract %}
        return (address=erc3525_contract);
    }

    func deploy(receiver, account, success_value) -> (address: felt) {
        tempvar address;
        %{
            ids.address = deploy_contract("./tests/mock/ERC3525MockReceiver.cairo",
                    [ids.receiver, ids.account, ids.success_value]).contract_address
        %}
        return (address=address);
    }
}
