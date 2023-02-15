// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IERC3525Full {
    //
    // ERC3525
    //

    func valueDecimals() -> (decimals: felt) {
    }

    func valueOf(tokenId: Uint256) -> (balance: Uint256) {
    }

    func slotOf(tokenId: Uint256) -> (slot: Uint256) {
    }

    func approveValue(tokenId: Uint256, operator: felt, value: Uint256) {
    }

    func allowance(tokenId: Uint256, operator: felt) -> (amount: Uint256) {
    }

    func transferValueFrom(fromTokenId: Uint256, toTokenId: Uint256, to: felt, value: Uint256) -> (
        toTokenId: Uint256
    ) {
    }

    //
    // 721 Enumerable
    //

    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func balanceOf(owner: felt) -> (balance: Uint256) {
    }

    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }

    func safeTransferFrom(from_: felt, to: felt, tokenId: Uint256, data_len: felt, data: felt*) {
    }

    func transferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }

    func approve(approved: felt, tokenId: Uint256) {
    }

    func setApprovalForAll(operator: felt, approved: felt) {
    }

    func getApproved(tokenId: Uint256) -> (approved: felt) {
    }

    func isApprovedForAll(owner: felt, operator: felt) -> (isApproved: felt) {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func tokenByIndex(index: Uint256) -> (tokenId: Uint256) {
    }

    func tokenOfOwnerByIndex(owner: felt, index: Uint256) -> (tokenId: Uint256) {
    }

    func tokenURI(tokenId: Uint256) -> (uri_len: felt, uri: felt*) {
    }

    //
    // 3525 Metadata
    //

    func contractURI() -> (uri_len: felt, uri: felt*) {
    }

    func slotURI(slot: Uint256) -> (uri_len: felt, uri: felt*) {
    }

    //
    // Slot Approvable
    //

    func setApprovalForSlot(owner: felt, slot: Uint256, operator: felt, approved: felt) {
    }

    func isApprovedForSlot(owner: felt, slot: Uint256, operator: felt) -> (is_approved: felt) {
    }

    //
    // Slot Enumerable
    //

    func slotCount() -> (count: Uint256) {
    }

    func slotByIndex(index: Uint256) -> (slot: Uint256) {
    }

    func tokenSupplyInSlot(slot: Uint256) -> (totalAmount: Uint256) {
    }

    func tokenInSlotByIndex(slot: Uint256, index: Uint256) -> (tokenId: Uint256) {
    }

    //
    // Mintable Burnable
    //

    func mint(to: felt, token_id: Uint256, slot: Uint256, value: Uint256) {
    }

    func mintNew(to: felt, slot: Uint256, value: Uint256) -> (token_id: Uint256) {
    }

    func mintValue(tokenId: Uint256, value: Uint256) {
    }

    func burn(tokenId: Uint256) {
    }

    func burnValue(tokenId: Uint256, value: Uint256) {
    }

    //
    // Additional methods
    //

    func split(tokenId: Uint256, amounts_len: felt, amounts: Uint256*) -> (
        token_ids_len: felt, token_ids: Uint256*
    ) {
    }

    func merge(tokenIds_len: felt, tokenIds: Uint256*) {
    }

    func totalValue(slot: Uint256) -> (total: Uint256) {
    }

    func setTokenImage(uri_len: felt, uri: felt*) {
    }
}
