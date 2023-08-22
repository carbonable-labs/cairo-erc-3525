#[starknet::interface]
trait IReceiver<TContractState> {
    fn called(self: @TContractState) -> bool;
}

#[starknet::contract]
mod Receiver {

    use cairo_erc_721::src5::interface::{ISRC5, ISRC5Legacy};
    use cairo_erc_721::src5::module::SRC5;
    use cairo_erc_721::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
    use cairo_erc_3525::interface::{IERC3525Receiver, IERC3525_RECEIVER_ID};
    use starknet::ContractAddress;
    use super::IReceiver;

    #[storage]
    struct Storage {
        _called: bool
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.initializer();
    }

    #[external(v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::SRC5Impl::supports_interface(@unsafe_state, interface_id)
        }
    }

    #[external(v0)]
    impl ReceiverImpl of IReceiver<ContractState> {
        fn called(self: @ContractState) -> bool {
            self._called.read()
        }
    }

    #[external(v0)]
    impl ERC3525ReceiverImpl of IERC3525Receiver<ContractState> {
        fn on_erc3525_received(
            ref self: ContractState,
            operator: ContractAddress,
            from_token_id: u256,
            to_token_id: u256,
            value: u256,
            data: Span<felt252>,
        ) -> felt252 {
            self._called.write(true);
            IERC3525_RECEIVER_ID
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState) {
            // [Effect] Register interfaces
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, IERC3525_RECEIVER_ID);
        }
    }
}
