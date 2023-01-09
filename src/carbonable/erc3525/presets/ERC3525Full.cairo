// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256, uint256_eq

from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.library import ERC3525
from carbonable.erc3525.extensions.slotapprovable.library import ERC3525SlotApprovable
from carbonable.erc3525.extensions.slotenumerable.library import (
    ERC3525SlotEnumerable,
    _add_token_to_slot_enumeration,
)

//
// Constructor
//

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, decimals: felt
) {
    ERC721.initializer(name, symbol);
    ERC721Enumerable.initializer();
    ERC3525.initializer(decimals);
    ERC3525SlotApprovable.initializer();
    ERC3525SlotEnumerable.initializer();
    return ();
}

//
// Getters
//

//
// ERC721
//

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC721.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC721.symbol();
}

@view
func tokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (tokenURI: felt) {
    let (tokenURI: felt) = ERC721.token_uri(tokenId);
    return (tokenURI=tokenURI);
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(owner: felt) -> (
    balance: Uint256
) {
    return ERC721.balance_of(owner);
}

@view
func ownerOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    owner: felt
) {
    return ERC721.owner_of(tokenId);
}

@view
func getApproved{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) -> (approved: felt) {
    return ERC721.get_approved(tokenId);
}

@view
func isApprovedForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, operator: felt
) -> (isApproved: felt) {
    let (isApproved: felt) = ERC721.is_approved_for_all(owner, operator);
    return (isApproved=isApproved);
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply) = ERC721Enumerable.total_supply();
    return (totalSupply=totalSupply);
}

@view
func tokenByIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId) = ERC721Enumerable.token_by_index(index);
    return (tokenId=tokenId);
}

@view
func tokenOfOwnerByIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId) = ERC721Enumerable.token_of_owner_by_index(owner, index);
    return (tokenId=tokenId);
}

//
// ERC165
//

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    interfaceId: felt
) -> (success: felt) {
    return ERC165.supports_interface(interfaceId);
}

//
// ERC3525
//

@view
func valueDecimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    return ERC3525.value_decimals();
}

@view
func valueOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    balance: Uint256
) {
    return ERC3525.balance_of(tokenId);
}

@view
func slotOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(tokenId: Uint256) -> (
    slot: Uint256
) {
    return ERC3525.slot_of(tokenId);
}

@view
func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, operator: felt
) -> (amount: Uint256) {
    return ERC3525.allowance(tokenId, operator);
}

@view
func totalValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(slot: Uint256) -> (
    total: Uint256
) {
    return ERC3525.total_value(slot);
}

//
// External functions
//

//
// ERC721
//

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    ERC3525SlotApprovable.approve(to, tokenId);
    return ();
}

@external
func setApprovalForAll{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    operator: felt, approved: felt
) {
    ERC721.set_approval_for_all(operator, approved);
    return ();
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    ERC721.transfer_from(from_, to, tokenId);
    return ();
}

@external
func safeTransferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*
) {
    ERC721.safe_transfer_from(from_, to, tokenId, data_len, data);
    return ();
}

//
// ERC3525
//

@external
func approveValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, operator: felt, value: Uint256
) {
    ERC3525SlotApprovable.approve_value(tokenId, operator, value);
    return ();
}

@external
func transferValueFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    fromTokenId: Uint256, toTokenId: Uint256, to: felt, value: Uint256
) -> (newTokenId: Uint256) {
    alloc_locals;
    let (local new_token_id: Uint256) = ERC3525SlotApprovable.transfer_from(
        fromTokenId, toTokenId, to, value
    );

    if (to != 0) {
        // Keep enumerability
        let (slot) = ERC3525.slot_of(fromTokenId);
        _add_token_to_slot_enumeration(slot, new_token_id);
        return (newTokenId=new_token_id);
    }
    return (newTokenId=new_token_id);
}

//
// SlotApprovable
//

@external
func setApprovalForSlot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, slot: Uint256, operator: felt, approved: felt
) {
    ERC3525SlotApprovable.set_approval_for_slot(owner, slot, operator, approved);
    return ();
}

@external
func isApprovedForSlot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, slot: Uint256, operator: felt
) -> (is_approved: felt) {
    let (is_approved) = ERC3525SlotApprovable.is_approved_for_slot(owner, slot, operator);
    return (is_approved=is_approved);
}

//
// ERC3525SlotEnumerable
//

@view
func slotCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    count: Uint256
) {
    return ERC3525SlotEnumerable.slot_count();
}

@view
func slotByIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    index: Uint256
) -> (slot: Uint256) {
    return ERC3525SlotEnumerable.slot_by_index(index);
}

