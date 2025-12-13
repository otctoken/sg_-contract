/// Uniswap v2 pair like program
module flowxswap::pair {
    use std::string::{Self, String};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Supply};
    use sui::transfer;
    use sui::event;

    use flowxswap::math;
    use flowxswap::type_helper;
    use flowxswap::treasury::{Self, Treasury};

    friend flowxswap::factory;

    /// 
    /// constants 
    /// 
    const MINIMUM_LIQUIDITY: u64 = 1000;
    const ZERO_ADDRESS: address = @zero;
    const FEE_PRECISION: u64 = 10000;

    /// 
    /// errors
    /// 
    const ERROR_INSUFFICIENT_LIQUIDITY_MINTED :u64 = 0;
    const ERROR_INSUFFICIENT_LIQUIDITY_BURNED :u64 = 1;
    const ERROR_INSUFFICIENT_INPUT_AMOUNT: u64 = 2;
    const ERROR_INSUFFICIENT_OUTPUT_AMOUNT: u64 = 3;
    const ERROR_INSUFFICIENT_LIQUIDITY: u64 = 4;
    const ERROR_K: u64 = 5;
    const ERROR_INVALID_FEE: u64 = 6;

    /// LP Coins represent the liquidity of two coins X and Y
    struct LP<phantom X, phantom Y> has drop {}

    /// Metadata of each liquidity pool.
    struct PairMetadata<phantom X, phantom Y> has key, store {
        /// the ID of liquidity pool of two coins X and Y
        id: UID,
        /// the reserve of coin X in pool
        reserve_x: Coin<X>,
        /// the reserve of coin Y in pool
        reserve_y: Coin<Y>,
        /// the last value of k
        k_last: u128,
        /// the total supply of LP coin
        lp_supply: Supply<LP<X, Y>>,
        /// the fee rate of pair
        fee_rate: u64 
    }

    /// Emitted when liquidity is added from user
    struct LiquidityAdded has copy, drop {
        user: address,
        coin_x: String,
        coin_y: String,
        amount_x: u64,
        amount_y: u64,
        liquidity: u64,
        fee: u64
    }

    /// Emitted when liquidity is removed from user
    struct LiquidityRemoved has copy, drop {
        user: address,
        coin_x: String,
        coin_y: String,
        amount_x: u64,
        amount_y: u64,
        liquidity: u64,
        fee: u64
    }

    /// Emitted when coin X is swapped to coin Y from user
    struct Swapped has copy, drop {
        user: address,
        coin_x: String,
        coin_y: String,
        amount_x_in: u64,
        amount_y_in: u64,
        amount_x_out: u64,
        amount_y_out: u64,
    }

    /// Returns the reserve of coins X and Y.
    public fun get_reserves<X, Y>(metadata: &PairMetadata<X, Y>): (u64, u64) {
        abort 0
    }

    /// Returns the total supply of LP coin.
    public fun total_lp_supply<X, Y>(metadata: &PairMetadata<X, Y>): u64 {
       abort 0
    }

    /// Returns the k last.
    public fun k<X, Y>(metadata: &PairMetadata<X, Y>): u128 {
        abort 0
    }

    public fun fee_rate<X, Y>(metadata: &PairMetadata<X, Y>): u64 {
        abort 0
    }

    /// Updates the k last.
    fun update_k_last<X, Y>(metadata: &mut PairMetadata<X, Y>) {
        abort 0
    }

    /// LP name includes type name of coin X and Y.
    public fun get_lp_name<X, Y>(): String {
        abort 0
    }

    /// Creates a liquidity pool of two coins X and Y.
    public(friend) fun create_pair<X, Y>(ctx: &mut TxContext): PairMetadata<X, Y> {        
        abort 0
    }

    /// Change fee rate of pair
    public(friend) fun set_fee_rate<X, Y>(metadata: &mut PairMetadata<X, Y>, new_fee_rate: u64) {
       abort 0
    }
    

    /// Deposits coin X to liquidity pool.
    fun deposit_x<X, Y>(metadata: &mut PairMetadata<X, Y>, coin_x: Coin<X>) {
        abort 0
    }

    /// Deposits coin Y to liquidity pool.
    fun deposit_y<X, Y>(metadata: &mut PairMetadata<X, Y>, coin_y: Coin<Y>) {
        abort 0
    }

    /// Returns an LP coin worth `amount`
    fun mint_lp<X, Y>(metadata: &mut PairMetadata<X, Y>, amount: u64, ctx: &mut TxContext): Coin<LP<X, Y>> {
        abort 0
    }

    /// Burns an LP coin
    fun burn_lp<X, Y>(metadata: &mut PairMetadata<X, Y>, lp_coin: Coin<LP<X, Y>>) {
        let lp_balance = coin::into_balance<LP<X, Y>>(lp_coin);
        balance::decrease_supply(&mut metadata.lp_supply, lp_balance);
    }

    /// Extract an X coin worth `amount` from the reserves of the liquidity pool.
    fun extract_x<X, Y>(metadata: &mut PairMetadata<X, Y>, amount: u64, ctx: &mut TxContext): Coin<X> {
       abort 0
    }

    /// Extract an Y coin worth `amount` from the reserves of the liquidity pool.
    fun extract_y<X, Y>(metadata: &mut PairMetadata<X, Y>, amount: u64, ctx: &mut TxContext): Coin<Y> {
        abort 0
    }
    
    /// Mints protocol fee.
    fun mint_fee<X, Y>(metadata: &mut PairMetadata<X, Y>, fee_to: address, ctx: &mut TxContext): u64 {
        abort 0
    }

    /// Mints LP coins corresponding to the amount of X or Y coins deposited into the liquidity pool.
    public fun mint<X, Y>(metadata: &mut PairMetadata<X, Y>, treasury: &Treasury, coin_x: Coin<X>, coin_y: Coin<Y>,  ctx: &mut TxContext): (Coin<LP<X, Y>>) {
        abort 0
    }

    /// Burns LP coin and return X and Y coins of corresponding value.
    public fun burn<X, Y>(metadata: &mut PairMetadata<X, Y>, treasury: &Treasury, lp_coin: Coin<LP<X, Y>>, ctx: &mut TxContext): (Coin<X>, Coin<Y>) {
        abort 0
    }

    /// Swaps X coins to Y coins or Y coins to X coins based on the "constant product formula".
    /// The coins must be deposited into the liquidity pool before calling this function.
    public fun swap<X, Y>(metadata: &mut PairMetadata<X, Y>, coin_x: Coin<X>, amount_x_out: u64, coin_y: Coin<Y>, amount_y_out: u64, ctx: &mut TxContext): (Coin<X>, Coin<Y>) {
       abort 0
    }
}
