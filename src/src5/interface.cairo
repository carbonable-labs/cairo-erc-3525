const ISRC5_ID: felt252 = 0x3f918d17e5ee77373b56385708f855659a07f75997f365cf87748628532a055;
const IERC165_ID: felt252 = 0x01ffc9a7;

#[starknet::interface]
trait ISRC5<TState> {
    fn supports_interface(self: @TState, interface_id: felt252) -> bool;
}
