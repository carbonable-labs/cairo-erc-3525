use starknet::ContractAddress;

const IERC3525_ID: felt252 = 0xd5358140;
const IERC3525_RECEIVER_ID: felt252 = 0x009ce20b;

#[starknet::interface]
trait IERC3525<TContractState> {
    fn value_decimals(self: @TContractState) -> u8;
    fn value_of(self: @TContractState, token_id: u256) -> u256;
    fn slot_of(self: @TContractState, token_id: u256) -> u256;
    fn approve_value(
        ref self: TContractState, token_id: u256, operator: ContractAddress, value: u256
    );
    fn allowance(self: @TContractState, token_id: u256, operator: ContractAddress) -> u256;
    fn transfer_value_from(
        ref self: TContractState,
        from_token_id: u256,
        to_token_id: u256,
        to: ContractAddress,
        value: u256
    ) -> u256;
}

#[starknet::interface]
trait IERC3525Legacy<TContractState> {
    fn valueDecimals(self: @TContractState) -> u8;
    fn valueOf(self: @TContractState, tokenId: u256) -> u256;
    fn slotOf(self: @TContractState, tokenId: u256) -> u256;
    fn approveValue(
        ref self: TContractState, tokenId: u256, operator: ContractAddress, value: u256
    );
    fn transferValueFrom(
        ref self: TContractState,
        fromTokenId: u256,
        toTokenId: u256,
        to: ContractAddress,
        value: u256
    ) -> u256;
}

#[starknet::interface]
trait IERC3525Receiver<TContractState> {
    fn on_erc3525_received(
        ref self: TContractState,
        operator: ContractAddress,
        from_token_id: u256,
        to_token_id: u256,
        value: u256,
        data: Span<felt252>,
    ) -> felt252;
}

#[starknet::interface]
trait IERC3525ReceiverLegacy<TContractState> {
    fn onERC3525Received(
        ref self: TContractState,
        operator: ContractAddress,
        fromTokenId: u256,
        toTokenId: u256,
        value: u256,
        data: Span<felt252>,
    ) -> felt252;
}
