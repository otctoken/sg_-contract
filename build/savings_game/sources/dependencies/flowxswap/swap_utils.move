module flowxswap::swap_utils {
    use std::ascii;
    use std::type_name;
    use sui::coin::{Self, Coin};

    use flowxswap::comparator;

    const EQUAL: u8 = 0;
    const SMALLER: u8 = 1;
    const GREATER: u8 = 2;
    const FEE_PRECISION: u64 = 10000;

    const ERROR_INSUFFICIENT_INPUT_AMOUNT: u64 = 0;
    const ERROR_INSUFFICIENT_LIQUIDITY: u64 = 1;
    const ERROR_IDENTICAL_COIN: u64 = 2;
    const ERROR_EMPTY_ARRAY: u64 = 3;

    // FORMULA = (x * y) = k;
    // (x + dx)(y - dy) = k = xy;
    // dy = y - (x * y) / (x + dx)
    // dy = y * dx / (x + dx);
    public fun get_amount_out(
        amount_in: u64,
        reserve_in: u64,
        reserve_out: u64,
        fee_rate: u64
    ): u64 {
        abort 0
    }
    
    // FORMULA = (x * y) = k;
    // (x + dx)(y - dy) = k = xy;
    // dx = (x * y) / (y - dy) - x;
    // dx = (x * dy) / (y - dy);
    public fun get_amount_in(
        amount_out: u64,
        reserve_in: u64,
        reserve_out: u64,
        fee_rate: u64
    ): u64 {
        abort 0
    }

    public fun quote(amount_in: u64, reserve_in: u64, reserve_out: u64): u64 {
        abort 0
    }

    public fun is_ordered<X, Y>(): bool {
        abort 0
    }

    public fun left_amount<T>(c: &Coin<T>, amount_desired: u64): u64 {
        abort 0
    }
}
