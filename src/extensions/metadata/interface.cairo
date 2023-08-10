const IERC3525_METADATA_ID: felt252 = 0xe1600902;

#[starknet::interface]
trait IERC3525Metadata<TContractState> {
    fn contract_uri(self: @TContractState) -> felt252;
    fn slot_uri(self: @TContractState, slot: u256) -> felt252;
}

#[starknet::interface]
trait IERC3525MetadataLegacy<TContractState> {
    fn contractURI(self: @TContractState) -> felt252;
    fn slotURI(self: @TContractState, slot: u256) -> felt252;
}
