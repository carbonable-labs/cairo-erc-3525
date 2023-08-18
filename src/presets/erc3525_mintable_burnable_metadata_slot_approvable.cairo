use starknet::ContractAddress;

#[starknet::interface]
trait IExternal<TContractState> {
    fn total_value(self: @TContractState, slot: u256) -> u256;
    fn mint(ref self: TContractState, to: ContractAddress, slot: u256, value: u256) -> u256;
    fn mint_value(ref self: TContractState, token_id: u256, value: u256);
    fn burn(ref self: TContractState, token_id: u256);
    fn burn_value(ref self: TContractState, token_id: u256, value: u256);
    fn set_token_uri(self: @TContractState, token_id: u256, token_uri: felt252);
    fn set_contract_uri(ref self: TContractState, uri: felt252);
    fn set_slot_uri(ref self: TContractState, slot: u256, uri: felt252);
}

#[starknet::contract]
mod ERC3525MintableBurnableMSA {
    use starknet::{get_caller_address, ContractAddress};
    use cairo_erc_721::src5::interface::{ISRC5, ISRC5Legacy};
    use cairo_erc_721::src5::module::SRC5;
    use cairo_erc_721::module::ERC721;
    use cairo_erc_721::interface::{IERC721, IERC721Legacy};
    use cairo_erc_721::extensions::metadata::module::ERC721Metadata;
    use cairo_erc_721::extensions::metadata::interface::{IERC721Metadata, IERC721MetadataLegacy};
    use cairo_erc_3525::module::ERC3525;
    use cairo_erc_3525::interface::{IERC3525, IERC3525Legacy};
    use cairo_erc_3525::extensions::metadata::module::ERC3525Metadata;
    use cairo_erc_3525::extensions::metadata::interface::{IERC3525Metadata, IERC3525MetadataLegacy};
    use cairo_erc_3525::extensions::slotapprovable::module::ERC3525SlotApprovable;
    use cairo_erc_3525::extensions::slotapprovable::interface::{
        IERC3525SlotApprovable, IERC3525SlotApprovableLegacy
    };

    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252, value_decimals: u8) {
        self.initializer(name, symbol, value_decimals);
    }

    #[external(v0)]
    impl SRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::SRC5Impl::supports_interface(@unsafe_state, interface_id)
        }
    }

    #[external(v0)]
    impl SRC5LegacyImpl of ISRC5Legacy<ContractState> {
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
            // Overwrite ERC721 Impl with ERC3525 SlotApprovable Impl
            let mut unsafe_state = ERC3525SlotApprovable::unsafe_new_contract_state();
            ERC3525SlotApprovable::ExternalImpl::approve(ref unsafe_state, to, token_id)
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
    impl ERC721LegacyImpl of IERC721Legacy<ContractState> {
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.balance_of(account)
        }

        fn ownerOf(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.owner_of(tokenId)
        }

        fn getApproved(self: @ContractState, tokenId: u256) -> ContractAddress {
            self.get_approved(tokenId)
        }

        fn isApprovedForAll(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.is_approved_for_all(owner, operator)
        }

        fn setApprovalForAll(ref self: ContractState, operator: ContractAddress, approved: bool) {
            self.set_approval_for_all(operator, approved)
        }

        fn transferFrom(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, tokenId: u256
        ) {
            self.transfer_from(from, to, tokenId)
        }

        fn safeTransferFrom(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            tokenId: u256,
            data: Span<felt252>
        ) {
            self.safe_transfer_from(from, to, tokenId, data)
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
    impl ERC721MetadataLegacyImpl of IERC721MetadataLegacy<ContractState> {
        fn tokenURI(self: @ContractState, tokenId: u256) -> felt252 {
            self.token_uri(tokenId)
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
            // Overwrite ERC3525 Impl with ERC3525 SlotApprovable Impl
            let mut unsafe_state = ERC3525SlotApprovable::unsafe_new_contract_state();
            ERC3525SlotApprovable::ExternalImpl::approve_value(
                ref unsafe_state, token_id, operator, value
            )
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
            // Overwrite ERC3525 Impl with ERC3525 SlotApprovable Impl
            let mut unsafe_state = ERC3525SlotApprovable::unsafe_new_contract_state();
            ERC3525SlotApprovable::ExternalImpl::transfer_value_from(
                ref unsafe_state, from_token_id, to_token_id, to, value
            )
        }
    }

    #[external(v0)]
    impl ERC3525LegacyImpl of IERC3525Legacy<ContractState> {
        fn valueDecimals(self: @ContractState) -> u8 {
            self.value_decimals()
        }

        fn valueOf(self: @ContractState, tokenId: u256) -> u256 {
            self.value_of(tokenId)
        }

        fn slotOf(self: @ContractState, tokenId: u256) -> u256 {
            self.slot_of(tokenId)
        }

        fn approveValue(
            ref self: ContractState, tokenId: u256, operator: ContractAddress, value: u256
        ) {
            self.approve_value(tokenId, operator, value)
        }

        fn transferValueFrom(
            ref self: ContractState,
            fromTokenId: u256,
            toTokenId: u256,
            to: ContractAddress,
            value: u256
        ) -> u256 {
            self.transfer_value_from(fromTokenId, toTokenId, to, value)
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
    impl ERC3525MetadataLegacyImpl of IERC3525MetadataLegacy<ContractState> {
        fn contractURI(self: @ContractState) -> felt252 {
            self.contract_uri()
        }

        fn slotURI(self: @ContractState, slot: u256) -> felt252 {
            self.slot_uri(slot)
        }
    }

    #[external(v0)]
    impl ERC3525SlotApprovableImpl of IERC3525SlotApprovable<ContractState> {
        fn set_approval_for_slot(
            ref self: ContractState,
            owner: ContractAddress,
            slot: u256,
            operator: ContractAddress,
            approved: bool
        ) {
            let mut unsafe_state = ERC3525SlotApprovable::unsafe_new_contract_state();
            ERC3525SlotApprovable::ERC3525SlotApprovableImpl::set_approval_for_slot(
                ref unsafe_state, owner, slot, operator, approved
            )
        }

        fn is_approved_for_slot(
            self: @ContractState, owner: ContractAddress, slot: u256, operator: ContractAddress
        ) -> bool {
            let unsafe_state = ERC3525SlotApprovable::unsafe_new_contract_state();
            ERC3525SlotApprovable::ERC3525SlotApprovableImpl::is_approved_for_slot(
                @unsafe_state, owner, slot, operator
            )
        }
    }

    #[external(v0)]
    impl ERC3525SlotApprovableLegacyImpl of IERC3525SlotApprovableLegacy<ContractState> {
        fn setApprovalForSlot(
            ref self: ContractState,
            owner: ContractAddress,
            slot: u256,
            operator: ContractAddress,
            approved: bool
        ) {
            self.set_approval_for_slot(owner, slot, operator, approved)
        }

        fn isApprovedForSlot(
            self: @ContractState, owner: ContractAddress, slot: u256, operator: ContractAddress
        ) -> bool {
            self.is_approved_for_slot(owner, slot, operator)
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
            let mut unsafe_state = ERC3525SlotApprovable::unsafe_new_contract_state();
            ERC3525SlotApprovable::InternalImpl::initializer(ref unsafe_state);
        }
    }
}
