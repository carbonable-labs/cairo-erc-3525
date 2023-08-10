#[starknet::contract]
mod ERC3525 {
    use starknet::{get_caller_address, ContractAddress};
    use cairo_erc_721::src5::interface::ISRC5;
    use cairo_erc_721::src5::module::SRC5;
    use cairo_erc_721::module::ERC721;
    use cairo_erc_721::interface::IERC721;
    use cairo_erc_721::extensions::metadata::module::ERC721Metadata;
    use cairo_erc_721::extensions::metadata::interface::IERC721Metadata;
    use cairo_erc_3525::module::ERC3525;
    use cairo_erc_3525::interface::IERC3525;
    use cairo_erc_3525::extensions::metadata::module::ERC3525Metadata;
    use cairo_erc_3525::extensions::metadata::interface::IERC3525Metadata;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252, value_decimals: u8) {
        self.initializer(name, symbol, value_decimals);
    }

    #[external(v0)]
    impl ERC721Impl of IERC721<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::balance_of(@unsafe_state, account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::owner_of(@unsafe_state, token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::get_approved(@unsafe_state, token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::is_approved_for_all(@unsafe_state, owner, operator)
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::approve(ref unsafe_state, to, token_id)
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::set_approval_for_all(ref unsafe_state, operator, approved)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::transfer_from(ref unsafe_state, from, to, token_id)
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::safe_transfer_from(ref unsafe_state, from, to, token_id, data)
        }
    }

    #[external(v0)]
    impl ERC721MetadataImpl of IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            let unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::ERC721MetadataImpl::name(@unsafe_state)
        }

        fn symbol(self: @ContractState) -> felt252 {
            let unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::ERC721MetadataImpl::symbol(@unsafe_state)
        }

        fn token_uri(self: @ContractState, token_id: u256) -> felt252 {
            let unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::ERC721MetadataImpl::token_uri(@unsafe_state, token_id)
        }
    }

    #[external(v0)]
    impl ERC3525Impl of IERC3525<ContractState> {
        fn value_decimals(self: @ContractState) -> u8 {
            let unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::ERC3525Impl::value_decimals(@unsafe_state)
        }

        fn value_of(self: @ContractState, token_id: u256) -> u256 {
            let unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::ERC3525Impl::value_of(@unsafe_state, token_id)
        }

        fn slot_of(self: @ContractState, token_id: u256) -> u256 {
            let unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::ERC3525Impl::slot_of(@unsafe_state, token_id)
        }

        fn approve_value(
            ref self: ContractState, token_id: u256, operator: ContractAddress, value: u256
        ) {
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::ERC3525Impl::approve_value(ref unsafe_state, token_id, operator, value)
        }

        fn allowance(self: @ContractState, token_id: u256, operator: ContractAddress) -> u256 {
            let unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::ERC3525Impl::allowance(@unsafe_state, token_id, operator)
        }

        fn transfer_value_from(
            ref self: ContractState,
            from_token_id: u256,
            to_token_id: u256,
            to: ContractAddress,
            value: u256
        ) -> u256 {
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::ERC3525Impl::transfer_value_from(
                ref unsafe_state, from_token_id, to_token_id, to, value
            )
        }
    }

    #[external(v0)]
    impl ERC3525MetadataImpl of IERC3525Metadata<ContractState> {
        fn contract_uri(self: @ContractState) -> felt252 {
            let unsafe_state = ERC3525Metadata::unsafe_new_contract_state();
            ERC3525Metadata::ERC3525MetadataImpl::contract_uri(@unsafe_state)
        }

        fn slot_uri(self: @ContractState, slot: u256) -> felt252 {
            let unsafe_state = ERC3525Metadata::unsafe_new_contract_state();
            ERC3525Metadata::ERC3525MetadataImpl::slot_uri(@unsafe_state, slot)
        }
    }

    #[external(v0)]
    #[generate_trait]
    impl ExternalImpl of ExternalTrait {
        fn mint(ref self: ContractState, to: ContractAddress, slot: u256, value: u256) -> u256 {
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_mint_new(ref unsafe_state, to, slot, value)
        }

        fn burn(ref self: ContractState, token_id: u256) {
            // [Check] Ensure that the caller is the owner of the token
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::InternalImpl::_owner_of(@unsafe_state, token_id);
            assert(get_caller_address() == owner, 'ERC721Burnable: wrong caller');
            // [Effect] Burn the token
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_burn(ref unsafe_state, token_id)
        }

        fn set_token_uri(self: @ContractState, token_id: u256, token_uri: felt252) {
            let mut unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::InternalImpl::_set_token_uri(ref unsafe_state, token_id, token_uri);
        }

        fn set_contract_uri(ref self: ContractState, uri: felt252) {
            let mut unsafe_state = ERC3525Metadata::unsafe_new_contract_state();
            ERC3525Metadata::InternalImpl::_set_contract_uri(ref unsafe_state, uri)
        }

        fn set_slot_uri(ref self: ContractState, slot: u256, uri: felt252) {
            let mut unsafe_state = ERC3525Metadata::unsafe_new_contract_state();
            ERC3525Metadata::InternalImpl::_set_slot_uri(ref unsafe_state, slot, uri)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(
            ref self: ContractState, name: felt252, symbol: felt252, value_decimals: u8
        ) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::initializer(ref unsafe_state);
            let mut unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::InternalImpl::initializer(ref unsafe_state, name, symbol);
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::initializer(ref unsafe_state, value_decimals);
            let mut unsafe_state = ERC3525Metadata::unsafe_new_contract_state();
            ERC3525Metadata::InternalImpl::initializer(ref unsafe_state);
        }
    }
}
