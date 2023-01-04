// SPDX-License-Identifier: MIT

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from cairopen.string.ASCII import StringCodec
from cairopen.string.string import String
from cairopen.string.utils import StringUtil

from carbonable.erc3525.IERC3525Full import IERC3525Full as IERC3525

namespace ERC3525MetadataDescriptor {
    func constructContractURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }() -> (uri_len: felt, uri: felt*) {
        alloc_locals;

        let (local tmp_name) = IERC3525.name(instance);
        let (local desc_str) = _contractDescription{instance=instance}();
        let (local img_str) = _contractImage{instance=instance}();
        let (decimals) = IERC3525.valueDecimals(instance);
        let (local decimals_str) = StringCodec.felt_to_string(decimals);

        let (str) = StringCodec.ss_to_string('{"name":"');
        let (str) = append_ss(str, tmp_name);
        let (str) = append_ss(str, '","description":"');
        let (str) = StringUtil.concat(str, desc_str);
        let (str) = append_ss(str, '","image":"');
        let (str) = StringUtil.concat(str, img_str);
        let (str) = append_ss(str, '","valueDecimals":');
        let (str) = StringUtil.concat(str, decimals_str);
        let (str) = append_ss(str, '}');

        return (str.len, str.data);
    }

    func constructSlotURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(slot: Uint256) -> (uri_len: felt, uri: felt*) {
        alloc_locals;
        let (local name_str) = _slotName{instance=instance}(slot);
        let (local desc_str) = _slotDescription{instance=instance}(slot);
        let (local img_str) = _slotImage{instance=instance}(slot);
        let (local props_str) = _slotProperties{instance=instance}(slot);

        let (str) = StringCodec.ss_to_string('{"name":"');
        let (str) = StringUtil.concat(str, name_str);
        let (str) = append_ss(str, '","description":"');
        let (str) = StringUtil.concat(str, desc_str);
        let (str) = append_ss(str, '","image":"');
        let (str) = StringUtil.concat(str, img_str);
        let (str) = append_ss(str, '","properties":"');
        let (str) = StringUtil.concat(str, props_str);
        let (str) = append_ss(str, '"}');

        return (str.len, str.data);
    }

    func constructTokenURI{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(tokenId: Uint256) -> (uri_len: felt, uri: felt*) {
        alloc_locals;

        let (local name_str) = _tokenName{instance=instance}(tokenId);
        let (local desc_str) = _tokenDescription{instance=instance}(tokenId);
        let (local img_str) = _tokenImage{instance=instance}(tokenId);
        let (local props_str) = _tokenProperties{instance=instance}(tokenId);

        let (slot) = IERC3525.slotOf(instance, tokenId);
        let (local slot_str) = StringCodec.felt_to_string(slot.low);

        let (value) = IERC3525.valueOf(instance, tokenId);
        let (local value_str) = StringCodec.felt_to_string(value.low);

        let (str) = StringCodec.ss_to_string('{"name":"');
        let (str) = StringUtil.concat(str, name_str);
        let (str) = append_ss(str, '","description":"');
        let (str) = StringUtil.concat(str, desc_str);
        let (str) = append_ss(str, '","image":"');
        let (str) = StringUtil.concat(str, img_str);
        let (str) = append_ss(str, '","slot":');
        let (str) = StringUtil.concat(str, slot_str);
        let (str) = append_ss(str, ',"value":');
        let (str) = StringUtil.concat(str, value_str);
        let (str) = append_ss(str, ',"properties":"');
        let (str) = StringUtil.concat(str, props_str);
        let (str) = append_ss(str, '"}');

        return (str.len, str.data);
    }

    func _contractDescription{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }() -> (uri: String) {
        let (str) = StringCodec.ss_to_string('dummy description');
        return (uri=str);
    }

    func _contractImage{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }() -> (uri: String) {
        let (str) = StringCodec.ss_to_string('dummy image');
        return (uri=str);
    }

    func _slotName{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(slot: Uint256) -> (uri: String) {
        let (str) = StringCodec.ss_to_string('dummy slot name');
        return (uri=str);
    }

    func _slotDescription{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(slot: Uint256) -> (uri: String) {
        let (str) = StringCodec.ss_to_string('dummy slot description');
        return (uri=str);
    }

    func _slotImage{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(slot: Uint256) -> (uri: String) {
        let (str) = StringCodec.ss_to_string('dummy slot image');
        return (uri=str);
    }

    func _slotProperties{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(slot: Uint256) -> (uri: String) {
        let (str) = StringCodec.ss_to_string('dummy slot properties');
        return (uri=str);
    }

    func _tokenName{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(tokenId: Uint256) -> (uri: String) {
        let (str) = StringCodec.ss_to_string('dummy token name');
        return (uri=str);
    }

    func _tokenDescription{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(tokenId: Uint256) -> (uri: String) {
        let (str) = StringCodec.ss_to_string('dummy token description');
        return (uri=str);
    }

    func _tokenImage{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(tokenId: Uint256) -> (uri: String) {
        let (str) = StringCodec.ss_to_string('dummy token image');
        return (uri=str);
    }

    func _tokenProperties{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        bitwise_ptr: BitwiseBuiltin*,
        range_check_ptr,
        instance,
    }(tokenId: Uint256) -> (String,) {
        let (str) = StringCodec.ss_to_string('dummy token properties');
        return (uri=str);
    }
}

func append_ss{bitwise_ptr: BitwiseBuiltin*, range_check_ptr}(str: String, s: felt) -> (
    str: String
) {
    alloc_locals;
    let (tmp_str) = StringCodec.ss_to_string(s);
    let (res) = StringUtil.concat(str, tmp_str);
    return (str=res);
}
