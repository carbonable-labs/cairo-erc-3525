%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.library import ERC3525

const NAME = 'Carbonable Project';
const SYMBOL = 'CP';
const DECIMALS = 18;
const USER1 = 'user1';
const USER2 = 'user2';
const TOKN1 = 1;
const TOKN2 = 2;
const SLOT1 = 'slot1';

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ERC721.initializer(NAME, SYMBOL);
    ERC721Enumerable.initializer();
    ERC3525.initializer(DECIMALS);
    ERC3525._mint(USER1, Uint256(TOKN1, 0), Uint256(SLOT1, 0), Uint256(42, 0));
    ERC3525._mint(USER2, Uint256(TOKN2, 0), Uint256(SLOT1, 0), Uint256(21, 0));

    return ();
}

// Test disambiguation token_id and to set to zero
@view
func test_cannot_transfer_to_zero_address{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to_token_id = Uint256(TOKN2, 0);
    let value_felt = 10;
    let value = Uint256(value_felt, 0);

    %{
        stop_prank = start_prank(ids.USER1)
        expect_revert(error_message="ERC3525: cannot transfer token zero or to zero address")
    %}
    ERC3525.transfer_from(from_token_id, Uint256(0, 0), 0, value);
    %{ stop_prank() %}
    return ();
}

@view
func test_disambiguation_fails_if_invalid_parameters{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let from_token_id = Uint256(TOKN1, 0);
    let to_token_id = Uint256(TOKN2, 0);
    let value_felt = 10;
    let value = Uint256(value_felt, 0);

    %{
        stop_prank = start_prank(ids.USER1)
        expect_revert(error_message="ERC3525: cannot set both token_id and to")
    %}
    ERC3525.transfer_from(from_token_id, to_token_id, 'some_address', value);
    %{ stop_prank() %}
    return ();
}