@view
func tokenSupplyInSlot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    slot: Uint256
) -> (totalAmount: Uint256) {
    let (totalAmount) = ERC3525SlotEnumerable.token_supply_in_slot(slot);
    return (totalAmount=totalAmount);
}

@view
func tokenInSlotByIndex{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    slot: Uint256, index: Uint256
) -> (tokenId: Uint256) {
    let (tokenId) = ERC3525SlotEnumerable.token_in_slot_by_index(slot, index);
    return (tokenId=tokenId);
}

//
// Helpers
//

//
// Merge and Split
//

@view
func split{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, amounts_len: felt, amounts: Uint256*
) -> (token_ids_len: felt, token_ids: Uint256*) {
    alloc_locals;

    let is_len_valid = is_le(amounts_len, 255);
    with_attr error_message("ERC3525: split length too large") {
        assert 1 = is_len_valid;
    }

    let is_len_valid = is_le(2, amounts_len);
    with_attr error_message("ERC3525: split length too low") {
        assert 1 = is_len_valid;
    }

    let (local new_token_ids: Uint256*) = alloc();
    let (owner) = ERC721.owner_of(tokenId);
    _split_iter(owner, tokenId, amounts_len, amounts, new_token_ids, 1);
    return (token_ids_len=amounts_len, token_ids=new_token_ids);
}

// Private
func _split_iter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt,
    token_id: Uint256,
    amounts_len: felt,
    amounts: Uint256*,
    new_token_ids: Uint256*,
    n: felt,
) {
    alloc_locals;
    if (n == amounts_len) {
        let (value) = ERC3525.balance_of(token_id);
        let (is_eq) = uint256_eq([amounts], value);
        with_attr error_message("ERC3525: Split amounts do not sum to balance") {
            assert 1 = is_eq;
        }
        assert [new_token_ids] = token_id;
        return ();
    }

    let (new_token_id) = transferValueFrom(token_id, Uint256(0, 0), owner, [amounts]);
    assert [new_token_ids] = new_token_id;

    return _split_iter(
        owner, token_id, amounts_len, amounts + Uint256.SIZE, new_token_ids + Uint256.SIZE, n + 1
    );
}

@view
func merge{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenIds_len: felt, tokenIds: Uint256*
) {
    alloc_locals;

    let is_len_valid = is_le(tokenIds_len, 255);
    with_attr error_message("ERC3525: merge length too large") {
        assert 1 = is_len_valid;
    }

    let is_len_valid = is_le(2, tokenIds_len);
    with_attr error_message("ERC3525: merge length too low") {
        assert 1 = is_len_valid;
    }

    return _merge_iter(tokenIds_len, tokenIds, 1);
}

// Private
func _merge_iter{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_ids_len: felt, token_ids: Uint256*, n: felt
) {
    if (n == token_ids_len) {
        return ();
    }

    let (from_owner) = ERC721.owner_of(token_ids[n - 1]);
    let (to_owner) = ERC721.owner_of(token_ids[n]);
    with_attr error_message("ERC3525: merge tokens not from owner") {
        assert to_owner = from_owner;
    }

    let (value) = ERC3525.balance_of(token_ids[n - 1]);
    let (new_token_id) = transferValueFrom(token_ids[n - 1], token_ids[n], 0, value);
    ERC3525SlotEnumerable._burn(token_ids[n - 1]);

    return _merge_iter(token_ids_len, token_ids, n + 1);
}

//
// Mint and Burn
//

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, token_id: Uint256, slot: Uint256, value: Uint256
) {
    return ERC3525SlotEnumerable._mint(to, token_id, slot, value);
}

@external
func mintNew{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, slot: Uint256, value: Uint256
) -> (token_id: Uint256) {
    let (token_id) = ERC3525SlotEnumerable._mint_new(to, slot, value);
    return (token_id=token_id);
}

@external
func mintValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, value: Uint256
) {
    ERC3525._mint_value(token_id, value);
    return ();
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(token_id: Uint256) {
    let (caller) = get_caller_address();
    with_attr error_message("ERC3525: caller is not token owner nor approved") {
        ERC721._is_approved_or_owner(caller, token_id);
    }
    ERC3525SlotEnumerable._burn(token_id);
    return ();
}

@external
func burnValue{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    token_id: Uint256, value: Uint256
) {
    let (caller) = get_caller_address();
    with_attr error_message("ERC3525: caller is not token owner nor approved") {
        ERC721._is_approved_or_owner(caller, token_id);
    }
    ERC3525._burn_value(token_id, value);
    return ();
}

@external
func setTokenURI{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256, tokenURI: felt
) {
    ERC721._set_token_uri(tokenId, tokenURI);
    return ();
}
