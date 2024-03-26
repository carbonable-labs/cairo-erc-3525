use starknet::ContractAddress;
use starknet::contract_address_const;
use zeroable::Zeroable;

// Constants

const VALUE_DECIMALS: u8 = 6;
const TOKEN_ID_1: u256 = 1;
const TOKEN_ID_2: u256 = 2;
const INVALID_TOKEN: u256 = 666;
const SLOT_1: u256 = 'SLOT1';
const SLOT_2: u256 = 'SLOT2';
const VALUE: u256 = 1000;
const CONTRACT_URI: felt252 = 'CONTRACT_URI';
const SLOT_URI: felt252 = 'SLOT_URI';

// Addresses

fn ZERO() -> ContractAddress {
    Zeroable::zero()
}

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

fn RECIPIENT() -> ContractAddress {
    contract_address_const::<'RECIPIENT'>()
}

fn SPENDER() -> ContractAddress {
    contract_address_const::<'SPENDER'>()
}

fn OPERATOR() -> ContractAddress {
    contract_address_const::<'OPERATOR'>()
}

fn SOMEONE() -> ContractAddress {
    contract_address_const::<'SOMEONE'>()
}

fn ANYONE() -> ContractAddress {
    contract_address_const::<'ANYONE'>()
}

fn NAME() -> ByteArray {
    "NAME"
}

fn SYMBOL() -> ByteArray {
    "SYMBOL"
}

fn BASE_URI() -> ByteArray {
    "BASE_URI"
}
