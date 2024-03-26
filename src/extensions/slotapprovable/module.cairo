#[starknet::component]
mod ERC3525SlotApprovableComponent {
    // Core deps
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use zeroable::Zeroable;
    use integer::BoundedInt;

    // Starknet deps
    use starknet::{get_caller_address, ContractAddress};

    // External deps
    use openzeppelin::introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin::introspection::src5::SRC5Component::{SRC5, SRC5Camel};
    use openzeppelin::introspection::src5::SRC5Component;

    use openzeppelin::token::erc721::erc721::ERC721Component::InternalTrait as ERC721InternalTrait;
    use openzeppelin::token::erc721::erc721::ERC721Component::ERC721;
    use openzeppelin::token::erc721::erc721::ERC721Component;

    // Local deps
    use cairo_erc_3525::module::ERC3525Component::InternalTrait as ERC3525InternalTrait;
    use cairo_erc_3525::module::ERC3525Component::ERC3525;
    use cairo_erc_3525::module::ERC3525Component;
    use cairo_erc_3525::extensions::slotapprovable::interface::{
        IERC3525SlotApprovable, IERC3525SlotApprovableCamelOnly, IERC3525_SLOT_APPROVABLE_ID
    };

    #[storage]
    struct Storage {
        _erc3525_slot_approvals: LegacyMap::<(ContractAddress, u256, ContractAddress), bool>,
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

    mod Errors {
        const SELF_APPROVAL: felt252 = 'ERC3525: self approval';
    }

    #[embeddable_as(ERC3525SlotApprovableImpl)]
    impl ERC3525SlotApprovable<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ERC3525Comp: ERC3525Component::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721Comp: ERC721Component::HasComponent<TContractState>
    > of IERC3525SlotApprovable<ComponentState<TContractState>> {
        fn set_approval_for_slot(
            ref self: ComponentState<TContractState>,
            owner: ContractAddress,
            slot: u256,
            operator: ContractAddress,
            approved: bool
        ) {
            // [Check] Caller and operator are not null
            let caller = get_caller_address();
            assert(!caller.is_zero(), ERC3525Component::Errors::INVALID_CALLER);
            assert(!operator.is_zero(), ERC3525Component::Errors::INVALID_OPERATOR);

            // [Check] Caller is owner or approved for all
            let erc721_comp = get_dep_component!(@self, ERC721Comp);
            let is_approved_for_all = erc721_comp.is_approved_for_all(operator, owner);
            assert(
                caller == owner || is_approved_for_all, ERC3525Component::Errors::CALLER_NOT_ALLOWED
            );

            // [Check] No self approval
            assert(caller != operator, Errors::SELF_APPROVAL);

            // [Effect] Store approval
            self._erc3525_slot_approvals.write((owner, slot, operator), approved);

            // [Event] Emit ApprovalForSlot
            self.emit(ApprovalForSlot { owner, slot, operator, approved });
        }

        fn is_approved_for_slot(
            self: @ComponentState<TContractState>,
            owner: ContractAddress,
            slot: u256,
            operator: ContractAddress
        ) -> bool {
            self._erc3525_slot_approvals.read((owner, slot, operator))
        }
    }

    #[embeddable_as(ERC3525SlotApprovableCamelOnlyImpl)]
    impl ERC3525SlotApprovableCamelOnly<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ERC3525Comp: ERC3525Component::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721Comp: ERC721Component::HasComponent<TContractState>
    > of IERC3525SlotApprovableCamelOnly<ComponentState<TContractState>> {
        fn setApprovalForSlot(
            ref self: ComponentState<TContractState>,
            owner: ContractAddress,
            slot: u256,
            operator: ContractAddress,
            approved: bool
        ) {
            self.set_approval_for_slot(owner, slot, operator, approved);
        }

        fn isApprovedForSlot(
            self: @ComponentState<TContractState>,
            owner: ContractAddress,
            slot: u256,
            operator: ContractAddress
        ) -> bool {
            self.is_approved_for_slot(owner, slot, operator)
        }
    }

