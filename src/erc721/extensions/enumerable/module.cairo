// Source: https://github.com/Seraph-Labs/Cairo-Contracts/blob/cairo-2/src/tokens/erc721/extensions/enumerable.cairo

#[starknet::contract]
mod ERC721Enumerable {
    use option::OptionTrait;
    use integer::BoundedInt;
    use traits::{TryInto, Into};
    use starknet::ContractAddress;
    use cairo_erc_3525::src5::module::SRC5;
    use cairo_erc_3525::erc721::module::ERC721;
    use cairo_erc_3525::erc721::extensions::enumerable::interface::{IERC721_ENUMERABLE_ID, IERC721Enumerable};

    #[storage]
    struct Storage {
        _supply: u256,
        _index_to_tokens: LegacyMap::<u256, u256>,
        _tokens_to_index: LegacyMap::<u256, u256>,
        _owner_index_to_token: LegacyMap::<(ContractAddress, u256), u256>,
        _owner_token_to_index: LegacyMap::<u256, u256>,
    }

    #[external(v0)]
    impl ERC721EnumerableImpl of IERC721Enumerable<ContractState> {
        fn total_supply(self: @ContractState) -> u256 {
            self._supply.read()
        }

        fn token_by_index(self: @ContractState, index: u256) -> u256 {
            // assert index is not out of bounds
            let supply = self._supply.read();
            assert(index < supply, 'ERC721Enum: index out of bounds');
            self._index_to_tokens.read(index)
        }

        fn token_of_owner_by_index(
            self: @ContractState, owner: ContractAddress, index: u256
        ) -> u256 {
            self._token_of_owner_by_index(owner, index).expect('ERC721Enum: index out of bounds')
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState) {
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(
                ref unsafe_state, IERC721_ENUMERABLE_ID
            );
        }

        fn transfer_from(
            ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256
        ) {
            self._remove_token_from_owner_enum(from, token_id);
            self._add_token_to_owner_enum(to, token_id);

            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::transfer_from(ref unsafe_state, from, to, token_id);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self._remove_token_from_owner_enum(from, token_id);
            self._add_token_to_owner_enum(to, token_id);

            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::ERC721Impl::safe_transfer_from(ref unsafe_state, from, to, token_id, data)
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self._add_token_to_owner_enum(to, token_id);
            self._add_token_to_total_enum(token_id);
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_mint(ref unsafe_state, to, token_id);
        }

        fn _safe_mint(
            ref self: ContractState, to: ContractAddress, token_id: u256, data: Span<felt252>
        ) {
            self._add_token_to_owner_enum(to, token_id);
            self._add_token_to_total_enum(token_id);
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_safe_mint(ref unsafe_state, to, token_id, data);
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::ERC721Impl::owner_of(@unsafe_state, token_id);

            self._remove_token_from_owner_enum(owner, token_id);
            self._remove_token_from_total_enum(token_id);
            // set owners token_id index to zero
            self._owner_token_to_index.write(token_id, BoundedInt::min());
            ERC721::InternalImpl::_burn(ref unsafe_state, token_id);
        }

        fn _token_of_owner_by_index(
            self: @ContractState, owner: ContractAddress, index: u256
        ) -> Option<u256> {
            let token_id = self._owner_index_to_token.read((owner, index));
            match token_id == BoundedInt::<u256>::min() {
                bool::False(()) => Option::Some(token_id),
                bool::True(()) => Option::None(()),
            }
        }
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn _add_token_to_total_enum(ref self: ContractState, token_id: u256) {
            let supply = self._supply.read();
            // add token_id to totals last index
            self._index_to_tokens.write(supply, token_id);
            // add last index to token_id
            self._tokens_to_index.write(token_id, supply);
            // add to new_supply
            self._supply.write(supply + 1_u256);
        }

        fn _remove_token_from_total_enum(ref self: ContractState, token_id: u256) {
            // index starts from zero therefore minus 1
            let last_token_index = self._supply.read() - 1_u256;
            let cur_token_index = self._tokens_to_index.read(token_id);

            if last_token_index != cur_token_index {
                // set last token Id to cur token index
                let last_tokenId = self._index_to_tokens.read(last_token_index);
                self._index_to_tokens.write(cur_token_index, last_tokenId);
                // set cur token index to last token_id
                self._tokens_to_index.write(last_tokenId, cur_token_index);
            }

            // set token at last index to zero
            self._index_to_tokens.write(last_token_index, BoundedInt::min());
            // set token_id index to zero
            self._tokens_to_index.write(token_id, BoundedInt::min());
            // remove 1 from supply
            self._supply.write(last_token_index);
        }

        fn _add_token_to_owner_enum(
            ref self: ContractState, owner: ContractAddress, token_id: u256
        ) {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let len = ERC721::ERC721Impl::balance_of(@unsafe_state, owner);
            // set token_id to owners last index
            self._owner_index_to_token.write((owner, len), token_id);
            // set index to owners token_id
            self._owner_token_to_index.write(token_id, len);
        }

        fn _remove_token_from_owner_enum(
            ref self: ContractState, owner: ContractAddress, token_id: u256
        ) {
            // index starts from zero therefore minus 1
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let last_token_index = ERC721::ERC721Impl::balance_of(@unsafe_state, owner) - 1.into();
            let cur_token_index = self._owner_token_to_index.read(token_id);

            if last_token_index != cur_token_index {
                // set last token Id to cur token index
                let last_tokenId = self._owner_index_to_token.read((owner, last_token_index));
                self._owner_index_to_token.write((owner, cur_token_index), last_tokenId);
                // set cur token index to last token_id
                self._owner_token_to_index.write(last_tokenId, cur_token_index);
            }
            // set token at owners last index to zero
            self._owner_index_to_token.write((owner, last_token_index), BoundedInt::min());
        }
    }
}