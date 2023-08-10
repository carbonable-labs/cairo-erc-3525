#[starknet::contract]
mod SRC5 {
    use cairo_erc_3525::src5::interface::{ISRC5_ID, ISRC5};

    #[storage]
    struct Storage {
        supported_interfaces: LegacyMap<felt252, bool>
    }

    #[external(v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            if interface_id == ISRC5_ID {
                return true;
            }
            self.supported_interfaces.read(interface_id)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn register_interface(ref self: ContractState, interface_id: felt252) {
            self.supported_interfaces.write(interface_id, true);
        }

        fn deregister_interface(ref self: ContractState, interface_id: felt252) {
            assert(interface_id != ISRC5_ID, 'SRC5: invalid id');
            self.supported_interfaces.write(interface_id, false);
        }
    }
}
