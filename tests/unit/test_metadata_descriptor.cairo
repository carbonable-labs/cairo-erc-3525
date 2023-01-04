%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin

from openzeppelin.introspection.erc165.library import ERC165
from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.library import ERC3525
from carbonable.erc3525.periphery.library import ERC3525MetadataDescriptor

from tests.unit.library import assert_that

const NAME = 'Carbonable Project';
const SYMBOL = 'CP';
const DECIMALS = 18;
const ADMIN = 'admin';
const USER1 = 'user1';
const USER2 = 'user2';
const USER3 = 'user3';
const INVALID_ID = 666;
const SLOT1 = 'slot1';
const SLOT2 = 'slot2';

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ERC721.initializer(NAME, SYMBOL);
    ERC721Enumerable.initializer();
    ERC3525.initializer(DECIMALS);
    ERC3525._mint(USER1, Uint256(1, 0), Uint256(SLOT1, 0), Uint256(42, 0));
    ERC3525._mint(USER2, Uint256(2, 0), Uint256(SLOT1, 0), Uint256(21, 0));
    ERC3525._mint(USER1, Uint256(3, 0), Uint256(SLOT2, 0), Uint256(21, 0));

    // Old URIs setters
    ERC3525._set_contract_uri('ipfs://');
    ERC3525._set_slot_uri(Uint256(1, 0), 'ipfs://slot');
    return ();
}

@view
func test_contract_uri{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() {
    let instance = 123456;  // Fake instance
    let name = 'protostar test name';
    %{
        mock_call(ids.instance, "name", [int(b'test name'.hex(), 16)])
        mock_call(ids.instance, "valueDecimals", [18])
    %}
    let (uri_len, uri) = ERC3525MetadataDescriptor.constructContractURI{instance=instance}();
    %{
        import json
        tmp = []
        for i in range(ids.uri_len):
            tmp.append(chr(memory[ids.uri + i]))
        uri = "".join(tmp)
        json_uri = json.loads(uri)

        assert json_uri["name"] == "test name"
        assert json_uri["description"] == "dummy description"
        assert json_uri["image"] == "dummy image"
        assert json_uri["valueDecimals"] == 18
    %}
    assert 1 = 1;
    return ();
}

@view
func test_slot_uri{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() {
    let slot = Uint256(SLOT1, 0);
    let instance = 123456;  // Fake instance

    let (uri_len, uri) = ERC3525MetadataDescriptor.constructSlotURI{instance=instance}(slot);
    %{
        import json
        tmp = []
        for i in range(ids.uri_len):
            tmp.append(chr(memory[ids.uri + i]))
        uri = "".join(tmp)
        json_uri = json.loads(uri)

        assert json_uri["name"] == "dummy slot name"
        assert json_uri["description"] == "dummy slot description"
        assert json_uri["image"] == "dummy slot image"
        assert json_uri["properties"] == "dummy slot properties"
    %}
    assert 1 = 1;
    return ();
}

@view
func test_token_uri{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, bitwise_ptr: BitwiseBuiltin*, range_check_ptr
}() {
    let token_id = Uint256(1, 0);
    let slot = Uint256(SLOT1, 0);
    let instance = 123456;  // Fake instance
    %{
        mock_call(ids.instance, "valueOf", [42,0])
        mock_call(ids.instance, "slotOf", [ids.SLOT1, 0])
    %}
    let (uri_len, uri) = ERC3525MetadataDescriptor.constructTokenURI{instance=instance}(token_id);
    %{
        import json
        tmp = []
        for i in range(ids.uri_len):
            tmp.append(chr(memory[ids.uri + i]))
        uri = "".join(tmp)
        json_uri = json.loads(uri)

        assert json_uri["name"] == "dummy token name"
        assert json_uri["description"] == "dummy token description"
        assert json_uri["image"] == "dummy token image"
        assert json_uri["slot"] == ids.SLOT1
        assert json_uri["value"] == 42
        assert json_uri["properties"] == "dummy token properties"
    %}
    assert 1 = 1;
    return ();
}
