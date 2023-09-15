#[starknet::contract]
mod ERC3525SlotEnumerable {
    // Core deps
    use traits::Into;
    use zeroable::Zeroable;
    use integer::BoundedInt;

    // Starknet deps
    use starknet::{get_caller_address, ContractAddress};

    // External deps
    use openzeppelin::introspection::src5::SRC5;
    use openzeppelin::token::erc721::erc721::ERC721;

    // Local deps
    use cairo_erc_3525::module::ERC3525;
    use cairo_erc_3525::extensions::slotenumerable::interface::{
        IERC3525SlotEnumerable, IERC3525_SLOT_ENUMERABLE_ID
    };

    #[storage]
    struct Storage {
        _slot_enumerables_len: u256,
        _slot_enumerables: LegacyMap<u256, u256>,
        _slot_enumerables_index: LegacyMap<u256, u256>,
        _slot_tokens_len: LegacyMap<u256, u256>,
        _slot_tokens: LegacyMap<(u256, u256), u256>,
        _slot_tokens_index: LegacyMap<(u256, u256), u256>,
    }

    #[external(v0)]
    impl ERC3525SlotEnumerableImpl of IERC3525SlotEnumerable<ContractState> {
        fn slot_count(self: @ContractState) -> u256 {
            self._slot_enumerables_len.read()
        }

        fn slot_by_index(self: @ContractState, index: u256) -> u256 {
            // [Check] Index is in range
            let count = self._slot_enumerables_len.read();
            assert(index < count, 'ERC3525: index out of bounds');
            self._slot_enumerables.read(index)
        }
        fn token_supply_in_slot(self: @ContractState, slot: u256) -> u256 {
            self._slot_tokens_len.read(slot)
        }
        fn token_in_slot_by_index(self: @ContractState, slot: u256, index: u256) -> u256 {
            // [Check] Index is in range
            let supply = self._slot_tokens_len.read(slot);
            assert(index < supply, 'ERC3525: index out of bounds');
            self._slot_tokens.read((slot, index))
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState) {
            // [Effect] Register interfaces
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, IERC3525_SLOT_ENUMERABLE_ID);
        }

        fn _slot_exists(self: @ContractState, slot: u256) -> bool {
            let index = self._slot_enumerables_index.read(slot);
            self._slot_enumerables.read(index) == slot && slot != 0
        }

        fn _token_exists(self: @ContractState, slot: u256, token_id: u256) -> bool {
            let index = self._slot_tokens_index.read((slot, token_id));
            self._slot_tokens.read((slot, index)) == token_id && token_id != 0
        }

        fn _after_transfer_value_from(ref self: ContractState, token_id: u256) {
            // [Check] Token exists
            let unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::AssertImpl::_assert_minted(@unsafe_state, token_id);

            // [Effect] Add token to enumeration if new
            let slot = ERC3525::ERC3525Impl::slot_of(@unsafe_state, token_id);
            if self._token_exists(slot, token_id) {
                return ();
            }
            self._add_token_to_slot_enumeration(slot, token_id);
        }

        fn _mint_new(
            ref self: ContractState, to: ContractAddress, slot: u256, value: u256
        ) -> u256 {
            // [Effect] Mint new
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            let token_id = ERC3525::InternalImpl::_mint_new(ref unsafe_state, to, slot, value);

            // [Effect] Add slot to enumeration if new
            if !self._slot_exists(slot) {
                self._add_slot_to_slots_enumeration(slot);
            }

            // [Effect] Add token to enumeration
            self._add_token_to_slot_enumeration(slot, token_id);
            token_id
        }

        fn _mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, slot: u256, value: u256
        ) {
            // [Effect] Mint
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_mint(ref unsafe_state, to, token_id, slot, value);

            // [Effect] Add slot to enumeration if new
            if !self._slot_exists(slot) {
                self._add_slot_to_slots_enumeration(slot);
            }

            // [Effect] Add token to enumeration
            self._add_token_to_slot_enumeration(slot, token_id);
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            // [Effect] Remove token from enumeration
            let unsafe_state = ERC3525::unsafe_new_contract_state();
            let slot = ERC3525::ERC3525Impl::slot_of(@unsafe_state, token_id);
            self._remove_token_from_slot_enumeration(slot, token_id);

            // [Effect] Burn
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_burn(ref unsafe_state, token_id)
        }

        fn _add_slot_to_slots_enumeration(ref self: ContractState, slot: u256) {
            // [Effect] Store new slot
            let index = self._slot_enumerables_len.read();
            self._slot_enumerables_len.write(index + 1);
            self._slot_enumerables.write(index, slot);
            self._slot_enumerables_index.write(slot, index);
        }

        fn _add_token_to_slot_enumeration(ref self: ContractState, slot: u256, token_id: u256) {
            // [Effect] Store new token
            let index = self._slot_tokens_len.read(slot);
            self._slot_tokens_len.write(slot, index + 1);
            self._slot_tokens.write((slot, index), token_id);
            self._slot_tokens_index.write((slot, token_id), index);
        }

        fn _remove_token_from_slot_enumeration(
            ref self: ContractState, slot: u256, token_id: u256
        ) {
            // [Compute] Read last token
            let supply = self._slot_tokens_len.read(slot);
            let last_token = self._slot_tokens.read((slot, supply - 1));
            let last_index = self._slot_tokens_index.read((slot, last_token));

            // [Compute] Token index to remove
            let token_index = self._slot_tokens_index.read((slot, token_id));

            // [Effect] Replace token_id byt last token
            self._slot_tokens.write((slot, token_index), last_token);
            self._slot_tokens_index.write((slot, last_token), token_index);

            // [Effect] Remove last token and its index
            self._slot_tokens_len.write(slot, supply - 1);
            self._slot_tokens.write((slot, last_index), 0);
            self._slot_tokens_index.write((slot, token_id), 0);
        }
    }

    #[generate_trait]
    impl AssertImpl of AssertTrait {
        fn _assert_slot_exists(self: @ContractState, slot: u256) {
            // [Check] Slot exists
            assert(self._slot_exists(slot), 'ERC3525: slot does not exist');
        }
        fn _assert_slot_not_exists(self: @ContractState, slot: u256) {
            // [Check] Slot not exists
            assert(!self._slot_exists(slot), 'ERC3525: slot already exists');
        }
    }
}
