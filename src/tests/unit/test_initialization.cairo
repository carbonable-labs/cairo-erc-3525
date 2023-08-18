use cairo_erc_3525::module::ERC3525;
use cairo_erc_3525::tests::unit::constants::{STATE, VALUE_DECIMALS};


// Tests initialization

#[test]
#[available_gas(20000000)]
fn test_can_set_valid_decimals() {
    let mut state = STATE();
    ERC3525::InternalImpl::initializer(ref state, VALUE_DECIMALS);
    assert(ERC3525::ERC3525Impl::value_decimals(@state) == VALUE_DECIMALS, 'Wrong value decimals');
}
