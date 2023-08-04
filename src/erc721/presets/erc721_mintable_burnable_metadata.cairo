#[starknet::contract]
mod ERC721 {
    use starknet::{get_caller_address, ContractAddress};
    use cairo_erc_3525::src5::interface::ISRC5;
    use cairo_erc_3525::src5::module::SRC5;
    use cairo_erc_3525::erc721::module::ERC721;
    use cairo_erc_3525::erc721::interface::{IERC721, IERC721Mintable, IERC721Burnable};
    use cairo_erc_3525::erc721::extensions::metadata::module::ERC721Metadata;
    use cairo_erc_3525::erc721::extensions::metadata::interface::IERC721Metadata;

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252) {
        self.initializer(name, symbol);
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
    impl ERC721MintableImpl of IERC721Mintable<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_mint(ref unsafe_state, to, token_id)
        }
    }

    #[external(v0)]
    impl ERC721BurnableImpl of IERC721Burnable<ContractState> {
        fn burn(ref self: ContractState, token_id: u256) {
            // [Check] Ensure that the caller is the owner of the token
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::InternalImpl::_owner_of(@unsafe_state, token_id);
            assert(get_caller_address() == owner, 'ERC721Burnable: wrong caller');
            // [Effect] Burn the token
            ERC721::InternalImpl::_burn(ref unsafe_state, token_id)
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

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, name: felt252, symbol: felt252) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::initializer(ref unsafe_state);
            let mut unsafe_state = ERC721Metadata::unsafe_new_contract_state();
            ERC721Metadata::InternalImpl::initializer(ref unsafe_state, name, symbol);
        }
    }
}