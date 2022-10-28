// SPDX-License-Identifier: MIT
// Carbonable Contracts for Cairo v0.0.1 (erc3525/IERC3525Receiver.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525Receiver {
    func onERC3525Received(
        operator,
        from_token_id: Uint256,
        to_token_id: Uint256,
        value: Uint256,
        data_len,
        data: felt*,
    ) -> (selector,) {
    }
}
