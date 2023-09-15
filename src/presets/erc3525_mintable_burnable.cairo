use starknet::ContractAddress;

#[starknet::interface]
trait IExternal<TContractState> {
    fn total_value(self: @TContractState, slot: u256) -> u256;
    fn mint(ref self: TContractState, to: ContractAddress, slot: u256, value: u256) -> u256;
    fn mint_value(ref self: TContractState, token_id: u256, value: u256);
    fn burn(ref self: TContractState, token_id: u256);
    fn burn_value(ref self: TContractState, token_id: u256, value: u256);
}

#[starknet::contract]
mod ERC3525MintableBurnable {
    // Starknet deps
    use starknet::{get_caller_address, ContractAddress};

    // SRC5
    use openzeppelin::introspection::interface::{ISRC5, ISRC5Camel};
    use openzeppelin::introspection::src5::SRC5;

    // ERC721
    use openzeppelin::token::erc721::erc721::ERC721;
    use openzeppelin::token::erc721::interface::{
        IERC721, IERC721CamelOnly, IERC721Metadata, IERC721MetadataCamelOnly
    };

    // ERC3525
    use cairo_erc_3525::module::ERC3525;
    use cairo_erc_3525::interface::{IERC3525, IERC3525CamelOnly};

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState, value_decimals: u8) {
        self.initializer(value_decimals);
    }

    #[external(v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::SRC5Impl::supports_interface(@unsafe_state, interface_id)
        }
    }

    #[external(v0)]
    impl SRC5CamelImpl of ISRC5Camel<ContractState> {
        fn supportsInterface(self: @ContractState, interfaceId: felt252) -> bool {
            self.supports_interface(interfaceId)
        }
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
    impl ExternalImpl of super::IExternal<ContractState> {
        fn total_value(self: @ContractState, slot: u256) -> u256 {
            let unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_total_value(@unsafe_state, slot)
        }

        fn mint(ref self: ContractState, to: ContractAddress, slot: u256, value: u256) -> u256 {
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_mint_new(ref unsafe_state, to, slot, value)
        }

        fn mint_value(ref self: ContractState, token_id: u256, value: u256) {
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_mint_value(ref unsafe_state, token_id, value)
        }

        fn burn(ref self: ContractState, token_id: u256) {
            // [Check] Ensure that the caller is the owner of the token
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::InternalImpl::_owner_of(@unsafe_state, token_id);
            assert(get_caller_address() == owner, 'ERC3525Burnable: wrong caller');
            // [Effect] Burn the token
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_burn(ref unsafe_state, token_id)
        }

        fn burn_value(ref self: ContractState, token_id: u256, value: u256) {
            // [Check] Ensure that the caller is the owner of the token
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::InternalImpl::_owner_of(@unsafe_state, token_id);
            assert(get_caller_address() == owner, 'ERC3525Burnable: wrong caller');
            // [Effect] Burn the token
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_burn_value(ref unsafe_state, token_id, value)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, value_decimals: u8) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::initializer(ref unsafe_state, 0, 0);
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::initializer(ref unsafe_state, value_decimals);
        }
    }
}
