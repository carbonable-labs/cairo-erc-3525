// SPDX-License-Identifier: MIT
// Carbonable Contracts for Cairo v0.0.1 (erc3525/IERC3525Metadata.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525Metadata {
    func contractUri() -> (uri,) {
    }

    func slotUri(slot: Uint256) -> (uri,) {
    }
}
