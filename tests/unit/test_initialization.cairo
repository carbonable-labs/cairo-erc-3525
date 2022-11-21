%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from carbonable.erc3525.library import ERC3525

@view
func test_can_set_valid_decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    let decimals = 18;
    ERC3525.initializer(decimals);
    let (returned_decimals) = ERC3525.value_decimals();
    assert decimals = returned_decimals;
    return ();
}

@view
func test_cannot_set_invalid_decimals{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let decimals = 2 ** 8 + 1;

    %{ expect_revert(error_message="ERC3525: decimals exceed 2^8") %}
    ERC3525.initializer(decimals);

    let decimals = -1;

    %{ expect_revert(error_message="ERC3525: decimals exceed 2^8") %}
    ERC3525.initializer(decimals);
    return ();
}
