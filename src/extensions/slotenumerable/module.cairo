#[starknet::component]
mod ERC3525SlotEnumerableComponent {
    // Core deps
    use traits::Into;
    use zeroable::Zeroable;
    use integer::BoundedInt;

    // Starknet deps
    use starknet::{get_caller_address, ContractAddress};

    // External deps
    use openzeppelin::introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin::introspection::src5::SRC5Component;

    use openzeppelin::token::erc721::erc721::ERC721Component;

    // Local deps
    use cairo_erc_3525::module::ERC3525Component::AssertTrait as ERC3525AssertTrait;
    use cairo_erc_3525::module::ERC3525Component::InternalTrait as ERC3525InternalTrait;
    use cairo_erc_3525::module::ERC3525Component::ERC3525;
    use cairo_erc_3525::module::ERC3525Component;
    use cairo_erc_3525::extensions::slotenumerable::interface::{
        IERC3525SlotEnumerable, IERC3525SlotEnumerableCamelOnly, IERC3525_SLOT_ENUMERABLE_ID
    };

    #[storage]
    struct Storage {
        _erc3525_slot_enumerables_len: u256,
        _erc3525_slot_enumerables: LegacyMap<u256, u256>,
        _erc3525_slot_enumerables_index: LegacyMap<u256, u256>,
        _erc3525_slot_tokens_len: LegacyMap<u256, u256>,
        _erc3525_slot_tokens: LegacyMap<(u256, u256), u256>,
        _erc3525_slot_tokens_index: LegacyMap<(u256, u256), u256>,
    }

    mod Errors {
        const INDEX_OUT_OF_BOUNDS: felt252 = 'ERC3525: index out of bounds';
        const SLOT_ALREADY_EXISTS: felt252 = 'ERC3525: slot already exists';
        const SLOT_DOES_NOT_EXIST: felt252 = 'ERC3525: slot does not exist';
    }

    #[embeddable_as(ERC3525SlotEnumerableImpl)]
    impl ERC3525SlotEnumerable<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ERC3525Comp: ERC3525Component::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721Comp: ERC721Component::HasComponent<TContractState>
    > of IERC3525SlotEnumerable<ComponentState<TContractState>> {
        fn slot_count(self: @ComponentState<TContractState>) -> u256 {
            self._erc3525_slot_enumerables_len.read()
        }

        fn slot_by_index(self: @ComponentState<TContractState>, index: u256) -> u256 {
            // [Check] Index is in range
            let count = self._erc3525_slot_enumerables_len.read();
            assert(index < count, Errors::INDEX_OUT_OF_BOUNDS);
            self._erc3525_slot_enumerables.read(index)
        }
        fn token_supply_in_slot(self: @ComponentState<TContractState>, slot: u256) -> u256 {
            self._erc3525_slot_tokens_len.read(slot)
        }
        fn token_in_slot_by_index(
            self: @ComponentState<TContractState>, slot: u256, index: u256
        ) -> u256 {
            // [Check] Index is in range
            let supply = self._erc3525_slot_tokens_len.read(slot);
            assert(index < supply, Errors::INDEX_OUT_OF_BOUNDS);
            self._erc3525_slot_tokens.read((slot, index))
        }
    }

