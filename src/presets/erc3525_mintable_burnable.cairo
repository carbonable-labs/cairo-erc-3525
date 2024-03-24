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
    use openzeppelin::introspection::src5::SRC5Component;

    // ERC721
    use openzeppelin::token::erc721::erc721::ERC721Component;
    use openzeppelin::token::erc721::interface::{
        IERC721, IERC721CamelOnly, IERC721Metadata, IERC721MetadataCamelOnly
    };

    // ERC3525
    use cairo_erc_3525::module::ERC3525Component;
    use cairo_erc_3525::interface::{IERC3525, IERC3525CamelOnly};

    // Declare components
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: ERC3525Component, storage: erc3525, event: ERC3525Event);

    // Component implementations
    // TODO embed missing ABIs
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525Impl = ERC3525Component::ERC3525Impl<ContractState>;
    impl ERC3525InternalImpl = ERC3525Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        erc3525: ERC3525Component::Storage,
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
    }

    #[constructor]
    fn constructor(ref self: ContractState, value_decimals: u8) {
        self.initializer(value_decimals);
    }

    // TODO check support for the following impls:
    // impl SRC5Impl of ISRC5<ContractState> {
    // impl SRC5CamelImpl of ISRC5Camel<ContractState> {
    // impl ERC721Impl of IERC721<ContractState> {
    // impl ERC3525Impl of IERC3525<ContractState> {

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
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, value_decimals: u8) {
            self.erc721.initializer("", "", "");
            self.erc3525.initializer(value_decimals);
        }
    }
}
