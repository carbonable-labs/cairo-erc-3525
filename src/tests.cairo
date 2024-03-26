#[cfg(test)]
mod unit {
    mod constants;
    mod test_initialization;
    mod test_approvals;
    mod test_metadata;
    mod test_mint_burn;
    mod test_slot_approvable;
    mod test_slot_enumerable;
    mod test_transfer_to_address;
    mod test_transfer_to_token;
    mod test_views;
}

mod mocks {
    mod receiver;
    mod contracts;
}

mod utils;

#[cfg(test)]
mod integration {
    mod constants;
    mod test_base;
    mod test_receiver;
    mod test_metadata;
    mod test_slot_approvable;
    mod test_slot_enumerable;
}
