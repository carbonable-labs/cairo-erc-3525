#[starknet::contract]
mod ERC3525SlotApprovable {
    use starknet::{get_caller_address, ContractAddress};
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use zeroable::Zeroable;
    use integer::BoundedInt;

    use cairo_erc_721::src5::module::SRC5;
    use cairo_erc_721::module::ERC721;
    use cairo_erc_3525::module::ERC3525;
    use cairo_erc_3525::extensions::slotapprovable::interface::{
        IERC3525SlotApprovable, IERC3525_SLOT_APPROVABLE_ID
    };

    #[storage]
    struct Storage {
        _slot_approvals: LegacyMap::<(ContractAddress, u256, ContractAddress), bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ApprovalForSlot: ApprovalForSlot,
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForSlot {
        owner: ContractAddress,
        slot: u256,
        operator: ContractAddress,
        approved: bool,
    }

    #[external(v0)]
    impl ERC3525SlotApprovableImpl of IERC3525SlotApprovable<ContractState> {
        fn set_approval_for_slot(
            ref self: ContractState,
            owner: ContractAddress,
            slot: u256,
            operator: ContractAddress,
            approved: bool
        ) {
            // [Check] Caller and operator are not null
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'ERC3525: invalid caller');
            assert(!operator.is_zero(), 'ERC3525: invalid operator');

            // [Check] Caller is owner or approved for all
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let is_approved_for_all = ERC721::ERC721Impl::is_approved_for_all(
                @unsafe_state, operator, owner
            );
            assert(caller == owner || is_approved_for_all, 'ERC3525: caller not allowed');

            // [Check] No self approval
            assert(caller != operator, 'ERC3525: self approval');

            // [Effect] Store approval
            self._slot_approvals.write((owner, slot, operator), approved);

            // [Event] Emit ApprovalForSlot
            self.emit(ApprovalForSlot { owner, slot, operator, approved });
        }

        fn is_approved_for_slot(
            self: @ContractState, owner: ContractAddress, slot: u256, operator: ContractAddress
        ) -> bool {
            self._slot_approvals.read((owner, slot, operator))
        }
    }

    #[generate_trait]
    impl ExternalImpl of ExternalTrait {
        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            // [Check] Caller is allowed
            let caller = get_caller_address();
            self._assert_allowed(caller, token_id);
            // [Note] ERC721 allows approval to owner

            // [Effect] Store approval
            let mut unsafe_state = ERC721::unsafe_new_contract_state();
            ERC721::InternalImpl::_approve(ref unsafe_state, to, token_id);
        }

        fn approve_value(
            ref self: ContractState, token_id: u256, operator: ContractAddress, value: u256
        ) {
            // [Check] Caller and operator are not null addresses
            let caller = get_caller_address();
            assert(!caller.is_zero(), 'ERC3525: invalid caller');
            assert(!operator.is_zero(), 'ERC3525: invalid operator');

            // [Check] Operator is not owner and caller is approved or owner
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::ERC721Impl::owner_of(@unsafe_state, token_id);
            assert(owner != operator, 'ERC3525: approval to owner');
            self._assert_allowed(caller, token_id);

            // [Effect] Store approved value
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            ERC3525::InternalImpl::_approve_value(ref unsafe_state, token_id, operator, value);
        }

        fn transfer_value_from(
            ref self: ContractState,
            from_token_id: u256,
            to_token_id: u256,
            to: ContractAddress,
            value: u256
        ) -> u256 {
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
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            match to_token_id.try_into() {
                // Into felt252 works
                Option::Some(token_id) => {
                    match token_id {
                        // If token_id is zero, transfer value to address
                        0 => ERC3525::InternalImpl::_transfer_value_to(
                            ref unsafe_state, from_token_id, to, value
                        ),
                        // Otherwise, transfer value to token
                        _ => ERC3525::InternalImpl::_transfer_value_to_token(
                            ref unsafe_state, from_token_id, to_token_id, value
                        ),
                    }
                },
                // Into felt252 fails, so token_id is not zero
                Option::None(()) => ERC3525::InternalImpl::_transfer_value_to_token(
                    ref unsafe_state, from_token_id, to_token_id, value
                ),
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState) {
            // [Effect] Register interfaces
            let mut unsafe_state = SRC5::unsafe_new_contract_state();
            SRC5::InternalImpl::register_interface(ref unsafe_state, IERC3525_SLOT_APPROVABLE_ID);
        }

        fn _spend_allowance(
            ref self: ContractState, spender: ContractAddress, token_id: u256, value: u256
        ) {
            // [Compute] Spender allowance
            let is_approved = self._is_allowed(spender, token_id);
            let mut unsafe_state = ERC3525::unsafe_new_contract_state();
            let current_allowance = ERC3525::ERC3525Impl::allowance(
                @unsafe_state, token_id, spender
            );
            let infinity: u256 = BoundedInt::max();

            // [Effect] Update allowance if the rights are limited
            if current_allowance == infinity || is_approved {
                return ();
            }
            assert(current_allowance >= value, 'ERC3525: insufficient allowance');
            let new_allowance = current_allowance - value;
            ERC3525::InternalImpl::_approve_value(
                ref unsafe_state, token_id, spender, new_allowance
            );
        }

        fn _is_allowed(self: @ContractState, operator: ContractAddress, token_id: u256) -> bool {
            // [Compute] Operator is owner or approved for all
            let unsafe_state = ERC721::unsafe_new_contract_state();
            let owner = ERC721::ERC721Impl::owner_of(@unsafe_state, token_id);
            let is_owner_or_approved = ERC721::InternalImpl::_is_approved_or_owner(
                @unsafe_state, operator, token_id
            );

            // [Compute] Operator is approved for slot
            let unsafe_state = ERC3525::unsafe_new_contract_state();
            let slot = ERC3525::ERC3525Impl::slot_of(@unsafe_state, token_id);
            let is_approved_for_slot = self.is_approved_for_slot(owner, slot, operator);

            // [Check] Operator allowance
            is_owner_or_approved || is_approved_for_slot
        }
    }

    #[generate_trait]
    impl AssertImpl of AssertTrait {
        fn _assert_allowed(self: @ContractState, operator: ContractAddress, token_id: u256) {
            // [Check] Operator is allowed
            assert(self._is_allowed(operator, token_id), 'ERC3525: caller not allowed');
        }
    }
}
