#[starknet::component]
mod ERC3525Component {
    // Core deps
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use traits::{Into, TryInto};
    use zeroable::Zeroable;
    use integer::BoundedInt;

    // Starknet deps
    use starknet::{get_caller_address, ContractAddress};

    // External deps
    use openzeppelin::introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin::introspection::src5::SRC5Component::{SRC5, SRC5Camel};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};
    use openzeppelin::token::erc721::erc721::ERC721Component::InternalTrait as ERC721InternalTrait;
    use openzeppelin::token::erc721::erc721::ERC721Component::ERC721;
    use openzeppelin::token::erc721::erc721::ERC721Component;
    use openzeppelin::account::interface::ISRC6_ID;

    // Local deps
    use cairo_erc_3525::interface::{
        IERC3525_ID, IERC3525_RECEIVER_ID, IERC3525, IERC3525CamelOnly, IERC3525ReceiverDispatcher,
        IERC3525ReceiverDispatcherTrait
    };

    #[storage]
    struct Storage {
        _erc3525_value_decimals: u8,
        _erc3525_values: LegacyMap::<u256, u256>,
        _erc3525_approved_values: LegacyMap::<(ContractAddress, u256, ContractAddress), u256>,
        _erc3525_slots: LegacyMap::<u256, u256>,
        _erc3525_total_minted: u256,
        _erc3525_total_value: LegacyMap::<u256, u256>,
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

    mod Errors {
        const INVALID_TOKEN_ID: felt252 = 'ERC3525: invalid token_id';
        const INVALID_ADDRESS: felt252 = 'ERC3525: invalid address';
        const INVALID_CALLER: felt252 = 'ERC3525: invalid caller address';
        const INVALID_OPERATOR: felt252 = 'ERC3525: invalid operator';
        const INVALID_FROM_TOKEN_ID: felt252 = 'ERC3525: invalid from token id';
        const INVALID_TO_TOKEN_ID: felt252 = 'ERC3525: invalid to token id';
        const INVALID_VALUE: felt252 = 'ERC3525: invalid value';
        const INVALID_EXCLUSIVE_ARGS: felt252 = 'ERC3525: mutually excl args set';
        const INVALID_AMOUNTS: felt252 = 'ERC3525: invalid amounts';
        const INVALID_TOKEN_IDS: felt252 = 'ERC3525: invalid token_ids';
        const INVALID_RECEIVER: felt252 = 'ERC3525: invalid receiver';
        const SLOT_MISTMATCH: felt252 = 'ERC3525: slot mismatch';
        const OWNER_MISTMATCH: felt252 = 'ERC3525: owner mismatch';
        const VALUE_EXCEEDS_BALANCE: felt252 = 'ERC3525: value exceeds balance';
        const APPROVAL_TO_OWNER: felt252 = 'ERC3525: approval to owner';
        const CALLER_NOT_ALLOWED: felt252 = 'ERC3525: caller not allowed';
        const INVALID_SLOT: felt252 = 'ERC3525: invalid slot';
        const INSUFFICIENT_ALLOWANCE: felt252 = 'ERC3525: insufficient allowance';
        const RECEIVER_REJECTION: felt252 = 'ERC3525: receiver\'s rejection';
        const TOKEN_NOT_MINTED: felt252 = 'ERC3525: token not minted';
        const TOKEN_ALREADY_MINTED: felt252 = 'ERC3525: token already minted';
    }

    #[embeddable_as(ERC3525Impl)]
    impl ERC3525<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>
    > of IERC3525<ComponentState<TContractState>> {
        fn value_decimals(self: @ComponentState<TContractState>) -> u8 {
            // [Compute] Value decimals
            self._erc3525_value_decimals.read()
        }

        fn value_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            // [Check] Token exists
            self._assert_minted(token_id);

            // [Compute] Token value
            self._erc3525_values.read(token_id)
        }

        fn slot_of(self: @ComponentState<TContractState>, token_id: u256) -> u256 {
            // [Check] Token exists
            self._assert_minted(token_id);
            self._erc3525_slots.read(token_id)
        }

        fn approve_value(
            ref self: ComponentState<TContractState>, token_id: u256, operator: ContractAddress, value: u256
        ) {
            // [Check] Caller and operator are not null addresses
            let caller = get_caller_address();
            assert(!caller.is_zero(), Errors::INVALID_CALLER);
            assert(!operator.is_zero(), Errors::INVALID_OPERATOR);

            // [Check] Operator is not owner and caller is approved or owner
            let erc721_comp = get_dep_component!(@self, ERC721);
            let owner = erc721_comp.owner_of(token_id);
            assert(owner != operator, Errors::APPROVAL_TO_OWNER);
            assert(
                erc721_comp._is_approved_or_owner(caller, token_id),
                Errors::CALLER_NOT_ALLOWED
            );

            // [Effect] Store approved value
            self._approve_value(token_id, operator, value);
        }

        fn allowance(self: @ComponentState<TContractState>, token_id: u256, operator: ContractAddress) -> u256 {
            // [Check] 
            let erc721_comp = get_dep_component!(self, ERC721);
            let owner = erc721_comp.owner_of(token_id);
            self._erc3525_approved_values.read((owner, token_id, operator))
        }

        fn transfer_value_from(
            ref self: ComponentState<TContractState>,
            from_token_id: u256,
            to_token_id: u256,
            to: ContractAddress,
            value: u256
        ) -> u256 {
            // [Check] caller, from token_id and transfered value are not null
            let caller = get_caller_address();
            assert(!caller.is_zero(), Errors::INVALID_CALLER);
            assert(from_token_id != 0.into(), Errors::INVALID_FROM_TOKEN_ID);
            assert(value != 0.into(), Errors::INVALID_VALUE);

            // [Check] Disambiguate function call: only one of `to_token_id` and `to` must be set
            assert(to_token_id == 0.into() || to.is_zero(), Errors::INVALID_EXCLUSIVE_ARGS);
            assert(to_token_id != 0.into() || !to.is_zero(), Errors::INVALID_EXCLUSIVE_ARGS);

            // [Effect] Spend allowance if possible
            self._spend_allowance(caller, from_token_id, value);

            // [Effect] Transfer value to address
            match to_token_id.try_into() {
                // Into felt252 works
                Option::Some(token_id) => {
                    match token_id {
                        // If token_id is zero, transfer value to address
                        0 => self._transfer_value_to(from_token_id, to, value),
                        // Otherwise, transfer value to token
                        _ => self._transfer_value_to_token(from_token_id, to_token_id, value),
                    }
                },
                // Into felt252 fails, so token_id is not zero
                Option::None(()) => self
                    ._transfer_value_to_token(from_token_id, to_token_id, value),
            }
        }
    }

    #[embeddable_as(ERC3525CamelOnlyImpl)]
    impl ERC3525CamelOnly<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>
    > of IERC3525CamelOnly<ComponentState<TContractState>> {
        fn valueDecimals(self: @ComponentState<TContractState>) -> u8 {
            ERC3525::value_decimals(self)
        }
        fn valueOf(self: @ComponentState<TContractState>, tokenId: u256) -> u256 {
            ERC3525::value_of(self, tokenId)
        }
        fn slotOf(self: @ComponentState<TContractState>, tokenId: u256) -> u256 {
            ERC3525::slot_of(self, tokenId)
        }
        fn approveValue(
            ref self: ComponentState<TContractState>, tokenId: u256, operator: ContractAddress, value: u256
        ) {
            ERC3525::approve_value(ref self, tokenId, operator, value)
        }
        fn transferValueFrom(
            ref self: ComponentState<TContractState>,
            fromTokenId: u256,
            toTokenId: u256,
            to: ContractAddress,
            value: u256
        ) -> u256 {
            ERC3525::transfer_value_from(ref self, fromTokenId, toTokenId, to, value)
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, value_decimals: u8) {
            // [Effect] Store value decimals
            self._erc3525_value_decimals.write(value_decimals);

            // [Effect] Register interfaces
            let mut src5_comp = get_dep_component_mut!(ref self, SRC5);
            src5_comp.register_interface(IERC3525_ID);
        }

        fn _get_new_token_id(self: @ComponentState<TContractState>) -> u256 {
            self._erc3525_total_minted.read() + 1
        }

        fn _total_value(self: @ComponentState<TContractState>, slot: u256) -> u256 {
            self._erc3525_total_value.read(slot)
        }

        fn _approve_value(
            ref self: ComponentState<TContractState>, token_id: u256, operator: ContractAddress, value: u256
        ) {
            // [Effect] Store approved value
            let erc721_comp = get_dep_component!(@self, ERC721);
            let owner = erc721_comp.owner_of(token_id);
            self._erc3525_approved_values.write((owner, token_id, operator), value);

            // [Event] Emit ApprovalValue
            self.emit(ApprovalValue { token_id, operator, value });
        }

        fn _transfer_value_to(
            ref self: ComponentState<TContractState>, from_token_id: u256, to: ContractAddress, value: u256
        ) -> u256 {
            // [Effect] Mint new token and transfer value
            let token_id = self._get_new_token_id();
            let slot = self.slot_of(from_token_id);
            self._mint(to, token_id, slot, 0.into());
            self._transfer_value(from_token_id, token_id, value);
            token_id
        }

        fn _transfer_value_to_token(
            ref self: ComponentState<TContractState>, from_token_id: u256, to_token_id: u256, value: u256
        ) -> u256 {
            // [Effect] Transfer value
            self._transfer_value(from_token_id, to_token_id, value);
            to_token_id
        }

        fn _spend_allowance(
            ref self: ComponentState<TContractState>, spender: ContractAddress, token_id: u256, value: u256
        ) {
            // [Compute] Spender allowance
            let erc721_comp = get_dep_component!(@self, ERC721);
            let owner = erc721_comp.owner_of(token_id);
            let current_allowance = self._erc3525_approved_values.read((owner, token_id, spender));
            let infinity: u256 = BoundedInt::max();
            let is_approved = erc721_comp._is_approved_or_owner(
                spender, token_id
            );

            // [Effect] Update allowance if the rights are limited
            if current_allowance == infinity || is_approved {
                return ();
            }
            assert(current_allowance >= value, Errors::INSUFFICIENT_ALLOWANCE);
            let new_allowance = current_allowance - value;
            self._approve_value(token_id, spender, new_allowance);
        }

        fn _mint_new(
            ref self: ComponentState<TContractState>, to: ContractAddress, slot: u256, value: u256
        ) -> u256 {
            // [Effect] Generate a new token_id and mint it
            let token_id = self._get_new_token_id();
            self._mint(to, token_id, slot, value);
            token_id
        }

        fn _mint(
            ref self: ComponentState<TContractState>, to: ContractAddress, token_id: u256, slot: u256, value: u256
        ) {
            // [Check] Token id not already exists
            self._assert_not_minted(token_id);

            // [Check] Receiver address, slot and antoken_id are not null
            assert(!to.is_zero(), Errors::INVALID_ADDRESS);
            assert(slot != 0, Errors::INVALID_SLOT);
            assert(token_id != 0, Errors::INVALID_TOKEN_ID);

            // [Effect] Mint token and value
            self._mint_token(to, token_id, slot);
            self._mint_value(token_id, value);
        }

        fn _mint_token(ref self: ComponentState<TContractState>, to: ContractAddress, token_id: u256, slot: u256) {
            // [Effect] Mint a new enumerable token if supported, standard token otherwise
            let mut erc721_comp = get_dep_component_mut!(ref self, ERC721);
            erc721_comp._mint(to, token_id);

            // [Effect] Store slot
            self._erc3525_slots.write(token_id, slot);

            // [Effect] Update new total minted
            self._erc3525_total_minted.write(self._erc3525_total_minted.read() + 1);

            // [Event] Emit SlotChanged
            self.emit(SlotChanged { token_id, old_slot: 0.into(), new_slot: slot });
        }

        fn _mint_value(ref self: ComponentState<TContractState>, token_id: u256, value: u256) {
            // [Check] Token exists
            self._assert_minted(token_id);

            // [Effect] Update token value
            self._erc3525_values.write(token_id, self._erc3525_values.read(token_id) + value);

            // [Effect] Update total value
            let slot = self.slot_of(token_id);
            let _total = self._erc3525_total_value.read(slot);
            self._erc3525_total_value.write(slot, self._erc3525_total_value.read(slot) + value);

            // [Event] Emit TransferValue
            self.emit(TransferValue { from_token_id: 0.into(), to_token_id: token_id, value });
        }

        fn _transfer_value(
            ref self: ComponentState<TContractState>, from_token_id: u256, to_token_id: u256, value: u256
        ) {
            // [Check] Tokens exist and not null
            self._assert_minted(from_token_id);
            self._assert_minted(to_token_id);
            assert(from_token_id != 0, Errors::INVALID_FROM_TOKEN_ID);
            assert(to_token_id != 0, Errors::INVALID_TO_TOKEN_ID);

            // [Check] Tokens slot match
            assert(
                self.slot_of(from_token_id) == self.slot_of(to_token_id), Errors::SLOT_MISTMATCH
            );

            // [Check] Transfer amount does not exceed balance
            let from_balance = self._erc3525_values.read(from_token_id);
            assert(from_balance >= value, Errors::VALUE_EXCEEDS_BALANCE);

            // [Effect] Update tokens balance
            self._erc3525_values.write(from_token_id, from_balance - value);
            let to_balance = self._erc3525_values.read(to_token_id);
            self._erc3525_values.write(to_token_id, to_balance + value);

            // [Interaction] Receiver
            // let unsafe_state = ERC721::unsafe_new_contract_state();
            // let owner = ERC721::ERC721Impl::owner_of(@unsafe_state, to_token_id);
            // let data = ArrayTrait::new();
            // let success = self._check_on_erc3525_received(from_token_id, to_token_id, owner, value, data.span());

            // TODO: Enable when main stream accounts accept SRC6
            // assert(success, Errors::INVALID_RECEIVER);

            // [Event] Emit TransferValue
            self.emit(TransferValue { from_token_id, to_token_id, value });
        }

        fn _burn(ref self: ComponentState<TContractState>, token_id: u256) {
            // [Check] Token exists
            self._assert_minted(token_id);

            // [Effect] Burn token
            let mut erc721_comp = get_dep_component_mut!(ref self, ERC721);
            erc721_comp._burn(token_id);

            // [Effect] Update token and total value
            let value = self._erc3525_values.read(token_id);
            let slot = self._erc3525_slots.read(token_id);
            self._erc3525_values.write(token_id, 0.into());
            self._erc3525_total_value.write(slot, self._erc3525_total_value.read(slot) - value);

            // [Effect] Update slot
            self._erc3525_slots.write(token_id, 0.into());

            // [Event] Emit TransferValue and SlotChanged
            self.emit(TransferValue { from_token_id: token_id, to_token_id: 0.into(), value });
            self.emit(SlotChanged { token_id, old_slot: slot, new_slot: 0.into() });
        }

        fn _burn_value(ref self: ComponentState<TContractState>, token_id: u256, value: u256) {
            // [Check] Token exists
            self._assert_minted(token_id);

            // [Check] Burn value does not exceed balance
            let balance = self._erc3525_values.read(token_id);
            assert(balance >= value, Errors::VALUE_EXCEEDS_BALANCE);

            // [Effect] Update token and total value
            let slot = self._erc3525_slots.read(token_id);
            self._erc3525_values.write(token_id, balance - value);
            self._erc3525_total_value.write(slot, self._erc3525_total_value.read(slot) - value);

            // [Event] Emit TransferValue
            self.emit(TransferValue { from_token_id: token_id, to_token_id: 0.into(), value });
            return ();
        }

        fn _check_on_erc3525_received(
            self: @ComponentState<TContractState>,
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
                let selector = contract
                    .on_erc3525_received(operator, from_token_id, to_token_id, value, data);
                assert(selector == IERC3525_RECEIVER_ID, Errors::RECEIVER_REJECTION);
                return true;
            }
            contract.supports_interface(ISRC6_ID)
        }

        fn _split(ref self: ComponentState<TContractState>, token_id: u256, amounts: @Array<u256>) -> Array<u256> {
            // [Check] Token exists
            self._assert_minted(token_id);

            // [Check] Amounts are not null
            assert(amounts.len() > 1, Errors::INVALID_AMOUNTS);

            // [Check] Amounts
            let mut total_amount: u256 = 0;
            let mut index = 0;
            loop {
                if index >= amounts.len() {
                    break;
                }
                let amount = *amounts[index];
                assert(amount != 0, Errors::INVALID_AMOUNTS);
                total_amount += amount;
                index += 1;
            };
            assert(total_amount != 0.into(), Errors::INVALID_AMOUNTS);

            // [Check] Amounts sum does not exceed balance
            let balance = self._erc3525_values.read(token_id);
            assert(balance >= total_amount, Errors::VALUE_EXCEEDS_BALANCE);

            // [Effect] Update token and total value
            let slot = self._erc3525_slots.read(token_id);
            let erc721_comp = get_dep_component!(@self, ERC721);
            let owner = erc721_comp.owner_of(token_id);
            self._erc3525_values.write(token_id, balance - total_amount);

            // [Effect] Mint new tokens
            let mut new_token_ids = ArrayTrait::new();
            let mut index = 0;
            loop {
                if index >= amounts.len() {
                    break;
                }
                let amount = *amounts[index];
                // [Warning] _mint_new will emit TransferValue where from is 0
                let new_token_id = self._mint_new(owner, slot, amount);
                new_token_ids.append(new_token_id);
                index += 1;
            };
            return new_token_ids;
        }
        fn _merge(ref self: ComponentState<TContractState>, token_ids: @Array<u256>) {
            // [Check] Token ids are not null
            assert(token_ids.len() > 1, Errors::INVALID_TOKEN_IDS);

            // [Effect] Merge token values
            let erc721_comp = get_dep_component!(@self, ERC721);
            let mut index = 0;
            loop {
                if index + 1 >= token_ids.len() {
                    break;
                }
                // [Check] From token id exist
                let from_token_id = *token_ids[index];
                self._assert_minted(from_token_id);
                // [Check] To token id exist
                let to_token_id = *token_ids[index];
                self._assert_minted(to_token_id);
                // [Check] Token ids slot match
                assert(
                    self.slot_of(from_token_id) == self.slot_of(to_token_id), Errors::SLOT_MISTMATCH
                );
                // [Check] Owners match
                let from_owner = erc721_comp.owner_of(from_token_id);
                let to_owner = erc721_comp.owner_of(to_token_id);
                assert(from_owner == to_owner, Errors::OWNER_MISTMATCH);
                // [Effect] Merge tokens
                let value = self._erc3525_values.read(from_token_id);
                self._transfer_value(from_token_id, to_token_id, value);
                // [Effect] Burn from token
                self._burn(from_token_id);
                index += 1;
            };
        }
    }


    #[generate_trait]
    impl AssertImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721: ERC721Component::HasComponent<TContractState>
    > of AssertTrait<TContractState> {
        fn _assert_minted(self: @ComponentState<TContractState>, token_id: u256) {
            let erc721_comp = get_dep_component!(self, ERC721);
            let exists = erc721_comp._exists(token_id);
            assert(exists, Errors::TOKEN_NOT_MINTED);
        }

        fn _assert_not_minted(self: @ComponentState<TContractState>, token_id: u256) {
            let erc721_comp = get_dep_component!(self, ERC721);
            let exists = erc721_comp._exists(token_id);
            assert(!exists, Errors::TOKEN_ALREADY_MINTED);
        }
    }
}
