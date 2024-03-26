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
mod ERC3525MintableBurnableMetadata {
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

    // Declare components
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC3525Component, storage: erc3525, event: ERC3525Event);
    component!(
        path: ERC3525MetadataComponent, storage: erc3525_metadata, event: ERC3525MetadataEvent
    );

    // Component implementations
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525Impl = ERC3525Component::ERC3525Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525CamelOnlyImpl =
        ERC3525Component::ERC3525CamelOnlyImpl<ContractState>;
    impl ERC3525InternalImpl = ERC3525Component::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525MetadataImpl =
        ERC3525MetadataComponent::ERC3525MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525MetadataCamelOnlyImpl =
        ERC3525MetadataComponent::ERC3525MetadataCamelOnlyImpl<ContractState>;
    impl ERC3525MetadataInternalImpl = ERC3525MetadataComponent::InternalImpl<ContractState>;

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
        }
    }
}
