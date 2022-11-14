%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from carbonable.erc3525.library import ERC3525

const NAME = 'Carbonable Project';
const SYMBOL = 'CP';
const DECIMALS = 18;
const USER1 = 'user1';
const USER2 = 'user2';

@view
func test_can_mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ERC3525.initializer(NAME, SYMBOL, DECIMALS);
    let user = 'bal7';
    let token_id = Uint256(1, 0);
    let slot = Uint256(1, 0);
    let ZERO = Uint256(0, 0);

    ERC3525._mint(user, token_id, slot);

    %{
        expect_events(
        {"name": "SlotChanged", 
        # "data": {"tokenId": [1, 0], 
        #          "oldSlot": [0, 0], 
        #          "newSlot": [1, 0]}
        }
        )
    %}
    // let bal = ERC3525.balanceOf()
    return ();
}
