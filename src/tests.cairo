mod unit {
    mod constants;
    mod test_initialization;
    mod test_approvals;
}

mod mocks {
    mod account;
}

#[cfg(test)]
mod integration {
    mod constants;
    mod test_base;
    mod test_metadata;
    mod test_slot_approvable;
    mod test_slot_enumerable;
}