    #[generate_trait]
    impl ExternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl ERC3525Comp: ERC3525Component::HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        impl ERC721Comp: ERC721Component::HasComponent<TContractState>
    > of ExternalTrait<TContractState> {
        fn approve(ref self: ComponentState<TContractState>, to: ContractAddress, token_id: u256) {
            // [Check] Caller is allowed
            let caller = get_caller_address();
            self._assert_allowed(caller, token_id);
            // [Note] ERC721 allows approval to owner

            // [Effect] Store approval
            let mut erc721_comp = get_dep_component_mut!(ref self, ERC721Comp);
            erc721_comp._approve(to, token_id);
        }

        fn approve_value(
            ref self: ComponentState<TContractState>,
            token_id: u256,
            operator: ContractAddress,
            value: u256
        ) {
            // [Check] Caller and operator are not null addresses
            let caller = get_caller_address();
            assert(!caller.is_zero(), ERC3525Component::Errors::INVALID_CALLER);
            assert(!operator.is_zero(), ERC3525Component::Errors::INVALID_OPERATOR);

            // [Check] Operator is not owner and caller is approved or owner
            let erc721_comp = get_dep_component!(@self, ERC721Comp);
            let owner = erc721_comp.owner_of(token_id);
            assert(owner != operator, ERC3525Component::Errors::APPROVAL_TO_OWNER);
            self._assert_allowed(caller, token_id);

            // [Effect] Store approved value
            let mut erc3525_comp = get_dep_component_mut!(ref self, ERC3525Comp);
            erc3525_comp._approve_value(token_id, operator, value);
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
            assert(!caller.is_zero(), ERC3525Component::Errors::INVALID_CALLER);
            assert(from_token_id != 0.into(), ERC3525Component::Errors::INVALID_FROM_TOKEN_ID);
            assert(value != 0.into(), ERC3525Component::Errors::INVALID_VALUE);

            // [Check] Disambiguate function call: only one of `to_token_id` and `to` must be set
            assert(
                to_token_id == 0.into() || to.is_zero(),
                ERC3525Component::Errors::INVALID_EXCLUSIVE_ARGS
            );

            // [Effect] Spend allowance if possible
            self._spend_allowance(caller, from_token_id, value);

            // [Effect] Transfer value to address
            let mut erc3525_comp = get_dep_component_mut!(ref self, ERC3525Comp);
            if let Option::Some(token_id) = to_token_id.try_into() {
                // Into felt252 works
                match token_id {
                    // If token_id is zero, transfer value to address
                    0 => erc3525_comp._transfer_value_to(from_token_id, to, value),
                    // Otherwise, transfer value to token
                    _ => erc3525_comp._transfer_value_to_token(from_token_id, to_token_id, value),
                }
            } else {
                // Into felt252 fails, so token_id is not zero
                erc3525_comp._transfer_value_to_token(from_token_id, to_token_id, value)
            }
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
            src5_comp.register_interface(IERC3525_SLOT_APPROVABLE_ID);
        }

        fn _spend_allowance(
            ref self: ComponentState<TContractState>,
            spender: ContractAddress,
            token_id: u256,
            value: u256
        ) {
            // [Compute] Spender allowance
            let is_approved = self._is_allowed(spender, token_id);
            let mut erc3525_comp = get_dep_component_mut!(ref self, ERC3525Comp);
            let current_allowance = erc3525_comp.allowance(token_id, spender);
            let infinity: u256 = BoundedInt::max();

            // [Effect] Update allowance if the rights are limited
            if current_allowance == infinity || is_approved {
                return ();
            }
            assert(current_allowance >= value, ERC3525Component::Errors::INSUFFICIENT_ALLOWANCE);
            let new_allowance = current_allowance - value;
            erc3525_comp._approve_value(token_id, spender, new_allowance);
        }

        fn _is_allowed(
            self: @ComponentState<TContractState>, operator: ContractAddress, token_id: u256
        ) -> bool {
            // [Compute] Operator is owner or approved for all
            let erc721_comp = get_dep_component!(self, ERC721Comp);
            let owner = erc721_comp.owner_of(token_id);
            let is_owner_or_approved = erc721_comp._is_approved_or_owner(operator, token_id);

            // [Compute] Operator is approved for slot
            let erc3525_comp = get_dep_component!(self, ERC3525Comp);
            let slot = erc3525_comp.slot_of(token_id);
            let is_approved_for_slot = self.is_approved_for_slot(owner, slot, operator);

            // [Check] Operator allowance
            is_owner_or_approved || is_approved_for_slot
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
        fn _assert_allowed(
            self: @ComponentState<TContractState>, operator: ContractAddress, token_id: u256
        ) {
            // [Check] Operator is allowed
            assert(
                self._is_allowed(operator, token_id), ERC3525Component::Errors::CALLER_NOT_ALLOWED
            );
        }
    }
}
