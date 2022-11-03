// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

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
