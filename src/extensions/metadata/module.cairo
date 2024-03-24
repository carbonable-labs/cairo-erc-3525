#[starknet::component]
mod ERC3525MetadataComponent {
    // Starknet deps
    use starknet::ContractAddress;

    // External deps
    use openzeppelin::introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin::introspection::src5::SRC5Component::{SRC5, SRC5Camel};
    use openzeppelin::introspection::src5::SRC5Component;

    // Local deps
    use cairo_erc_3525::extensions::metadata::interface::{IERC3525_METADATA_ID, IERC3525Metadata, IERC3525MetadataCamelOnly};

    #[storage]
    struct Storage {
        _erc3525_contract_uri: felt252,
        _erc3525_slot_uri: LegacyMap<u256, felt252>,
    }

    #[embeddable_as(ERC3525MetadataImpl)]
    impl ERC3525Metadata<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>
    > of IERC3525Metadata<ComponentState<TContractState>> {
        fn contract_uri(self: @ComponentState<TContractState>) -> felt252 {
            self._erc3525_contract_uri.read()
        }

        fn slot_uri(self: @ComponentState<TContractState>, slot: u256) -> felt252 {
            self._erc3525_slot_uri.read(slot)
        }
    }

    #[embeddable_as(ERC3525MetadataCamelOnlyImpl)]
    impl ERC3525MetadataCamelOnly<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>
    > of IERC3525MetadataCamelOnly<ComponentState<TContractState>> {
        fn contractURI(self: @ComponentState<TContractState>) -> felt252 {
            self.contract_uri()
        }

        fn slotURI(self: @ComponentState<TContractState>, slot: u256) -> felt252 {
            self.slot_uri(slot)
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            // [Effect] Register interfaces
            let mut src5_comp = get_dep_component_mut!(ref self, SRC5);
            src5_comp.register_interface(IERC3525_METADATA_ID);
        }

        fn _set_contract_uri(ref self: ComponentState<TContractState>, uri: felt252) {
            // [Effect] Store uri
            self._erc3525_contract_uri.write(uri);
        }

        fn _set_slot_uri(ref self: ComponentState<TContractState>, slot: u256, uri: felt252) {
            // [Effect] Store uri
            self._erc3525_slot_uri.write(slot, uri);
        }
    }
}
