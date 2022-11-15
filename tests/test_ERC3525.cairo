%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.introspection.erc165.IERC165 import IERC165
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc721.IERC721Metadata import IERC721Metadata

from carbonable.erc3525.IERC3525 import IERC3525
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

//
// Constants
//

const NAME = 'Carbonable Project';
const SYMBOL = 'CP';
const DECIMALS = 18;
const ADMIN = 'admin';

//
// TESTS
//
@external
func __setup__() {
    %{
        context.erc3525_contract = deploy_contract("./src/carbonable/erc3525/ERC3525.cairo", 
            [ids.NAME, ids.SYMBOL, ids.DECIMALS, ids.ADMIN]).contract_address
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
    // assert 1 = is_3525_meta;
    assert 1 = is_165;
    assert 1 = is_721;

    return ();
}

@external
func test_nonexistent_token_balance{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let (local erc3525_contract) = contract_access.deployed();

    %{ expect_revert(error_message="ERC3525: balance query for nonexistent token") %}
    let (bal) = IERC3525.balanceOf3525(erc3525_contract, Uint256(0, 0));
    return ();
}

@external
func template_test{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    let (local erc3525_contract) = contract_access.deployed();

    return ();
}

namespace contract_access {
    func deployed() -> (address: felt) {
        tempvar erc3525_contract;
        %{ ids.erc3525_contract = context.erc3525_contract %}
        return (address=erc3525_contract);
    }
}
