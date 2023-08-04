const IERC721_METADATA_ID : felt252 = 0x5b5e139f;

#[starknet::interface]
trait IERC721Metadata<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn token_uri(self: @TContractState, token_id: u256) -> felt252;
}

#[starknet::interface]
trait IERC721MetadataLegacy<TContractState> {
    fn tokenUri(self: @TContractState, tokenId: u256) -> felt252;
}