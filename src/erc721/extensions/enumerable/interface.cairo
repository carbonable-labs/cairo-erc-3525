use starknet::ContractAddress;

const IERC721_ENUMERABLE_ID : felt252 = 0x780e9d63;

#[starknet::interface]
trait IERC721Enumerable<TContractState> {
    fn total_supply(self: @TContractState) -> u256;
    fn token_by_index(self: @TContractState, index: u256) -> u256;
    fn token_of_owner_by_index(self: @TContractState, owner: ContractAddress, index: u256) -> u256;
}

#[starknet::interface]
trait IERC721EnumerableLegacy<TContractState> {
    fn totalSupply(self: @TContractState) -> u256;
    fn tokenByIndex(self: @TContractState, index: u256) -> u256;
    fn tokenOfOwnerByIndex(self: @TContractState, owner: ContractAddress, index: u256) -> u256;
}