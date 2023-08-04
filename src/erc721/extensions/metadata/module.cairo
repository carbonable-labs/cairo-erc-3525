#[starknet::contract]
mod ERC721Metadata {
    use starknet::ContractAddress;
    use cairo_erc_3525::src5::module::SRC5;
    use cairo_erc_3525::erc721::module::ERC721;
    use cairo_erc_3525::erc721::extensions::metadata::interface::{IERC721_METADATA_ID, IERC721Metadata};

    #[storage]
    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _token_uri: LegacyMap<u256, felt252>,
    }

    #[external(v0)]
    impl ERC721MetadataImpl of IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self._name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self._symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            assert(ERC721::InternalImpl::_exists(@unsafe_state, token_id), 'ERC721: invalid token ID');
            self._token_uri.read(token_id)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, name: felt252, symbol: felt252) {
            self._name.write(name);
            self._symbol.write(symbol);
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, IERC721_METADATA_ID);
        }

        fn _set_token_uri(ref self: ContractState, token_id: u256, token_uri: felt252) {
            self._token_uri.write(token_id, token_uri);
        }
    }
}