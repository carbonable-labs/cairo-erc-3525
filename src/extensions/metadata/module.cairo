#[starknet::contract]
mod ERC3525Metadata {
    use starknet::ContractAddress;
    use cairo_erc_721::src5::module::SRC5;
    use cairo_erc_3525::extensions::metadata::interface::{IERC3525_METADATA_ID, IERC3525Metadata};

    #[storage]
    struct Storage {
        _contract_uri: felt252,
        _slot_uri: LegacyMap<u256, felt252>,
    }

    #[external(v0)]
    impl ERC3525MetadataImpl of IERC3525Metadata<ContractState> {
        fn contract_uri(self: @ContractState) -> felt252 {
            self._contract_uri.read()
        }

        fn slot_uri(self: @ContractState, slot: u256) -> felt252 {
            self._slot_uri.read(slot)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState) {
            // [Effect] Register interfaces
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, IERC3525_METADATA_ID);
        }

        fn _set_contract_uri(ref self: ContractState, uri: felt252) {
            // [Effect] Store uri
            self._contract_uri.write(uri);
        }

        fn _set_slot_uri(ref self: ContractState, slot: u256, uri: felt252) {
            // [Effect] Store uri
            self._slot_uri.write(slot, uri);
        }
    }
}
