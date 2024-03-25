#[starknet::interface]
trait IReceiver<TContractState> {
    fn called(self: @TContractState) -> bool;
}

#[starknet::contract]
mod Receiver {
    // Starknet deps
    use starknet::ContractAddress;

    // External deps
    use openzeppelin::introspection::interface::{ISRC5, ISRC5Dispatcher, ISRC5DispatcherTrait};
    use openzeppelin::introspection::src5::SRC5Component;
    use cairo_erc_3525::interface::{IERC3525Receiver, IERC3525_RECEIVER_ID};

    // Local deps
    use super::IReceiver;

    // Components
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // Component implementations
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        _called: bool
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
    }


    #[constructor]
    fn constructor(ref self: ContractState) {
        self.initializer();
    }

    #[external(v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            self.src5.supports_interface(interface_id)
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
            self.src5.register_interface(IERC3525_RECEIVER_ID);
        }
    }
}
