/// Uniswap v2 router like program
module flowxswap::router {
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::{Self, Clock};

    use flowxswap::pair::{Self, LP, PairMetadata};
    use flowxswap::factory::{Self, Container};
    use flowxswap::treasury::Treasury;
    use flowxswap::swap_utils;

    const ERROR_INSUFFICIENT_X_AMOUNT: u64 = 0;
    const ERROR_INSUFFICIENT_Y_AMOUNT: u64 = 1;
    const ERROR_INVALID_AMOUNT: u64 = 3;
    const ERROR_EXPIRED: u64 = 4;
    const ERROR_INSUFFICIENT_OUTPUT_AMOUNT: u64 = 5;
    const ERROR_EXCESSIVE_INPUT_AMOUNT: u64 = 6;

    fun ensure(clock: &Clock, deadline: u64) {
        assert!(deadline >= clock::timestamp_ms(clock), ERROR_EXPIRED);
    }

    public fun add_liquidity_direct<X, Y>(
        pair: &mut PairMetadata<X, Y>,
        treasury: &Treasury,
        coin_x: Coin<X>,
        coin_y: Coin<Y>,
        amount_x_min: u64,
        amount_y_min: u64,
        ctx: &mut TxContext
        ): Coin<LP<X, Y>> {
        abort 0
    }
    
