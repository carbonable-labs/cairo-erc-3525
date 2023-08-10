use starknet::ContractAddress;

const IERC3525_SLOT_APPROVABLE_ID: felt252 = 0xb688be58;

#[starknet::interface]
trait IERC3525SlotApprovable<TContractState> {
    fn set_approval_for_slot(
        ref self: TContractState,
        owner: ContractAddress,
        slot: u256,
        operator: ContractAddress,
        approved: bool
    );
    fn is_approved_for_slot(
        self: @TContractState, owner: ContractAddress, slot: u256, operator: ContractAddress
    ) -> bool;
}

#[starknet::interface]
trait IERC3525SlotApprovableLegacy<TContractState> {
    fn setApprovalForSlot(
        ref self: TContractState,
        owner: ContractAddress,
        slot: u256,
        operator: ContractAddress,
        approved: bool
    );
    fn isApprovedForSlot(
        self: @TContractState, owner: ContractAddress, slot: u256, operator: ContractAddress
    ) -> bool;
}
