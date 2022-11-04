// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525Metadata {
    func contractUri() -> (uri: felt) {
    }

    func slotUri(slot: Uint256) -> (uri: felt) {
    }
}
