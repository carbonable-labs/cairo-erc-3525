#[starknet::contract]
mod DualCaseERC3525Mock {
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use cairo_erc_3525::module::ERC3525Component;
    use starknet::ContractAddress;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC3525Component, storage: erc3525, event: ERC3525Event);

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // ERC3525
    #[abi(embed_v0)]
    impl ERC3525Impl = ERC3525Component::ERC3525Impl<ContractState>;
    impl ERC3525InternalImpl = ERC3525Component::InternalImpl<ContractState>;
    impl ERC3525AssertImpl = ERC3525Component::AssertImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc3525: ERC3525Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC3525Event: ERC3525Component::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        value_decimals: u8,
        base_uri: ByteArray,
        recipient: ContractAddress,
    ) {
        self.erc3525.initializer(value_decimals);
        self.erc721.initializer(name, symbol, base_uri);
    }
}

#[starknet::contract]
mod DualCaseERC3525MetadataMock {
    use cairo_erc_3525::extensions::metadata::module::ERC3525MetadataComponent;
    use cairo_erc_3525::module::ERC3525Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use starknet::ContractAddress;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC3525Component, storage: erc3525, event: ERC3525Event);
    component!(
        path: ERC3525MetadataComponent, storage: erc3525_metadata, event: ERC3525MetadataEvent
    );

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // ERC3525
    #[abi(embed_v0)]
    impl ERC3525Impl = ERC3525Component::ERC3525Impl<ContractState>;
    impl ERC3525InternalImpl = ERC3525Component::InternalImpl<ContractState>;
    impl ERC3525AssertImpl = ERC3525Component::AssertImpl<ContractState>;

    // ERC3525Metadata
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
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc3525: ERC3525Component::Storage,
        #[substorage(v0)]
        erc3525_metadata: ERC3525MetadataComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC3525Event: ERC3525Component::Event,
        #[flat]
        ERC3525MetadataEvent: ERC3525MetadataComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        value_decimals: u8,
        base_uri: ByteArray,
        recipient: ContractAddress,
    ) {
        self.erc3525_metadata.initializer();
        self.erc3525.initializer(value_decimals);
        self.erc721.initializer(name, symbol, base_uri);
    }
}

#[starknet::contract]
mod DualCaseERC3525SlotApprovableMock {
    use cairo_erc_3525::extensions::slotapprovable::module::ERC3525SlotApprovableComponent;
    use cairo_erc_3525::module::ERC3525Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use starknet::ContractAddress;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC3525Component, storage: erc3525, event: ERC3525Event);
    component!(
        path: ERC3525SlotApprovableComponent,
        storage: erc3525_slot_approvable,
        event: ERC3525SlotApprovableEvent
    );

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // ERC3525
    #[abi(embed_v0)]
    impl ERC3525Impl = ERC3525Component::ERC3525Impl<ContractState>;
    impl ERC3525InternalImpl = ERC3525Component::InternalImpl<ContractState>;
    impl ERC3525AssertImpl = ERC3525Component::AssertImpl<ContractState>;

    // ERC3525SlotApprovable
    #[abi(embed_v0)]
    impl ERC3525SlotApprovableImpl =
        ERC3525SlotApprovableComponent::ERC3525SlotApprovableImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525SlotApprovableCamelOnlyImpl =
        ERC3525SlotApprovableComponent::ERC3525SlotApprovableCamelOnlyImpl<ContractState>;
    impl ERC3525SlotApprovableInternalImpl =
        ERC3525SlotApprovableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc3525: ERC3525Component::Storage,
        #[substorage(v0)]
        erc3525_slot_approvable: ERC3525SlotApprovableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC3525Event: ERC3525Component::Event,
        #[flat]
        ERC3525SlotApprovableEvent: ERC3525SlotApprovableComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        value_decimals: u8,
        base_uri: ByteArray,
        recipient: ContractAddress,
    ) {
        self.erc3525_slot_approvable.initializer();
        self.erc3525.initializer(value_decimals);
        self.erc721.initializer(name, symbol, base_uri);
    }
}

#[starknet::contract]
mod DualCaseERC3525SlotEnumerableMock {
    use cairo_erc_3525::extensions::slotenumerable::module::ERC3525SlotEnumerableComponent;
    use cairo_erc_3525::module::ERC3525Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use starknet::ContractAddress;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC3525Component, storage: erc3525, event: ERC3525Event);
    component!(
        path: ERC3525SlotEnumerableComponent,
        storage: erc3525_slot_enumerable,
        event: ERC3525SlotEnumerableEvent
    );

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // ERC3525
    #[abi(embed_v0)]
    impl ERC3525Impl = ERC3525Component::ERC3525Impl<ContractState>;
    impl ERC3525InternalImpl = ERC3525Component::InternalImpl<ContractState>;
    impl ERC3525AssertImpl = ERC3525Component::AssertImpl<ContractState>;

    // ERC3525SlotEnumerable
    #[abi(embed_v0)]
    impl ERC3525SlotEnumerableImpl =
        ERC3525SlotEnumerableComponent::ERC3525SlotEnumerableImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC3525SlotEnumerableCamelOnlyImpl =
        ERC3525SlotEnumerableComponent::ERC3525SlotEnumerableCamelOnlyImpl<ContractState>;
    impl ERC3525SlotEnumerableInternalImpl =
        ERC3525SlotEnumerableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        erc3525: ERC3525Component::Storage,
        #[substorage(v0)]
        erc3525_slot_enumerable: ERC3525SlotEnumerableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        ERC3525Event: ERC3525Component::Event,
        #[flat]
        ERC3525SlotEnumerableEvent: ERC3525SlotEnumerableComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        value_decimals: u8,
        base_uri: ByteArray,
        recipient: ContractAddress,
    ) {
        self.erc3525_slot_enumerable.initializer();
        self.erc3525.initializer(value_decimals);
        self.erc721.initializer(name, symbol, base_uri);
    }
}