    #[embeddable_as(ERC3525SlotEnumerableCamelOnlyImpl)]
    impl ERC3525SlotEnumerableCamelOnly<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ERC3525Comp: ERC3525Component::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721Comp: ERC721Component::HasComponent<TContractState>
    > of IERC3525SlotEnumerableCamelOnly<ComponentState<TContractState>> {
        fn slotCount(self: @ComponentState<TContractState>) -> u256 {
            self.slot_count()
        }
        fn slotByIndex(self: @ComponentState<TContractState>, index: u256) -> u256 {
            self.slot_by_index(index)
        }
        fn tokenSupplyInSlot(self: @ComponentState<TContractState>, slot: u256) -> u256 {
            self.token_supply_in_slot(slot)
        }
        fn tokenInSlotByIndex(
            self: @ComponentState<TContractState>, slot: u256, index: u256
        ) -> u256 {
            self.token_in_slot_by_index(slot, index)
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ERC3525Comp: ERC3525Component::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721Comp: ERC721Component::HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            // [Effect] Register interfaces
            let mut src5_comp = get_dep_component_mut!(ref self, SRC5);
            src5_comp.register_interface(IERC3525_SLOT_ENUMERABLE_ID);
        }

        fn _slot_exists(self: @ComponentState<TContractState>, slot: u256) -> bool {
            let index = self._erc3525_slot_enumerables_index.read(slot);
            self._erc3525_slot_enumerables.read(index) == slot && slot != 0
        }

        fn _token_exists(
            self: @ComponentState<TContractState>, slot: u256, token_id: u256
        ) -> bool {
            let index = self._erc3525_slot_tokens_index.read((slot, token_id));
            self._erc3525_slot_tokens.read((slot, index)) == token_id && token_id != 0
        }

        fn _after_transfer_value_from(ref self: ComponentState<TContractState>, token_id: u256) {
            // [Check] Token exists
            let erc3525_comp = get_dep_component!(@self, ERC3525Comp);
            erc3525_comp._assert_minted(token_id);

            // [Effect] Add token to enumeration if new
            let slot = erc3525_comp.slot_of(token_id);
            if self._token_exists(slot, token_id) {
                return ();
            }
            self._add_token_to_slot_enumeration(slot, token_id);
        }

        fn _mint_new(
            ref self: ComponentState<TContractState>, to: ContractAddress, slot: u256, value: u256
        ) -> u256 {
            // [Effect] Mint new
            let mut erc3525_comp = get_dep_component_mut!(ref self, ERC3525Comp);
            let token_id = erc3525_comp._mint_new(to, slot, value);

            // [Effect] Add slot to enumeration if new
            if !self._slot_exists(slot) {
                self._add_slot_to_slots_enumeration(slot);
            }

            // [Effect] Add token to enumeration
            self._add_token_to_slot_enumeration(slot, token_id);
            token_id
        }

        fn _mint(
            ref self: ComponentState<TContractState>,
            to: ContractAddress,
            token_id: u256,
            slot: u256,
            value: u256
        ) {
            // [Effect] Mint
            let mut erc3525_comp = get_dep_component_mut!(ref self, ERC3525Comp);
            erc3525_comp._mint(to, token_id, slot, value);

            // [Effect] Add slot to enumeration if new
            if !self._slot_exists(slot) {
                self._add_slot_to_slots_enumeration(slot);
            }

            // [Effect] Add token to enumeration
            self._add_token_to_slot_enumeration(slot, token_id);
        }

        fn _burn(ref self: ComponentState<TContractState>, token_id: u256) {
            // [Effect] Remove token from enumeration
            let erc3525_comp = get_dep_component!(@self, ERC3525Comp);
            let slot = erc3525_comp.slot_of(token_id);
            self._remove_token_from_slot_enumeration(slot, token_id);

            // [Effect] Burn
            let mut erc3525_comp = get_dep_component_mut!(ref self, ERC3525Comp);
            erc3525_comp._burn(token_id)
        }

        fn _add_slot_to_slots_enumeration(ref self: ComponentState<TContractState>, slot: u256) {
            // [Effect] Store new slot
            let index = self._erc3525_slot_enumerables_len.read();
            self._erc3525_slot_enumerables_len.write(index + 1);
            self._erc3525_slot_enumerables.write(index, slot);
            self._erc3525_slot_enumerables_index.write(slot, index);
        }

        fn _add_token_to_slot_enumeration(
            ref self: ComponentState<TContractState>, slot: u256, token_id: u256
        ) {
            // [Effect] Store new token
            let index = self._erc3525_slot_tokens_len.read(slot);
            self._erc3525_slot_tokens_len.write(slot, index + 1);
            self._erc3525_slot_tokens.write((slot, index), token_id);
            self._erc3525_slot_tokens_index.write((slot, token_id), index);
        }

        fn _remove_token_from_slot_enumeration(
            ref self: ComponentState<TContractState>, slot: u256, token_id: u256
        ) {
            // [Compute] Read last token
            let supply = self._erc3525_slot_tokens_len.read(slot);
            let last_token = self._erc3525_slot_tokens.read((slot, supply - 1));
            let last_index = self._erc3525_slot_tokens_index.read((slot, last_token));

            // [Compute] Token index to remove
            let token_index = self._erc3525_slot_tokens_index.read((slot, token_id));

            // [Effect] Replace token_id byt last token
            self._erc3525_slot_tokens.write((slot, token_index), last_token);
            self._erc3525_slot_tokens_index.write((slot, last_token), token_index);

            // [Effect] Remove last token and its index
            self._erc3525_slot_tokens_len.write(slot, supply - 1);
            self._erc3525_slot_tokens.write((slot, last_index), 0);
            self._erc3525_slot_tokens_index.write((slot, token_id), 0);
        }
    }

    #[generate_trait]
    impl AssertImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ERC3525Comp: ERC3525Component::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721Comp: ERC721Component::HasComponent<TContractState>
    > of AssertTrait<TContractState> {
        fn _assert_slot_exists(self: @ComponentState<TContractState>, slot: u256) {
            // [Check] Slot exists
            assert(self._slot_exists(slot), Errors::SLOT_DOES_NOT_EXIST);
        }
        fn _assert_slot_not_exists(self: @ComponentState<TContractState>, slot: u256) {
            // [Check] Slot not exists
            assert(!self._slot_exists(slot), Errors::SLOT_ALREADY_EXISTS);
        }
    }
}
