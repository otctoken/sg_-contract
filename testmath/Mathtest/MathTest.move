module math::sgc {
    public struct Foo has key, store{
    id: UID,
    num:u64,
}
fun init(
        ctx: &mut TxContext
    ) {

        let adminAddr = Foo {
            id: object::new(ctx),
            num:0,
        };
        transfer::public_share_object(adminAddr);
    }
        public fun seq_value(n: u64, pos: u64): u64 {
        // assert_power_of_two(n);
        if (n == 1) {
            1
        } else {
            let m = n / 2; // n = 2m
            if (pos % 2 == 1) {
                // 奇数位：递归到上一层位置 (pos+1)/2
                seq_value(m, (pos + 1) / 2)
            } else {
                // 偶数位：直接映射到尾段
                m + (pos / 2)
            }
        }
    }


    public fun seq_pos(n: u64, val: u64): u64 {
        // assert_power_of_two(n);
        if (n == 1) {
            1
        } else {
            let m = n / 2; // n = 2m
            if (val > m) {
                2 * (val - m)
            } else {
                (2 * seq_pos(m, val)) - 1
            }
        }
    }


    public fun infer_prev_from_tail_single(total_len: u64, v: u64): u64 {
        // total_len 必须偶数 & 2^k
        // assert!(total_len % 2 == 0, E_TOTAL_LEN_MISMATCH);
        // assert_power_of_two(total_len);
        let n = total_len / 2;
        // 尾段索引（1..n）= v - n
        seq_value(n, v - n)
    }
    public entry fun lottery_num(fo:&mut Foo,rnum:u64,liebiao1:vector<u64>,tree_h:u64,quantity:u64){// 9[] //看图，初始 为内部节点边界quantity=9  树高 tree_h=4
        let mut i_n = 2;
        let mut rn = rnum;
        let mut i_n_lottery = 1;
        while(i_n < quantity){
            i_n_lottery = i_n;
            let inum = *vector::borrow(&liebiao1, i_n);
            if(rn > inum){
                rn = rn - inum;
                i_n = (i_n + 1) * 2;
                if(i_n >= 9){
                    i_n_lottery = i_n / 2;
                    if(i_n_lottery >= quantity){
                        let node_num = (i_n_lottery - 1) / 2 + 1;
                        fo.num = node_num;
                    }
                }
            }else{
                i_n = i_n * 2;
            }
        };
        if (i_n_lottery < quantity){
            let l_n_lottery_r = i_n_lottery + 1;
            let mut tree_u:u64 = 1 << (tree_h as u8);
            if(l_n_lottery_r <= tree_u / 2){
                let h = tree_h - 1;
                tree_u = 1 << (h as u8);
            };
            let l_n_lottery_l = infer_prev_from_tail_single(tree_u,l_n_lottery_r);
            let inum_ = 1;
            if(rn > inum_){
                fo.num = l_n_lottery_r;
            }else{
                fo.num = l_n_lottery_l;
            }
         }
    }
}
