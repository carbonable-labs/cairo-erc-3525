use starknet::ContractAddress;

#[starknet::interface]
trait IExternal<TContractState> {
    fn total_value(self: @TContractState, slot: u256) -> u256;
    fn mint(ref self: TContractState, to: ContractAddress, slot: u256, value: u256) -> u256;
    fn mint_value(ref self: TContractState, token_id: u256, value: u256);
    fn burn(ref self: TContractState, token_id: u256);
    fn burn_value(ref self: TContractState, token_id: u256, value: u256);
    fn set_base_uri(ref self: TContractState, base_uri: ByteArray);
    fn set_contract_uri(ref self: TContractState, uri: felt252);
    fn set_slot_uri(ref self: TContractState, slot: u256, uri: felt252);
}

#[starknet::contract]
mod ERC3525MintableBurnableMSA {
    // Starknet deps
    use starknet::{get_caller_address, ContractAddress};

    // SRC5
    use openzeppelin::introspection::interface::{ISRC5, ISRC5Camel};
    use openzeppelin::introspection::src5::SRC5Component;

    // ERC721
    use openzeppelin::token::erc721::erc721::ERC721Component;
    use openzeppelin::token::erc721::interface::{
        IERC721, IERC721CamelOnly, IERC721Metadata, IERC721MetadataCamelOnly
    };

    // ERC3525
    use cairo_erc_3525::module::ERC3525Component;
    use cairo_erc_3525::interface::{IERC3525, IERC3525CamelOnly};

    // ERC3525 - Metadata
    use cairo_erc_3525::extensions::metadata::module::ERC3525MetadataComponent;
    use cairo_erc_3525::extensions::metadata::interface::{
        IERC3525Metadata, IERC3525MetadataCamelOnly
    };

    // ERC3525 - SlotAprovable
    use cairo_erc_3525::extensions::slotapprovable::module::ERC3525SlotApprovableComponent;
    use cairo_erc_3525::extensions::slotapprovable::interface::{
        IERC3525SlotApprovable, IERC3525SlotApprovableCamelOnly
    };

