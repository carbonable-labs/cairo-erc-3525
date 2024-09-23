// Local imports
use cairo_erc_3525::module::{ERC3525Component, ERC3525Component::{ERC3525Impl, InternalImpl}};
use super::constants::{COMPONENT_STATE, VALUE_DECIMALS};


// Tests initialization
#[test]
#[available_gas(20000000)]
fn test_can_set_valid_decimals() {
    let mut state = COMPONENT_STATE();
    state.initializer(VALUE_DECIMALS);
    assert(state.value_decimals() == VALUE_DECIMALS, 'Wrong value decimals');
}
