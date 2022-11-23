%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from carbonable.erc3525.library import ERC3525, _check_on_erc3525_received
from carbonable.erc3525.utils.constants.library import IERC3525_RECEIVER_ID

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

@view
func test_mock{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let operator = 1;
    let from_token_id: Uint256 = Uint256(1, 0);
    let to_token_id: Uint256 = Uint256(2, 0);
    let value: Uint256 = Uint256(20, 0);
    let data_len = 0;
    let data = cast(0, felt*);
    let to = 0x1;
    %{
        stop_mock = mock_call(ids.to, "supportsInterface", [ids.TRUE])
        stop_mock = mock_call(ids.to, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
    %}
    let (result) = _check_on_erc3525_received(from_token_id, to_token_id, to, value, 0, data);
    %{ stop_mock() %}
    return ();
}
