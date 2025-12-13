/// Uniswap v2 factory like program
module flowxswap::factory {
    use std::string::{String};

    use sui::tx_context::{Self, TxContext};
    use sui::bag::{Self, Bag};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::event;

    use flowxswap::type_helper;
    use flowxswap::swap_utils;
    use flowxswap::pair::{Self, PairMetadata};
    use flowxswap::treasury::{Self, Treasury};

    const ZERO_ADDRESS: address = @zero;

    const ERROR_PAIR_ALREADY_CREATED: u64 = 0;
    const ERROR_PAIR_UNSORTED: u64 = 1;
    
    /// The container that holds all of AMM's liquidity pools
    struct Container has key {
        /// the ID of this container
        id: UID,
        /// AMM's liquidity pool collection.
        pairs: Bag,
        ///AMM's treasury.
        treasury: Treasury
    }

    /// Capability allow appoints new treasurer
    struct AdminCap has key, store {
        id: UID,
    }

    /// Emitted when liquidity pool is created from user.
    struct PairCreated has copy, drop {
        user: address,
        pair: String,
        coin_x: String,
        coin_y: String,
    }

    /// Emitted when fee rate is changed from user
    struct FeeChanged has copy, drop {
        user: address,
        coin_x: String,
        coin_y: String,
        fee_rate: u64
    }

    fun init(ctx: &mut TxContext) {
        abort 0
    }

    /// Creates a liquidity pool of two coins X and Y.
    /// The liquidity pool of the two coins must not exist yet.
    public fun create_pair<X, Y>(container: &mut Container, ctx: &mut TxContext) {
      abort 0
    }

    /// Whether the liquidity pool of the two coins has been created?
    public fun pair_is_created<X, Y>(container: &Container): bool {
       abort 0
    }

    /// Immutable borrows the `PairMetadata` of two coins X and Y.
    /// Two coins X and Y must be sorted.
    public fun borrow_pair<X, Y>(container: &Container): &PairMetadata<X, Y> {
        abort 0
    }

    /// Mutable borrows the `PairMetadata` of two coins X and Y.
    /// Two coins X and Y must be sorted.
    public fun borrow_mut_pair<X, Y>(container: &mut Container): (&mut PairMetadata<X, Y>) {
        abort 0
    }

    /// Mutable borrows the `PairMetadata` of two coins X and Y and the immutable borrow the treasury of AMM.
    /// Two coins X and Y must be sorted.
    public fun borrow_mut_pair_and_treasury<X, Y>(container: &mut Container): (&mut PairMetadata<X, Y>, &Treasury) {
        abort 0
    }

    /// Immutable borrows the `Treasury` of AMM.
    public fun borrow_treasury(container: &Container): &Treasury {
       abort 0
    }

    /// Appoints a new treasurer to the treasury
    public entry fun set_fee_to(_: &mut AdminCap, container: &mut Container, fee_to: address) {
        abort 0
    }

    fun set_fee_rate_<X, Y>(
        container: &mut Container, 
        new_fee_rate: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    public entry fun set_fee_rate<X, Y>(
        _: &mut AdminCap,
        container: &mut Container, 
        new_fee_rate: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }
}
