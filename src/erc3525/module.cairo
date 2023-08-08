#[starknet::contract]
mod ERC3525 {
    use starknet::{get_caller_address, ContractAddress};
    use array::{ArrayTrait, SpanTrait};
    use traits::Into;
    use zeroable::Zeroable;
    use integer::BoundedInt;

    use cairo_erc_3525::constants;
    use cairo_erc_3525::src5::module::SRC5;
    use cairo_erc_3525::src5::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
    use cairo_erc_3525::erc721::module::ERC721;
    use cairo_erc_3525::erc721::extensions::enumerable::module::ERC721Enumerable;
    use cairo_erc_3525::erc721::extensions::enumerable::interface::IERC721_ENUMERABLE_ID;
    use cairo_erc_3525::erc3525::interface::{IERC3525_ID, IERC3525_RECEIVER_ID, IERC3525, IERC3525ReceiverDispatcher, IERC3525ReceiverDispatcherTrait};

    #[storage]
    struct Storage {
        _value_decimals: u8,
        _values: LegacyMap::<u256, u256>,
        _approved_values: LegacyMap::<(ContractAddress, u256, ContractAddress), u256>,
        _slots: LegacyMap::<u256, u256>,
        _slot_uri: LegacyMap::<u256, felt252>,
        _contract_uri: felt252,
        _total_minted: u256,
        _total_value: LegacyMap::<u256, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TransferValue: TransferValue,
        ApprovalValue: ApprovalValue,
        SlotChanged: SlotChanged,
    }

    #[derive(Drop, starknet::Event)]
    struct TransferValue {
        from_token_id: u256,
        to_token_id: u256,
        value: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalValue {
        token_id: u256,
        operator: ContractAddress,
        value: u256
    }

    #[derive(Drop, starknet::Event)]
    struct SlotChanged {
        token_id: u256,
        old_slot: u256,
        new_slot: u256,
    }

    #[external(v0)]
    impl ERC3525Impl of IERC3525<ContractState>{

        fn value_decimals(self: @ContractState) -> u8 {
            // [Compute] Value decimals
            self._value_decimals.read()
        }

        fn value_of(self: @ContractState, token_id: u256) -> u256 {
            // [Check] Token exists
            self._assert_minted(token_id);

            // [Compute] Token value
            self._values.read(token_id)
        }

        fn slot_of(self: @ContractState, token_id: u256) -> u256 {
            // [Check] Token exists
            self._assert_minted(token_id);
            self._slots.read(token_id)
        }

        fn approve_value(ref self: ContractState, token_id: u256, operator: ContractAddress, value: u256) {
            // [Check] Caller and operator are not null addresses
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'ERC3525: invalid caller');
            assert(!operator.is_zero(), 'ERC3525: invalid operator');

            // [Check] Operator is not owner and caller is approved or owner
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::ERC721Impl::owner_of(@unsafe_state, token_id);
            assert(owner != operator, 'ERC3525: approval to owner');
            assert(ERC721::InternalImpl::_is_approved_or_owner(@unsafe_state, caller, token_id), 'ERC3525: caller not allowed');
            
            // [Effect] Store approved value
            self._approve_value(token_id, operator, value);
        }

        fn allowance(self: @ContractState, token_id: u256, operator: ContractAddress) -> u256 {
            // [Check] 
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::ERC721Impl::owner_of(@unsafe_state, token_id);
            self._approved_values.read((owner, token_id, operator))
        }

        fn transfer_value_from(ref self: ContractState, from_token_id: u256, to_token_id: u256, to: ContractAddress, value: u256) -> u256 {
            // [Check] caller, from token_id and transfered value are not null
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'ERC3525: invalid caller');
            assert(from_token_id != 0.into(), 'ERC3525: invalid from token id');
            assert(value != 0.into(), 'ERC3525: invalid value');

            // [Check] Disambiguate function call: only one of `to_token_id` and `to` must be set
            assert(to_token_id == 0.into() || to.is_zero(), 'ERC3525: mutually excl args set');

            // [Effect] Spend allowance if possible
            self._spend_allowance(caller, from_token_id, value);