    /// Add liquidity for two coins X and Y.
    /// A liquidity pool will be created if it does not exist yet.
    ///  * `container` - the container that holds all of AMM's liquidity pools.
    ///  * `vec_coin_x` - list of coins X offered to pay for adding liquidity.
    ///  * `vec_coin_y` - list of coins Y offered to pay for adding liquidity.
    ///  * `amount_x_desired` - desired amount of coin X to add as liquidity.
    ///  * `amount_y_desired` - desired amount of coin Y to add as liquidity.
    ///  * `amount_x_min` - minimum amount of coin X to add as liquidity.
    ///  * `amount_y_min` - minimum amount of coin Y to add as liquidity.
    ///  * `to` - address to receive LP coin.
    ///  * `deadline` - deadline of the transaction.
    public entry fun add_liquidity<X, Y>(
        clock: &Clock,
        container: &mut Container,
        coin_x: Coin<X>,
        coin_y: Coin<Y>,
        amount_x_min: u64,
        amount_y_min: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    /// Remove the liquidity of two coins X and Y.
    ///  * `container` - the container that holds all of AMM's liquidity pools.
    ///  * `lp_coin` - list of coins LP offered to pay for removing liquidity.
    ///  * `amount_lp_desired` - desired amount of coin LP to remove as liquidity.
    ///  * `amount_x_min` - minimum amount of coin X will be received.
    ///  * `amount_y_min` - minimum amount of coin Y will be received.
    ///  * `to` - address to receive coin X and coin Y.
    ///  * `deadline` - deadline of the transaction.
    public entry fun remove_liquidity<X, Y>(
        clock: &Clock,
        container: &mut Container,
        lp_coin: Coin<LP<X, Y>>,
        amount_x_min: u64,
        amount_y_min: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    /// Swap exact coin `X` for coin `Y`.
    public fun swap_exact_x_to_y_direct<X, Y>(
        pair: &mut PairMetadata<X, Y>,
        coin_x_in: Coin<X>,
        ctx: &mut TxContext
    ): Coin<Y> {
        abort 0
    }

    /// Swap exact coin `Y` for coin `X`.
    public fun swap_exact_y_to_x_direct<X, Y>(
        pair: &mut PairMetadata<X, Y>,
        coin_y_in: Coin<Y>,
        ctx: &mut TxContext
    ): Coin<X> {
        abort 0
    }

    public fun swap_exact_input_direct<X, Y>(
        container: &mut Container,
        coin_x_in: Coin<X>,
        ctx: &mut TxContext
    ): Coin<Y> {
        abort 0
    }

    /// Swap exact coin `X` for coin `Y`.
    ///  * `container` - the container that holds all of AMM's liquidity pools.
    ///  * `vec_coin_x_in` - list of coins X offered for swap.
    ///  * `amount_x_desired` - desired amount of coin X to swap.
    ///  * `amount_y_min_out` - minimum amount of coin X will be received.
    ///  * `to` - address to receive coin X and coin Y.
    ///  * `deadline` - deadline of the transaction.
    public entry fun swap_exact_input<X, Y>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_y_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    ///  Swap exact coin `X` for coin `Z`.
    ///  * `container` - the container that holds all of AMM's liquidity pools.
    ///  * `vec_coin_x_in` - list of coins X offered for swap.
    ///  * `amount_x_desired` - desired amount of coin X to swap.
    ///  * `amount_z_min_out` - minimum amount coin Z will be received.
    ///  * `to` - address to receive coin Z.
    ///  * `deadline` - deadline of the transaction.
    public entry fun swap_exact_input_doublehop<X, Y, Z>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_z_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    ///  Swap exact coin `X` for coin `W`.
    ///  * `container` - the container that holds all of AMM's liquidity pools.
    ///  * `vec_coin_x_in` - list of coins X offered for swap.
    ///  * `amount_x_desired` - desired amount of coin X to swap.
    ///  * `amount_w_min_out` - minimum amount coin W will be received.
    ///  * `to` - address to receive coin W.
    ///  * `deadline` - deadline of the transaction.
    public entry fun swap_exact_input_triplehop<X, Y, Z, W>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_w_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    public fun swap_x_to_exact_y_direct<X, Y>(
        pair: &mut PairMetadata<X, Y>,
        coin_x_in: Coin<X>,
        amount_y_out: u64,
        ctx: &mut TxContext
    ): Coin<Y> {
        abort 0
    }

    public fun swap_y_to_exact_x_direct<X, Y>(
        pair: &mut PairMetadata<X, Y>,
        coin_y_in: Coin<Y>,
        amount_x_out: u64,
        ctx: &mut TxContext
    ): Coin<X> {
        abort 0
    }

    public fun swap_exact_output_direct<X, Y>(
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_y_out: u64,
        ctx: &mut TxContext
    ): Coin<Y> {
        abort 0
    }

    ///  Swap coin `X` for exact coin `Y`.
    ///  * `container` - the container that holds all of AMM's liquidity pools.
    ///  * `vec_coin_x_in` - list of coins X offered for swap.
    ///  * `amount_x_max` - maximum amount of coin X to swap.
    ///  * `amount_y_out` - exact amount coin X will be received.
    ///  * `to` - address to receive coin X.
    ///  * `deadline` - deadline of the transaction.
    public entry fun swap_exact_output<X, Y>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_x_max: u64,
        amount_y_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    ///  Swap coin `X` for exact coin `Z`.
    ///  * `container` - the container that holds all of AMM's liquidity pools.
    ///  * `vec_coin_x_in` - list of coins X offered for swap.
    ///  * `amount_x_max` - maximum amount of coin X to swap.
    ///  * `amount_z_out` - exact amount coin Z will be received.
    ///  * `to` - address to receive coin Z.
    ///  * `deadline` - deadline of the transaction.
    public entry fun swap_exact_output_doublehop<X, Y, Z>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_x_max: u64,
        amount_z_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    ///  Swap coin `X` for exact coin `W`.
    ///  * `container` - the container that holds all of AMM's liquidity pools.
    ///  * `vec_coin_x_in` - list of coins X offered for swap.
    ///  * `amount_x_max` - maximum amount of coin X to swap.
    ///  * `amount_w_out` - exact amount coin W will be received.
    ///  * `to` - address to receive coin W.
    ///  * `deadline` - deadline of the transaction.
    public entry fun swap_exact_output_triplehop<X, Y, Z, W>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_x_max: u64,
        amount_w_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    public entry fun swap_exact_input_double_output<X, Y, Z>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_x_to_y_desired: u64,
        amount_x_to_z_desired: u64,
        amount_y_min_out: u64,
        amount_z_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun swap_exact_input_triple_output<X, Y, Z, W>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_x_to_y_desired: u64,
        amount_x_to_z_desired: u64,
        amount_x_to_w_desired: u64,
        amount_y_min_out: u64,
        amount_z_min_out: u64,
        amount_w_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun swap_exact_input_quadruple_output<X, Y, Z, W, V>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_x_to_y_desired: u64,
        amount_x_to_z_desired: u64,
        amount_x_to_w_desired: u64,
        amount_x_to_v_desired: u64,
        amount_y_min_out: u64,
        amount_z_min_out: u64,
        amount_w_min_out: u64,
        amount_v_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun swap_exact_input_quintuple_output<X, Y, Z, W, V, U>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        amount_x_to_y_desired: u64,
        amount_x_to_z_desired: u64,
        amount_x_to_w_desired: u64,
        amount_x_to_v_desired: u64,
        amount_x_to_u_desired: u64,
        amount_y_min_out: u64,
        amount_z_min_out: u64,
        amount_w_min_out: u64,
        amount_v_min_out: u64,
        amount_u_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun swap_exact_double_input<X, Y, Z>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        coin_y_in: Coin<Y>,
        amount_z_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun swap_exact_triple_input<X, Y, Z, W>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        coin_y_in: Coin<Y>,
        coin_z_in: Coin<Z>,
        amount_w_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun swap_exact_quadruple_input<X, Y, Z, W, V>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        coin_y_in: Coin<Y>,
        coin_z_in: Coin<Z>,
        coin_w_in: Coin<W>,
        amount_v_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext,
    ) {
        abort 0
    }

    public entry fun swap_exact_quintuple_input<X, Y, Z, W, V, U>(
        clock: &Clock,
        container: &mut Container,
        coin_x_in: Coin<X>,
        coin_y_in: Coin<Y>,
        coin_z_in: Coin<Z>,
        coin_w_in: Coin<W>,
        coin_v_in: Coin<V>,
        amount_u_min_out: u64,
        to: address,
        deadline: u64,
        ctx: &mut TxContext,
    ) {
        abort 0
    }
}
