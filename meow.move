module MyModule::ArtPortfolio {
    use aptos_framework::signer;
    use std::string::String;
    use aptos_framework::timestamp;
    use std::vector;

    /// Struct representing an art NFT with provenance tracking.
    struct ArtNFT has store, key, copy, drop {
        title: String,           // Title of the artwork
        creator: address,        // Original creator's address
        current_owner: address,  // Current owner's address
        creation_time: u64,      // Timestamp when NFT was created
        metadata_uri: String,    // URI pointing to artwork metadata/image
    }

    /// Struct to track all NFTs owned by an address.
    struct ArtCollection has key {
        owned_nfts: vector<ArtNFT>,  // Vector of owned art NFTs
    }

    /// Function to mint a new art NFT for a student's artwork.
    public fun mint_artwork(
        creator: &signer, 
        title: String, 
        metadata_uri: String
    ) acquires ArtCollection {
        let creator_addr = signer::address_of(creator);
        let art_nft = ArtNFT {
            title,
            creator: creator_addr,
            current_owner: creator_addr,
            creation_time: timestamp::now_seconds(),
            metadata_uri,
        };

        // Initialize collection if it doesn't exist
        if (!exists<ArtCollection>(creator_addr)) {
            let collection = ArtCollection {
                owned_nfts: vector::empty<ArtNFT>(),
            };
            move_to(creator, collection);
        };

        // Add NFT to creator's collection
        let collection = borrow_global_mut<ArtCollection>(creator_addr);
        vector::push_back(&mut collection.owned_nfts, art_nft);
    }

    /// Function to transfer ownership of an art NFT to another address.
    public fun transfer_artwork(
        current_owner: &signer,
        new_owner: address,
        nft_index: u64
    ) acquires ArtCollection {
        let owner_addr = signer::address_of(current_owner);
        
        // Remove NFT from current owner's collection
        let owner_collection = borrow_global_mut<ArtCollection>(owner_addr);
        let mut_nft = vector::borrow_mut(&mut owner_collection.owned_nfts, nft_index);
        mut_nft.current_owner = new_owner;

        // Move NFT to new owner's collection
        let nft_copy = *mut_nft;
        let _removed_nft = vector::remove(&mut owner_collection.owned_nfts, nft_index);

        // Initialize new owner's collection if needed
        if (!exists<ArtCollection>(new_owner)) {
            let new_collection = ArtCollection {
                owned_nfts: vector::empty<ArtNFT>(),
            };
            move_to(current_owner, new_collection); // Note: This would need proper authority
        };

        let new_owner_collection = borrow_global_mut<ArtCollection>(new_owner);
        vector::push_back(&mut new_owner_collection.owned_nfts, nft_copy);
    }
}