            // [Effect] Transfer value to address
            if to_token_id == 0.into() {
                return self._transfer_value_to(from_token_id, to, value);
            }
            self._transfer_value_to_token(from_token_id, to_token_id, value)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, value_decimals: u8) {
            // [Effect] Store value decimals
            self._value_decimals.write(value_decimals);

            // [Effect] Register interfaces
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, IERC3525_ID);
        }

        fn _get_new_token_id(self: @ContractState) -> u256 {
            self._total_minted.read() + 1
        }

        fn _approve_value(ref self: ContractState, token_id: u256, operator: ContractAddress, value: u256) {
            // [Effect] Store approved value
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::ERC721Impl::owner_of(@unsafe_state, token_id);
            self._approved_values.write((owner, token_id, operator), value);

            // [Event] Emit ApprovalValue
            self.emit(ApprovalValue { token_id, operator, value });
        }

        fn _transfer_value_to(ref self: ContractState, from_token_id: u256, to: ContractAddress, value: u256) -> u256 {
            // [Effect] Mint new token and transfer value
            let token_id = self._get_new_token_id();
            let slot = self.slot_of(from_token_id);
            self._mint(to, token_id, slot, 0.into());
            self._transfer_value(from_token_id, token_id, value);
            token_id
        }

        fn _transfer_value_to_token(ref self: ContractState, from_token_id: u256, to_token_id: u256, value: u256) -> u256 {
            // [Effect] Transfer value
            self._transfer_value(from_token_id, to_token_id, value);
            to_token_id
        }

        fn _spend_allowance(ref self: ContractState, spender: ContractAddress, token_id: u256, value: u256) {
            // [Compute] Spender allowance
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::ERC721Impl::owner_of(@unsafe_state, token_id);
            let current_allowance = self._approved_values.read((owner, token_id, spender));
            let infinity : u256 = BoundedInt::max();
            let is_approved = ERC721::InternalImpl::_is_approved_or_owner(@unsafe_state, spender, token_id);

            // [Effect] Update allowance if the rights are limited
            if current_allowance == infinity || is_approved {
                return ();
            }
            assert(current_allowance >= value, 'ERC3525: insufficient allowance');
            let new_allowance = current_allowance - value;
            self._approve_value(token_id, spender, new_allowance);
        }

        fn _mint_new(ref self: ContractState, to: ContractAddress, slot: u256, value: u256) -> u256 {
            // [Effect] Generate a new token_id and mint it
            let token_id = self._get_new_token_id();
            self._mint(to, token_id, slot, value);
            token_id
        }

        fn _mint(ref self: ContractState, to: ContractAddress, token_id: u256, slot: u256, value: u256) {
            // [Check] Token id not already exists
            self._assert_not_minted(token_id);

            // [Check] Receiver address, slot and antoken_id are not null
            assert(!to.is_zero(), 'ERC3525: invalid to address');
            assert(slot != 0, 'ERC3525: invalid slot');
            assert(token_id != 0, 'ERC3525: invalid token_id');
            
            // [Effect] Mint token and value
            self._mint_token(to, token_id, slot);
            self._mint_value(token_id, value);
        }

        fn _mint_token(ref self: ContractState, to: ContractAddress, token_id: u256, slot: u256) {
            // [Compute] Enumerable supported
            let unsafe_state = SRC5::unsafe_new_contract_state();
            let enumerable = SRC5::SRC5Impl::supports_interface(@unsafe_state, IERC721_ENUMERABLE_ID);
            
            // [Effect] Mint a new enumerable token if supported, standard token otherwise
            if enumerable {
                let mut unsafe_state = ERC721Enumerable::unsafe_new_contract_state();
                ERC721Enumerable::InternalImpl::_mint(ref unsafe_state, to, token_id);
            } else {
                let mut unsafe_state = ERC721::unsafe_new_contract_state();
                ERC721::InternalImpl::_mint(ref unsafe_state, to, token_id);
            }

            // [Effect] Store slot
            self._slots.write(token_id, slot);

            // [Effect] Update new total minted
            self._total_minted.write(self._total_minted.read() + 1);

            // [Event] Emit SlotChanged
            self.emit(SlotChanged { token_id, old_slot: 0.into(), new_slot: slot });
        }

        fn _mint_value(ref self: ContractState, token_id: u256, value: u256) {
            // [Check] Token exists
            self._assert_minted(token_id);
            
            // [Effect] Update token value
            self._values.write(token_id, self._values.read(token_id) + value);

            // [Effect] Update total value
            let slot = self.slot_of(token_id);
            let total = self._total_value.read(slot);
            self._total_value.write(slot, self._total_value.read(slot) + value);

            // [Event] Emit TransferValue
            self.emit(TransferValue { from_token_id: 0.into(), to_token_id: token_id, value });
        }

        fn _transfer_value(ref self: ContractState, from_token_id: u256, to_token_id: u256, value: u256) {
            // [Check] Tokens exist and not null
            self._assert_minted(from_token_id);
            self._assert_minted(to_token_id);
            assert(from_token_id != 0, 'ERC3525: invalid from_token_id');
            assert(to_token_id != 0, 'ERC3525: invalid to_token_id');

            // [Check] Tokens slot match
            assert(self.slot_of(from_token_id) == self.slot_of(to_token_id), 'ERC3525: transfer slot mismatch');

            // [Check] Transfer amount does not exceed balance
            let from_balance = self._values.read(from_token_id);
            assert(from_balance >= value, 'ERC3525: value exceeds balance');

            // [Effect] Update tokens balance
            self._values.write(from_token_id, from_balance - value);
            let to_balance = self._values.read(to_token_id);
            self._values.write(to_token_id, to_balance + value);

            // [Interaction] Receiver
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::ERC721Impl::owner_of(@unsafe_state, to_token_id);
            let data = ArrayTrait::new();
            let success = self._check_on_erc3525_received(
                from_token_id, to_token_id, owner, value, data.span()
            );
            
            // TODO: Enable when the main accounts accept SRC6
            // assert(success, 'ERC3525: invalid receiver');
            
            // [Event] Emit TransferValue
            self.emit(TransferValue { from_token_id, to_token_id, value });
        }

        fn _burn(ref self: ContractState, token_id: u256) {
            // [Check] Token exists
            self._assert_minted(token_id);

            // [Compute] Enumerable supported
            let unsafe_state = SRC5::unsafe_new_contract_state();
            let enumerable = SRC5::SRC5Impl::supports_interface(@unsafe_state, IERC721_ENUMERABLE_ID);

            // [Effect] Burn token
            if enumerable {
                let mut unsafe_state = ERC721Enumerable::unsafe_new_contract_state();
                ERC721Enumerable::InternalImpl::_burn(ref unsafe_state, token_id);
            } else {
                let mut unsafe_state = ERC721::unsafe_new_contract_state();
                ERC721::InternalImpl::_burn(ref unsafe_state, token_id);
            }

            // [Effect] Update token and total value
            let value = self._values.read(token_id);
            let slot = self._slots.read(token_id);
            self._values.write(token_id, 0.into());
            self._total_value.write(slot, self._total_value.read(slot) - value);

            // [Effect] Update slot
            self._slots.write(token_id, 0.into());

            // [Event] Emit TransferValue and SlotChanged
            self.emit(TransferValue { from_token_id: token_id, to_token_id: 0.into(), value });
            self.emit(SlotChanged { token_id, old_slot: slot, new_slot: 0.into() });
        }

        fn _burn_value(ref self: ContractState, token_id: u256, value: u256) {
            // [Check] Token exists
            self._assert_minted(token_id);

            // [Check] Burn value does not exceed balance
            let balance = self._values.read(token_id);
            assert(balance >= value, 'ERC3525: value exceeds balance');

            // [Effect] Update token and total value
            let slot = self._slots.read(token_id);
            self._values.write(token_id, balance - value);
            self._total_value.write(slot, self._total_value.read(slot) - value);
            
            // [Event] Emit TransferValue
            self.emit(TransferValue { from_token_id: token_id, to_token_id: 0.into(), value });
            return ();
        }

        fn _check_on_erc3525_received(
            self: @ContractState,
            from_token_id: u256,
            to_token_id: u256,
            to: ContractAddress,
            value: u256,
            data: Span<felt252>
        ) -> bool {

            let contract = ISRC5Dispatcher { contract_address: to };
            let support_interface = contract.supports_interface(IERC3525_RECEIVER_ID);
            if support_interface {
                let operator = get_caller_address();
                let contract = IERC3525ReceiverDispatcher { contract_address: to };
                let selector = contract.on_erc3525_received(
                    operator, from_token_id, to_token_id, value, data
                );
                assert(selector == IERC3525_RECEIVER_ID, 'ERC3525: receiver\'s rejection');
                return true;
            }
            contract.supports_interface(constants::ISRC6_ID)
        }
    }

    #[generate_trait]
    impl AssertImpl of AssertTrait {
        fn _assert_minted(self: @ContractState, token_id: u256) {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let exists = ERC721::InternalImpl::_exists(@unsafe_state, token_id);
            assert(exists, 'ERC3525: token not minted');
        }

        fn _assert_not_minted(self: @ContractState, token_id: u256) {
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let exists = ERC721::InternalImpl::_exists(@unsafe_state, token_id);
            assert(!exists, 'ERC3525: token already minted');
        }
    }
}