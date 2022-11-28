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
const ADMIN = 'admin';
const USER1 = 'user1';
const USER2 = 'user2';
const USER3 = 'user3';
const TOKN1 = 1;
const TOKN2 = 2;
const INVALID_ID = 666;
const SLOT1 = 'slot1';
const SLOT2 = 'slot2';

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ERC721.initializer(NAME, SYMBOL);
    ERC721Enumerable.initializer();
    ERC3525.initializer(DECIMALS);
    ERC3525._mint(USER1, Uint256(TOKN1, 0), Uint256(SLOT1, 0), Uint256(42, 0));
    ERC3525._mint(USER2, Uint256(TOKN2, 0), Uint256(SLOT1, 0), Uint256(21, 0));

    ERC3525._set_contract_uri('ipfs://');
    ERC3525._set_slot_uri(Uint256(1, 0), 'ipfs://slot');
    return ();
}

@view
func test_balance_of_nonexistent_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(666, 0);

    %{ expect_revert(error_message="ERC3525: query for nonexistent token") %}
    let (bal: Uint256) = ERC3525.balance_of(token_id);

    return ();
}

@view
func test_balance_of_valid_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    let user = 'bal7';
    let token_id = Uint256(1337, 0);
    let slot = Uint256(SLOT1, 0);

    ERC3525._mint(user, token_id, slot, Uint256(42, 0));

    let (balance: Uint256) = ERC3525.balance_of(token_id);
    assert 42 = balance.low;

    let (bal721) = ERC721.balance_of(user);
    assert 1 = bal721.low;

    return ();
}

@view
func test_slot_of_valid_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let token_id = Uint256(TOKN1, 0);
    let (slot: Uint256) = ERC3525.slot_of(token_id);
    assert SLOT1 = slot.low;
    return ();
}

@view
func test_slot_of_nonexistent_token{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(666, 0);
    %{ expect_revert(error_message="ERC3525: query for nonexistent token") %}
    let (slot: Uint256) = ERC3525.slot_of(token_id);
    return ();
}

@view
func test_contract_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (uri: felt) = ERC3525.contract_uri();
    assert 'ipfs://' = uri;
    return ();
}

@view
func test_slot_uri{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let slot = Uint256(1, 0);
    let (uri: felt) = ERC3525.slot_uri(slot);
    assert 'ipfs://slot' = uri;
    return ();
}
