use starknet::ContractAddress;

const IERC3525_SLOT_ENUMERABLE_ID: felt252 = 0x3b741b9e;

#[starknet::interface]
trait IERC3525SlotEnumerable<TContractState> {
    fn slot_count(self: @TContractState) -> u256;
    fn slot_by_index(self: @TContractState, index: u256) -> u256;
    fn token_supply_in_slot(self: @TContractState, slot: u256) -> u256;
    fn token_in_slot_by_index(self: @TContractState, slot: u256, index: u256) -> u256;
}

#[starknet::interface]
trait IERC3525SlotEnumerableCamelOnly<TContractState> {
    fn slotCount(self: @TContractState) -> u256;
    fn slotByIndex(self: @TContractState, index: u256) -> u256;
    fn tokenSupplyInSlot(self: @TContractState, slot: u256) -> u256;
    fn tokenInSlotByIndex(self: @TContractState, slot: u256, index: u256) -> u256;
}
