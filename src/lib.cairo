mod constants;
mod src5 {
    mod interface;
    mod module;
}
mod erc721 {
    mod interface;
    mod module;
    mod extensions {
        mod enumerable {
            mod interface;
            mod module;
        }
        mod metadata {
            mod interface;
            mod module;
        }
    }
    mod presets {
        mod erc721_mintable_burnable_metadata_enumerable;
        mod erc721_mintable_burnable_metadata;
    }
}
mod erc3525{
    mod interface;
    mod module;
    mod extensions {
        mod metadata {
            mod interface;
            mod module;
        }
        mod slotapprovable {
            mod interface;
            mod module;
        }
        mod slotenumerable {
            mod interface;
            mod module;
        }
    }
    mod presets {
    }
}