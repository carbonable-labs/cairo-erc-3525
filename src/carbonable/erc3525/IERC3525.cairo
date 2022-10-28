// SPDX-License-Identifier: MIT
// Carbonable Contracts for Cairo v0.0.1 (erc3525/IERC3525.cairo)

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525 {
    func valueDecimals() -> (decimals: felt) {
    }

    func balanceOf(token_id: Uint256) -> (balance: Uint256) {
    }

    func slotOf(token_id: Uint256) -> (slot: Uint256) {
    }

    func approve(token_id: Uint256, operator, value: Uint256) {
    }

    func allowance(token_id: Uint256, operator) -> (amount: Uint256) {
    }

    func transferFrom(from_token_id: Uint256, to_token_id: Uint256, value: Uint256) {
    }

    func transferFrom(from_token_id, to: Uint256, value: Uint256) -> (to_token_id: Uint256) {
    }
}
