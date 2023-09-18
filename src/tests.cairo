mod unit {
    mod constants;
    mod test_initialization;
    mod test_approvals;
    mod test_mint_burn;
}

mod mocks {
    mod account;
    mod receiver;
}

#[cfg(test)]
mod integration {
    mod constants;
    mod test_base;
    mod test_receiver;
    mod test_metadata;
    mod test_slot_approvable;
    mod test_slot_enumerable;
}