    // Declare components
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC3525Component, storage: erc3525, event: ERC3525Event);
    component!(
        path: ERC3525MetadataComponent, storage: erc3525_metadata, event: ERC3525MetadataEvent
    );
    component!(
        path: ERC3525SlotApprovableComponent,
        storage: erc3525_slot_approvable,
        event: ERC3525SlotApprovableEvent
    );

    // Component implementations
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5CamelImpl = SRC5Component::SRC5CamelImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnlyImpl =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl ERC3525InternalImpl = ERC3525Component::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525MetadataImpl =
        ERC3525MetadataComponent::ERC3525MetadataImpl<ContractState>;
    impl ERC3525MetadataInternalImpl = ERC3525MetadataComponent::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525MetadataCamelOnlyImpl =
        ERC3525MetadataComponent::ERC3525MetadataCamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525SlotApprovableImpl =
        ERC3525SlotApprovableComponent::ERC3525SlotApprovableImpl<ContractState>;
    impl ERC3525SlotApprovableInternalImpl =
        ERC3525SlotApprovableComponent::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525SlotApprovableCamelOnlyImpl =
        ERC3525SlotApprovableComponent::ERC3525SlotApprovableCamelOnlyImpl<ContractState>;
    impl ERC3525SlotApprovableExternalImpl =
        ERC3525SlotApprovableComponent::ExternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc3525: ERC3525Component::Storage,
        #[substorage(v0)]
        erc3525_metadata: ERC3525MetadataComponent::Storage,
        #[substorage(v0)]
        erc3525_slot_approvable: ERC3525SlotApprovableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        ERC3525Event: ERC3525Component::Event,
        #[flat]
        ERC3525MetadataEvent: ERC3525MetadataComponent::Event,
        #[flat]
        ERC3525SlotApprovableEvent: ERC3525SlotApprovableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        value_decimals: u8
    ) {
        self.initializer(name, symbol, base_uri, value_decimals);
    }

    #[abi(embed_v0)]
    impl ERC721Impl of IERC721<ContractState> {
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc721.balance_of(account)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.owner_of(token_id)
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            self.erc721.get_approved(token_id)
        }

        fn is_approved_for_all(
            self: @ContractState, owner: ContractAddress, operator: ContractAddress
        ) -> bool {
            self.erc721.is_approved_for_all(owner, operator)
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            // Overwrite ERC721 Impl with ERC3525 SlotApprovable Impl
            self.erc3525_slot_approvable.approve(to, token_id)
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: ContractAddress, approved: bool
        ) {
            self.erc721.set_approval_for_all(operator, approved)
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            self.erc721.transfer_from(from, to, token_id)
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self.erc721.safe_transfer_from(from, to, token_id, data)
        }
    }

    #[abi(embed_v0)]
    impl ERC721CamelOnlyImpl of IERC721CamelOnly<ContractState> {
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

    #[abi(embed_v0)]
    impl ERC3525Impl of IERC3525<ContractState> {
        fn value_decimals(self: @ContractState) -> u8 {
            self.erc3525.value_decimals()
        }

        fn value_of(self: @ContractState, token_id: u256) -> u256 {
            self.erc3525.value_of(token_id)
        }

        fn slot_of(self: @ContractState, token_id: u256) -> u256 {
            self.erc3525.slot_of(token_id)
        }

        fn approve_value(
            ref self: ContractState, token_id: u256, operator: ContractAddress, value: u256
        ) {
            // Overwrite ERC3525 Impl with ERC3525 SlotApprovable Impl
            self.erc3525_slot_approvable.approve_value(token_id, operator, value)
        }

        fn allowance(self: @ContractState, token_id: u256, operator: ContractAddress) -> u256 {
            self.erc3525.allowance(token_id, operator)
        }

        fn transfer_value_from(
            ref self: ContractState,
            from_token_id: u256,
            to_token_id: u256,
            to: ContractAddress,
            value: u256
        ) -> u256 {
            // Overwrite ERC3525 Impl with ERC3525 SlotApprovable Impl
            self.erc3525_slot_approvable.transfer_value_from(from_token_id, to_token_id, to, value)
        }
    }

    #[abi(embed_v0)]
    impl ERC3525CamelOnlyImpl of IERC3525CamelOnly<ContractState> {
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

    #[abi(embed_v0)]
    impl ExternalImpl of super::IExternal<ContractState> {
        fn total_value(self: @ContractState, slot: u256) -> u256 {
            self.erc3525._total_value(slot)
        }

        fn mint(ref self: ContractState, to: ContractAddress, slot: u256, value: u256) -> u256 {
            self.erc3525._mint_new(to, slot, value)
        }

        fn mint_value(ref self: ContractState, token_id: u256, value: u256) {
            self.erc3525._mint_value(token_id, value)
        }

        fn burn(ref self: ContractState, token_id: u256) {
            // [Check] Ensure that the caller is the owner of the token
            let owner = self.erc721._owner_of(token_id);
            assert(get_caller_address() == owner, 'ERC3525Burnable: wrong caller');
            // [Effect] Burn the token
            self.erc3525._burn(token_id)
        }

        fn burn_value(ref self: ContractState, token_id: u256, value: u256) {
            // [Check] Ensure that the caller is the owner of the token
            let owner = self.erc721._owner_of(token_id);
            assert(get_caller_address() == owner, 'ERC3525Burnable: wrong caller');
            // [Effect] Burn the token
            self.erc3525._burn_value(token_id, value)
        }

        fn set_base_uri(ref self: ContractState, base_uri: ByteArray) {
            self.erc721._set_base_uri(base_uri)
        }

        fn set_contract_uri(ref self: ContractState, uri: felt252) {
            self.erc3525_metadata._set_contract_uri(uri)
        }

        fn set_slot_uri(ref self: ContractState, slot: u256, uri: felt252) {
            self.erc3525_metadata._set_slot_uri(slot, uri)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(
            ref self: ContractState,
            name: ByteArray,
            symbol: ByteArray,
            base_uri: ByteArray,
            value_decimals: u8
        ) {
            self.erc721.initializer(name, symbol, base_uri);
            self.erc3525.initializer(value_decimals);
            self.erc3525_metadata.initializer();
            self.erc3525_slot_approvable.initializer();
        }
    }
}
