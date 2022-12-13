// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq, ALL_ONES

// Project dependencies
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc721.library import ERC721
from openzeppelin.token.erc721.IERC721 import IERC721
from openzeppelin.token.erc721.IERC721Metadata import IERC721Metadata

from carbonable.erc3525.IERC3525Full import IERC3525Full as IERC3525

namespace assert_that {
    func total_supply_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, instance}(
        expected_supply_felt
    ) {
        alloc_locals;
        let expected_supply = Uint256(expected_supply_felt, 0);
        let (returned_supply) = IERC3525.totalSupply(instance);
        let (is_eq) = uint256_eq(returned_supply, expected_supply);
        with_attr error_message("totalSupply is unexpected") {
            assert 1 = is_eq;
        }
        return ();
    }

    func slot_of_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, instance}(
        token_id_felt, expected_slot_felt
    ) {
        alloc_locals;
        let token_id = Uint256(token_id_felt, 0);
        let expected_slot = Uint256(expected_slot_felt, 0);
        let (returned_slot: Uint256) = IERC3525.slotOf(instance, token_id);
        let (is_eq) = uint256_eq(returned_slot, expected_slot);
        assert 1 = is_eq;
        return ();
    }

    func owner_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, instance}(
        token_id_felt, expected_owner
    ) {
        let token_id = Uint256(token_id_felt, 0);
        let (returned_owner) = IERC3525.ownerOf(instance, token_id);
        assert returned_owner = expected_owner;
        return ();
    }

    func ERC3525_balance_of_is{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, instance
    }(token_id_felt, expected_balance_felt) {
        alloc_locals;
        let expected_balance = Uint256(expected_balance_felt, 0);
        let token_id = Uint256(token_id_felt, 0);

        let (returned_balance: Uint256) = IERC3525.valueOf(instance, token_id);
        let (is_eq) = uint256_eq(returned_balance, expected_balance);
        with_attr error_message("Can't assert balance") {
            assert 1 = is_eq;
        }
        return ();
    }

    func allowance_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, instance}(
        token_id_felt, operator: felt, expected_allowance_felt
    ) {
        alloc_locals;
        let token_id = Uint256(token_id_felt, 0);
        let expected_allowance = Uint256(expected_allowance_felt, 0);
        let (local returned_allowance: Uint256) = IERC3525.allowance(instance, token_id, operator);
        let (is_eq) = uint256_eq(returned_allowance, expected_allowance);
        assert 1 = is_eq;
        return ();
    }

    func slot_count_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, instance}(
        expected_count_felt: felt
    ) {
        alloc_locals;
        let (returned_slot_count) = IERC3525.slotCount(instance);
        let expected_slot_count = Uint256(expected_count_felt, 0);
        let (is_eq) = uint256_eq(returned_slot_count, expected_slot_count);
        assert 1 = is_eq;
        return ();
    }

    func slot_by_index_is{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, instance
    }(index_felt: felt, expected_slot_felt: felt) {
        alloc_locals;
        let index = Uint256(index_felt, 0);
        let expected_slot = Uint256(expected_slot_felt, 0);
        let (returned_slot) = IERC3525.slotByIndex(instance, index);
        let (is_eq) = uint256_eq(returned_slot, expected_slot);
        assert 1 = is_eq;
        return ();
    }

    func token_supply_in_slot_is{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, instance
    }(slot_felt: felt, expected_supply_felt: felt) {
        alloc_locals;
        let slot = Uint256(slot_felt, 0);
        let expected_supply = Uint256(expected_supply_felt, 0);
        let (returned_supply) = IERC3525.tokenSupplyInSlot(instance, slot);
        let (is_eq) = uint256_eq(returned_supply, expected_supply);
        assert 1 = is_eq;
        return ();
    }

    func token_in_slot_by_index_is{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, instance
    }(slot_felt: felt, index_felt: felt, expected_token_id_felt: felt) {
        alloc_locals;
        let slot = Uint256(slot_felt, 0);
        let index = Uint256(index_felt, 0);
        let expected_token_id = Uint256(expected_token_id_felt, 0);
        let (returned_token_id) = IERC3525.tokenInSlotByIndex(instance, slot, index);
        let (is_eq) = uint256_eq(returned_token_id, expected_token_id);
        assert 1 = is_eq;
        return ();
    }
}
