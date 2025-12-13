// Copied from: https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/sources/math.move
// SPDX-License-Identifier: Apache-2.0

/// Basic math for nicer programmability
/// This module may be redundant in the future
module flowxswap::math {

    /// Return the larger of `x` and `y`
    public fun max(x: u64, y: u64): u64 {
       abort 0
    }

    /// Return the smaller of `x` and `y`
    public fun min(x: u64, y: u64): u64 {
        abort 0
    }
    
    /// Return the value of a base raised to a power
    public fun pow(base: u64, exponent: u8): u64 {    
        abort 0
    }

    /// Return the larger of `x` and `y`
    public fun max_u128(x: u128, y: u128): u128 {
        abort 0
    }

    /// Return the smaller of `x` and `y`
    public fun min_u128(x: u128, y: u128): u128 {
        abort 0
    }

    /// Get a nearest lower integer Square Root for `x`. Given that this
    /// function can only operate with integers, it is impossible
    /// to get perfect (or precise) integer square root for some numbers.
    ///
    /// Example:
    /// ```
    /// math::sqrt(9) => 3
    /// math::sqrt(8) => 2 // the nearest lower square root is 4;
    /// ```
    ///
    /// In integer math, one of the possible ways to get results with more
    /// precision is to use higher values or temporarily multiply the
    /// value by some bigger number. Ideally if this is a square of 10 or 100.
    ///
    /// Example:
    /// ```
    /// math::sqrt(8) => 2;
    /// math::sqrt(8 * 10000) => 282;
    /// // now we can use this value as if it was 2.82;
    /// // but to get the actual result, this value needs
    /// // to be divided by 100 (because sqrt(10000)).
    ///
    ///
    /// math::sqrt(8 * 1000000) => 2828; // same as above, 2828 / 1000 (2.828)
    /// ```
    public fun sqrt(x: u64): u64 {
        abort 0
    }

    /// Similar to math::sqrt, but for u128 numbers. Get a nearest lower integer Square Root for `x`. Given that this
    /// function can only operate with integers, it is impossible
    /// to get perfect (or precise) integer square root for some numbers.
    ///
    /// Example:
    /// ```
    /// math::sqrt_u128(9) => 3
    /// math::sqrt_u128(8) => 2 // the nearest lower square root is 4;
    /// ```
    ///
    /// In integer math, one of the possible ways to get results with more
    /// precision is to use higher values or temporarily multiply the
    /// value by some bigger number. Ideally if this is a square of 10 or 100.
    ///
    /// Example:
    /// ```
    /// math::sqrt_u128(8) => 2;
    /// math::sqrt_u128(8 * 10000) => 282;
    /// // now we can use this value as if it was 2.82;
    /// // but to get the actual result, this value needs
    /// // to be divided by 100 (because sqrt_u128(10000)).
    ///
    ///
    /// math::sqrt_u128(8 * 1000000) => 2828; // same as above, 2828 / 1000 (2.828)
    /// ```
    public fun sqrt_u128(x: u128): u128 {
        abort 0
    }
}
