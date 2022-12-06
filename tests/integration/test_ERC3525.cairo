%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.introspection.erc165.IERC165 import IERC165
from openzeppelin.token.erc721.enumerable.IERC721Enumerable import IERC721Enumerable
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc721.IERC721Metadata import IERC721Metadata

from carbonable.erc3525.IERC3525Full import IERC3525Full as IERC3525
from carbonable.erc3525.IERC3525Metadata import IERC3525Metadata
from carbonable.erc3525.utils.constants.library import (
    IERC165_ID,
    INVALID_ID,
    IERC721_ID,
    IERC721_RECEIVER_ID,
    IERC721_METADATA_ID,
    IERC721_ENUMERABLE_ID,
    IERC3525_ID,
    IERC3525_METADATA_ID,
    IERC3525_RECEIVER_ID,
    ON_ERC3525_RECEIVED_SELECTOR,
)

from tests.integration.library import assert_that

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

//
// TESTS
//
@external
func __setup__() {
    %{
        context.erc3525_contract = deploy_contract("./src/carbonable/erc3525/presets/ERC3525MintableBurnable.cairo", 
            [ids.NAME, ids.SYMBOL, ids.DECIMALS]).contract_address
    %}

    return ();
}

@external
func test_initialized_metadata{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local erc3525_contract) = contract_access.deployed();
    let (name) = IERC721Metadata.name(erc3525_contract);
    let (symbol) = IERC721Metadata.symbol(erc3525_contract);
    let (decimals) = IERC3525.valueDecimals(erc3525_contract);

    assert NAME = name;
    assert SYMBOL = symbol;
    assert DECIMALS = decimals;
    return ();
}

@external
func test_supports_interfaces{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local erc3525_contract) = contract_access.deployed();
    let (is_3525) = IERC165.supportsInterface(erc3525_contract, IERC3525_ID);
    let (is_3525_meta) = IERC165.supportsInterface(erc3525_contract, IERC3525_METADATA_ID);
    let (is_165) = IERC165.supportsInterface(erc3525_contract, IERC165_ID);
    let (is_721) = IERC165.supportsInterface(erc3525_contract, IERC721_ID);
    assert 1 = is_3525;
    assert 1 = is_3525_meta;
    assert 1 = is_165;
    assert 1 = is_721;

    return ();
}

@external
func test_e2e_3525{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local instance) = contract_access.deployed();
    let slot1 = Uint256(SLOT1, 0);
    let slot2 = Uint256(SLOT2, 0);
    let value = Uint256(10, 0);
    let zero = Uint256(0, 0);
    local account1;
    local account2;
    local account3;
    local account4;

    // Create users accounts
    %{
        ids.account1 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", [ids.USER1]).contract_address 
        ids.account2 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", [ids.USER2]).contract_address 
        ids.account3 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", [ids.USER3]).contract_address 
        ids.account4 = deploy_contract("./lib/cairo_contracts/src/openzeppelin/account/presets/Account.cairo", [ids.USER4]).contract_address
    %}

    // Mint some tokens
    let (_) = IERC3525.mintNew(instance, account1, slot1, value);  // #01
    let (_) = IERC3525.mintNew(instance, account1, slot1, value);  // #02
    let (_) = IERC3525.mintNew(instance, account2, slot1, value);  // #03
    let (_) = IERC3525.mintNew(instance, account3, slot1, value);  // #04
    let (_) = IERC3525.mintNew(instance, account4, slot1, value);  // #05
    let (_) = IERC3525.mintNew(instance, account1, slot2, value);  // #06
    let (_) = IERC3525.mintNew(instance, account2, slot2, value);  // #07
    let (_) = IERC3525.mintNew(instance, account2, slot2, value);  // #08
    let (_) = IERC3525.mintNew(instance, account3, slot2, value);  // #09

    // Mint more value
    IERC3525.mintValue(instance, Uint256(1, 0), value);
    IERC3525.mintValue(instance, Uint256(2, 0), value);

    with instance {
        assert_that.ERC3525_balance_of_is(1, 20);
        assert_that.owner_is(1, account1);

        // approve USER3 tokens
        %{ stop_prank = start_prank(caller_address=ids.account1, target_contract_address=ids.instance) %}
        IERC3525.approveValue(instance, Uint256(1, 0), account3, Uint256(5, 0));
        IERC3525.approveValue(instance, Uint256(2, 0), account3, Uint256(5, 0));
        IERC3525.approveValue(instance, Uint256(6, 0), account3, Uint256(5, 0));
        %{ stop_prank() %}

        // / Transfer tokens
        // 1 -> 3
        %{ stop_prank = start_prank(caller_address=ids.account3, target_contract_address=ids.instance) %}
        let (_) = IERC3525.transferValueFrom(
            contract_address=instance,
            fromTokenId=Uint256(1, 0),
            toTokenId=Uint256(3, 0),
            to=0,
            value=Uint256(1, 0),
        );
        %{ stop_prank() %}

        // 2 -> 3
        %{ stop_prank = start_prank(caller_address=ids.account3, target_contract_address=ids.instance) %}
        let (_) = IERC3525.transferValueFrom(
            contract_address=instance,
            fromTokenId=Uint256(2, 0),
            toTokenId=Uint256(3, 0),
            to=0,
            value=Uint256(1, 0),
        );
        %{ stop_prank() %}

        // 6 -> 7
        %{ stop_prank = start_prank(caller_address=ids.account3, target_contract_address=ids.instance) %}
        let (_) = IERC3525.transferValueFrom(
            contract_address=instance,
            fromTokenId=Uint256(6, 0),
            toTokenId=Uint256(7, 0),
            to=0,
            value=Uint256(1, 0),
        );
        %{ stop_prank() %}

        // 1 -> 10 (new)
        %{ stop_prank = start_prank(caller_address=ids.account3, target_contract_address=ids.instance) %}
        let (token_id) = IERC3525.transferValueFrom(
            contract_address=instance,
            fromTokenId=Uint256(1, 0),
            toTokenId=Uint256(0, 0),
            to=account4,
            value=Uint256(1, 0),
        );
        %{ stop_prank() %}
        let token_10 = token_id.low;
        assert 10 = token_10;

        assert_that.allowance_is(1, account3, 3);
        assert_that.ERC3525_balance_of_is(1, 18);

        // Burn value
        IERC3525.burnValue(instance, Uint256(1, 0), Uint256(3, 0));
        IERC3525.burnValue(instance, Uint256(8, 0), Uint256(2, 0));
        IERC3525.burnValue(instance, Uint256(9, 0), Uint256(1, 0));

        assert_that.allowance_is(1, account3, 3);
        assert_that.ERC3525_balance_of_is(1, 15);
        assert_that.total_supply_is(10);

        // Burn token
        IERC3525.burn(instance, Uint256(1, 0));
        assert_that.total_supply_is(9);

        // Mint after burn
        let (token_id) = IERC3525.mintNew(instance, account1, slot2, value);  // #11 minted
        assert_that.total_supply_is(10);
        assert 11 = token_id.low;

        // Mint after burn

        IERC3525.mint(instance, account2, Uint256(1, 0), slot2, value);  // #1 reminted

        assert_that.slot_of_is(1, SLOT2);
        assert_that.owner_is(1, account2);
    }

    return ();
}

namespace contract_access {
    func deployed() -> (address: felt) {
        tempvar erc3525_contract;
        %{ ids.erc3525_contract = context.erc3525_contract %}
        return (address=erc3525_contract);
    }
}
