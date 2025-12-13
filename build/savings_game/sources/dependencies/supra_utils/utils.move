module supra_utils::utils {
    use std::vector;

    /// Undefined expression
    const EUNDEFIND_EXP: u64 = 1;

    /// unstable append of second vector into first vector
    public fun destructive_reverse_append<Element: drop>(first: &mut vector<Element>, second: vector<Element>) {
        while(!vector::is_empty(&second)) {
            vector::push_back(first, vector::pop_back(&mut second));
        }
    }

    /// Flatten and concatenate the vectors
    public fun vector_flatten_concat<Element: copy + drop>(lhs: &mut vector<Element>, other: vector<vector<Element>>) {
        let i = 0;
        let length = vector::length(&other);
        while (i < length) {
            let bytes = vector::borrow(&other, i);
            vector::append(lhs, *bytes);
            i = i + 1;
        };
    }

    /// Calculates the power of a base raised to an exponent. The result of `base` raised to the power of `exponent`
    public fun calculate_power(base: u128, exponent: u16): u256 {
        let result: u256 = 1;
        let base: u256 = (base as u256);
        assert!((base | (exponent as u256)) != 0, EUNDEFIND_EXP);
        if (base == 0) { return 0 };
        while(exponent != 0) {
            if ((exponent & 0x1) == 1) { result = result * base; };
            base = base * base;
            exponent = (exponent >> 1);
        };
        result
    }

    #[test]
    fun test_calculate_power() {
        assert!(calculate_power(1,0) == 1, 0);
        assert!(calculate_power(0,1) == 0, 0);
        assert!(calculate_power(2,7) == 128, 0);
        assert!(calculate_power(2,8) == 256, 0);
        assert!(calculate_power(12, 0) == 1, 1);
        assert!(calculate_power(15, 3) == 3375, 2);
        assert!(calculate_power(10, 2) == 100, 3);
    }

    #[test]
    #[expected_failure( abort_code = EUNDEFIND_EXP, location = Self)]
    fun test_failure_undefined_exp() {
        assert!(calculate_power(0,0) == 0, 100);
    }

    #[test]
    fun test_base_with_big_number() {
        assert!(calculate_power(4294967295, 2) == 18446744065119617025, 101);
        assert!(calculate_power(4294967296, 2) == 18446744073709551616, 102);
        assert!(calculate_power(4294967296, 3) == 79228162514264337593543950336, 103);
        assert!(calculate_power(4294967297, 2) == 18446744082299486209, 104);
        assert!(calculate_power(4294967297, 3) == 79228162569604569827557507073, 105);
    }
}
