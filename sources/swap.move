module savings_game::mini_swap{
    use sui::coin::Coin;
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use flowxswap::factory::{Self, Container};
    use flowxswap::router;

    entry fun entry_swap<X, Y>(
        pool: &mut Container,
        coin_x_in: Coin<X>,
        ctx: &mut TxContext
    ) {
        let coin_y_out = router::swap_exact_input_direct<X, Y>(pool, coin_x_in, ctx);
        transfer::public_transfer(coin_y_out, tx_context::sender(ctx));
    }

    public fun swap<X, Y>(
        pool: &mut Container,
        coin_x_in: Coin<X>,
        ctx: &mut TxContext
    ):Coin<Y>{
        router::swap_exact_input_direct<X, Y>(pool, coin_x_in, ctx)
    }

}