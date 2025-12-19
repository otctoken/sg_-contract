module savings_game::vault{

    use std::type_name::{Self, TypeName};
    use std::ascii::{String};

    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::clock::{Clock};
    use sui::table::{Self, Table};
    use sui::transfer::{Self};
    use sui::random::{Self,Random};
    use sui::bag::{Self, Bag};
    use sui::dynamic_field as DF;
    use sui::event::emit;

    use lending_core::account::{AccountCap};
    use lending_core::lending;
    use lending_core::incentive_v2::{Incentive as IncentiveV2};
    use lending_core::incentive_v3::{Self, Incentive, RewardFund,ClaimableReward};
    use lending_core::pool::{Pool};
    use lending_core::storage::{Storage};
    use lending_core::version;
    use lending_core::logic;

    use oracle::oracle::{PriceOracle};

    use sui_system::sui_system::{SuiSystemState};

    use flowxswap::factory::Container;

    use savings_game::sgc::{Self,SGC,Minter,Halving_cycle};
    use savings_game::mini_swap::{Self};
    
    const MINUTE:u64 = 60_000;
    const COINDS:u64 = 1_000_000;
    const TIMEDS:u64 = 1_000;

    const EFEE:u64 = 0;
    const E_POS_OOB: u64 = 1;              // pos 越界
    const E_VAL_OOB: u64 = 2;              // val 越界
    const E_TAIL_VAL_OOB: u64 = 3;         // 尾段 v 越界
    const E_PREV_VAL_OOB: u64 = 4;         // 上一层 v_prev 越界
    const E_ZERO_WEIGHT: u64 = 5;        // 存款不得小于1000000，否者无票权
    const E_TIME_NOT:u64 = 6;            //时间周期未到
    const E_INSUFFICIENT_PERMISSIONS:u64 = 7;            //时间周期未
    const E_TYPE_NOT:u64 = 8;            //时间周期未到
    const E_NO_SUCH_BAL:u64 = 9;
    const E_ZERO:u64 = 10;
    const ERRVERSION: u64 = 11;
    const REWARDFUNDERR:u64 = 12;
    const REWARDFUNDERROR:u64 = 13;
    const WEEKERR:u64 = 14;
    const MOONERR:u64 = 15;
    //合约升级必修改
    const VERSION: u64 = 1;


    public struct Node_Data has store , drop {
        balance_right: u64,
        change_time: u64,
        previous_value: u128
        // usdc_index: u8
    }

    public struct Get_sgc<phantom T> has key, store {
        id: UID,
        change_time:Table<address,u64>, 
        sgc_weight:u64
    }

    public struct SavingsData<phantom T> has key, store {
        id: UID,
        tree_height:u8,//二叉树高
        index: u8, //池子编号
        time_per_round:u64, //最小周期初定1天
        start_time:u64,  // 本轮开始时间
        start_time_day:u64,
        weighting_day:u64, 
        weighting_weekly:u64, 
        weighting_monthly:u64, 
        round_weekly:u64,
        round_monthly:u64,
        lottery_draw_weekly:bool,
        lottery_draw_monthly:bool,
        number_of_draws:u64,
        total_balance:u64,//总存款
        internal_node:u64,  //内部节点
        leaf_node:u64,  //叶子节点
        savings:Table<address,u64>,  //100秒 0.1sui 一票权   100USDC 100秒，总计存款
        adder_node:Table<address,u64>,  //用户映射的编号
        node_adder:Table<u64,address>, //抽奖后用于认定奖励人
        internal_node_data:Table<u64,Node_Data>, 
        leaf_node_data:Table<u64,Node_Data>,  
        null_node:vector<u64>,//用start_time时间映射  空节点列表，如果新的时间没有了
        //sgc_weight : u64,
        prize_pool_weekly:Bag,
        prize_pool_monthly:Bag,
        // rule_ids:Table<u8,vector<address>>, 
        account_cap: AccountCap, //结算凭证
        version : u64 //升级后修改
    }

    public struct AdminCap has key, store {
        id: UID
    }

    public struct AdminAddr_fee has key, store {
        id: UID,
        fee:u8,
        adder:address,
        version : u64 //升级后修改
    }

    public struct Outcome<phantom T> has copy,drop {
        win:u64,
        game_type:u64,
        adder:address,
        random:u128
    }
    //升级后必须调用
    entry fun upgrading_packages_migrate<T>(_: &AdminCap,s: &mut SavingsData<T>,af:&mut AdminAddr_fee) {
        s.version = VERSION;
        af.version = VERSION;
    }

    fun init(
        ctx: &mut TxContext
    ) {

        let adminAddr = AdminAddr_fee {
            id: object::new(ctx),
            fee:12,
            adder:@0x82242fabebc3e6e331c3d5c6de3d34ff965671b75154ec1cb9e00aa437bbfa44,
            version:1
        };
        transfer::public_share_object(adminAddr);
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, @0x82242fabebc3e6e331c3d5c6de3d34ff965671b75154ec1cb9e00aa437bbfa44);
    }

    public entry fun change_fee(_: &AdminCap,adminAddr:&mut AdminAddr_fee,fee:u8,ctx: &mut TxContext){
        assert!(fee >= 10,EFEE);
        adminAddr.fee = fee;
    }
    public entry fun change_adder(_: &AdminCap,adminAddr:&mut AdminAddr_fee,add:address,ctx: &mut TxContext){
        adminAddr.adder = add;
    }

    public entry fun change_round<T>(_: &AdminCap,savingsd: &mut SavingsData<T>,time_per_num:u64,
    weekly_num:u64,monthly_num:u64,ctx: &mut TxContext){
        savingsd.time_per_round = time_per_num;
        savingsd.round_weekly = weekly_num;
        savingsd.round_monthly = monthly_num;
    }
    public entry fun change_weighting<T>(_: &AdminCap,savingsd: &mut SavingsData<T>,w_d:u64,
    w_w:u64,w_m:u64,ctx: &mut TxContext){
        savingsd.weighting_day = w_d;
        savingsd.weighting_weekly = w_w;
        savingsd.weighting_monthly = w_m;
    }
    // 看小数点1 SUI 一天  在除以 8 640 000 = 10.000000sgc    六位的 如 deep 191700
    public entry fun initSavingsData<T>(_: &AdminCap,round:u64,index_: u8,sgc_weight:u64,clock: &Clock,ctx: &mut TxContext){
        let nd = Node_Data{
            balance_right: 0,
            change_time: 0,
            previous_value: 0
        };
        let mut sd = SavingsData<T> {
            id: object::new(ctx),
            tree_height:1,
            index: index_,
            time_per_round: round*MINUTE,
            start_time:clock.timestamp_ms(),
            start_time_day:clock.timestamp_ms(),
            weighting_day:50, 
            weighting_weekly:30, 
            weighting_monthly:20, 
            round_weekly:7,
            round_monthly:28,
            lottery_draw_weekly:false,
            lottery_draw_monthly:false,
            number_of_draws:0,
            total_balance:0,
            internal_node:1,
            leaf_node:2,
            savings:table::new(ctx),
            adder_node:table::new(ctx),
            node_adder:table::new(ctx),
            internal_node_data:table::new(ctx),
            leaf_node_data:table::new(ctx),
            null_node:vector::empty<u64>(),
            //sgc_weight:sgc_weight,
            prize_pool_weekly:bag::new(ctx),
            prize_pool_monthly:bag::new(ctx),
            // rule_ids:table::new(ctx), 
            account_cap: lending::create_account(ctx),
            version:1
        };
        table::add(&mut sd.adder_node, @0x0, 1);
        table::add(&mut sd.node_adder, 1, @0x0);
        table::add(&mut sd.leaf_node_data, 1, nd);
        transfer::public_share_object(sd);
        let  sg =  Get_sgc<T>{
            id: object::new(ctx),
            change_time:table::new(ctx), 
            sgc_weight:sgc_weight,
        };
        transfer::public_share_object(sg);
    }


    //需要有存款后执行这个函数
    public  fun get_rewards_type<T>(savingsd: &SavingsData<T>,storage: &mut Storage, incentive: &Incentive,clock: &Clock, ctx: &mut TxContext)
    : (vector<vector<String>>, vector<vector<address>>){
        // 1. 获取原始奖励列表
        let all_rewards = incentive_v3::get_user_claimable_rewards(clock, storage, incentive, savingsd.account_cap.account_owner());

        // 2. 使用模块提供的函数一次性解析所有数据
        // 这一步会把 ClaimableReward 结构体拆解成平行的 vectors
        let (
            mut asset_coin_types,   // vector<String>
            mut reward_coin_types,  // vector<String>
            mut user_claimable,     // vector<u256>
            mut user_claimed,       // vector<u256>
            mut all_rule_ids        // vector<vector<address>>
        ) = incentive_v3::parse_claimable_rewards(all_rewards);

        // 3. 准备结果容器 (注意要加 mut)

        // 注意：原代码逻辑如果是一个用户对应多个规则，result_rule_ids 可能需要是 vector<vector<address>> 或者你只需要其中一个

        // 4. 遍历解析后的数据
        // 因为 vector::pop_back 是从后往前取，所以这些 vector 的长度是同步变化的
        // 1. 创建第一个 Table
        let mut result_strings = vector::empty<vector<String>>();
        let mut result_addresses = vector::empty<vector<address>>();
        while (!vector::is_empty(&user_claimable)) {
            
            // 弹出当前这一条数据的信息
            let amount = vector::pop_back(&mut user_claimable);
            let asset_type = vector::pop_back(&mut asset_coin_types);
            let rule_ids = vector::pop_back(&mut all_rule_ids);
            
            // 弹出不需要的数据以保持 vector 同步并清理内存 (drop)
            let _ = vector::pop_back(&mut reward_coin_types);
            let _ = vector::pop_back(&mut user_claimed);

            // 5. 执行你的判断逻辑
            if (amount > 0) {
                let mut asset_coin_type = vector::empty<String>();
                vector::push_back(&mut asset_coin_type, asset_type);
                
                // 关于 rule_ids 的处理：
                // 原报错代码是: result_rule_ids = reward.rule_ids;
                // 这里的 rule_ids 是 vector<address> 类型。
                // 如果你的 result_rule_ids 是用来存所有符合条件的规则ID，你需要决定是覆盖还是合并。
                // 假设你是想拿到最后一条非零奖励的规则ID，或者你需要根据你的业务逻辑调整这里：
                vector::push_back(&mut result_strings, asset_coin_type);
                vector::push_back(&mut result_addresses, rule_ids);
            };
        };
        (result_strings, result_addresses)
    }

    
    public fun seq_value(n: u64, pos: u64): u64 {
        // assert_power_of_two(n);
        assert!(pos >= 1 && pos <= n, E_POS_OOB);
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
        assert!(val >= 1 && val <= n, E_VAL_OOB);
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
        assert!(v >= n + 1 && v <= total_len, E_TAIL_VAL_OOB);
        // 尾段索引（1..n）= v - n
        seq_value(n, v - n)
    }


    public fun tail_from_prev_single(total_len: u64, v_prev: u64): u64 {
        // assert!(total_len % 2 == 0, E_TOTAL_LEN_MISMATCH);
        // assert_power_of_two(total_len);
        let n = total_len / 2;
        assert!(v_prev >= 1 && v_prev <= n, E_PREV_VAL_OOB);
        let pos = seq_pos(n, v_prev);
        n + pos
    }


    fun get_parent_node(nn:u64,leaf_node:u64,tree_height:u8):u64{  //测试必须测试一下.................
        let mut tree_u:u64 = 1 << tree_height;
        if((leaf_node - 1) <= tree_u / 2){
            let h = tree_height - 1;
            tree_u = 1 << h;
        };
        loop {                                 // Move 同样支持 `loop`
            if (nn > tree_u / 2) {
                return nn - 1;                 // 直接返回找到的父
            };
            let right = tail_from_prev_single(tree_u, nn);
            if (right < leaf_node) {
                return right - 1;              // 也是找到父
            };
            tree_u = tree_u / 2;           
        }
    }

    //let u:u64 = 1 << n;
    //数学@......................................……………………..............................................

        /// 统一生成“键”：ascii::String（和 type_name 完全一致）
    fun key_of<A>(): String {
        type_name::into_string(type_name::get<A>())
    }
    //金库存取
    /// 存入任意币种手续费：把 Coin<A> 合并进 Bag 里的 `Balance<A>`
    public entry fun deposit_fee<A>(
        vault: &mut AdminAddr_fee,
        coin_in: Coin<A>,
        _ctx: &mut TxContext,
    ) {
        let bal_in: Balance<A> = coin::into_balance(coin_in);
        let k0: String = key_of<A>();
        if (DF::exists_with_type<String, Balance<A>>(&vault.id, k0)) {
            let bal_ref: &mut Balance<A> =
                DF::borrow_mut<String, Balance<A>>(&mut vault.id, k0);
            balance::join(bal_ref, bal_in);
        } else {
            DF::add<String, Balance<A>>(&mut vault.id, k0, bal_in);
        }
    }


/// 必须有余额才取：没有则用自定义错误码中止（不再触发 DF 的 EFieldDoesNotExist=1）
    fun withdraw_burning_sgc<A>(
        vault: &mut AdminAddr_fee,
        ctx: &mut TxContext,
    ): Coin<A> {
        let k0: String = key_of<A>();
        assert!(DF::exists_with_type<String, Balance<A>>(&vault.id, k0), E_NO_SUCH_BAL);
        let bal: Balance<A> = DF::remove<String, Balance<A>>(&mut vault.id, k0);
        let c = coin::from_balance(bal, ctx);
        assert!(coin::value(&c) > 0, E_ZERO);
        c
    }


    //..................................................................................
    fun calculate_node_weight(nodes_data:&Node_Data,time_:u64,start_time:u64):u128{
        if (start_time >= nodes_data.change_time * TIMEDS) {
            ((time_ - (start_time / TIMEDS)) * nodes_data.balance_right as u128)
        } else {
            ((time_ - nodes_data.change_time) * nodes_data.balance_right as u128) + nodes_data.previous_value
        }
    }
    fun remove_by_value(nums: &mut vector<u64>, target: u64){
        let (found, i) = vector::index_of(nums, &target);
        if (found) {
            vector::swap_remove(nums, i);
        };
    }
    //循环修改父节点....
    fun modify_parent_node<A>(time_:u64,the_node:u64,savingsd: &mut SavingsData<A>,coinv:u64,add_sub:bool,p_v:u128){
        let mut node_ = the_node;
        while (node_ > 0) {
            let internal_nodes_data = table::borrow_mut(&mut savingsd.internal_node_data, node_);
            internal_nodes_data.previous_value = calculate_node_weight(internal_nodes_data,time_,savingsd.start_time);
            internal_nodes_data.change_time = time_;
            if(add_sub){
                internal_nodes_data.balance_right = internal_nodes_data.balance_right + coinv;
            }else{
                internal_nodes_data.balance_right = internal_nodes_data.balance_right - coinv;
                internal_nodes_data.previous_value = internal_nodes_data.previous_value - p_v;
            };
            node_ = node_ / 2;
        };
    }

 

    fun add_new_node<A>(savingsd: &mut SavingsData<A>,coin_v:u64,clock: &Clock,send:address){//增加空节点怎么弄？
        //增加空节点怎么弄？
        //if(savingsd.null_node.time<开始时间 && ...)
        table::add(&mut savingsd.adder_node, send, savingsd.leaf_node);
        table::add(&mut savingsd.node_adder, savingsd.leaf_node, send);
        let coinv_ = coin_v / COINDS;
        let time_ = clock.timestamp_ms() / TIMEDS;
        let nd = Node_Data{
            balance_right: coinv_,
            change_time: time_,
            previous_value: 0
        };
        table::add(&mut savingsd.leaf_node_data,savingsd.leaf_node, nd);
        let tree_u:u64 = 1 << savingsd.tree_height;
        let merge_nodes = infer_prev_from_tail_single(tree_u , savingsd.leaf_node);
        let merge_nodes_data = table::borrow(&savingsd.leaf_node_data, merge_nodes);
        let id_b_r = coinv_ + merge_nodes_data.balance_right;
        let p_v = calculate_node_weight(merge_nodes_data,time_,savingsd.start_time);
        let id = Node_Data{
            balance_right: id_b_r,
            change_time: time_,
            previous_value: p_v
        };
        table::add(&mut savingsd.internal_node_data,savingsd.internal_node, id);
        let node_nn = savingsd.internal_node / 2;
        modify_parent_node(time_,node_nn,savingsd,coinv_,true,0);
        //执行
        savingsd.leaf_node = savingsd.leaf_node + 1;
        savingsd.internal_node = savingsd.internal_node + 1;
        if(savingsd.leaf_node > tree_u){
            savingsd.tree_height = savingsd.tree_height + 1;
        } 
    }
    
    fun modify_node_nodes<A>(node_n:u64,savingsd: &mut SavingsData<A>,coin_v:u64,clock: &Clock,send:address){   //修改我的节点 增加存款或再次加入
        let coinv_ = coin_v / COINDS;
        let time_ = clock.timestamp_ms() / TIMEDS;
        let data_ = table::borrow_mut(&mut savingsd.leaf_node_data,node_n); 
        let p_v = calculate_node_weight(data_,time_,savingsd.start_time);
        data_.previous_value = p_v;
        data_.change_time = time_;
        data_.balance_right = data_.balance_right + coinv_;
        let parent_node = get_parent_node(node_n,savingsd.leaf_node,savingsd.tree_height);
        modify_parent_node<A>(time_,parent_node,savingsd,coinv_,true,0)
    }

    fun use_null_nodes<A>(savingsd: &mut SavingsData<A>,coin_v:u64,clock: &Clock,send:address){   //使用空节点
        let null_n = vector::pop_back(&mut savingsd.null_node);
        let adder_ = table::borrow_mut(&mut savingsd.node_adder, null_n);
        let savings_ = table::remove(&mut savingsd.savings, *adder_);
        let node_ = table::remove(&mut savingsd.adder_node, *adder_);
        *adder_ = send;
        table::add(&mut savingsd.adder_node, send, null_n);
        let coinv_ = coin_v / COINDS;
        let time_ = clock.timestamp_ms() / TIMEDS;
        let node_d_  = table::borrow_mut(&mut savingsd.leaf_node_data, null_n);
        node_d_.balance_right = coinv_;
        node_d_.change_time = time_;
        node_d_.previous_value = 0;

        let parent_node = get_parent_node(null_n,savingsd.leaf_node,savingsd.tree_height);
        modify_parent_node<A>(time_,parent_node,savingsd,coinv_,true,0);
    }

    public entry fun deposit<A> (
        savingsd: &mut SavingsData<A>,
        deposit_coin: Coin<A>,
        storage: &mut Storage,
        pool_a: &mut Pool<A>,
        inc_v1: &mut IncentiveV2,
        inc_v2: &mut Incentive,
        minter:&mut Minter,
        hc:&mut Halving_cycle,
        g_s:&mut Get_sgc<A>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(savingsd.version == VERSION, ERRVERSION);
        let coin_value = deposit_coin.value();
        assert!(coin_value >= COINDS, E_ZERO_WEIGHT);
        get_sgc_coin(minter,hc,savingsd,g_s,false,clock,ctx);
        savingsd.total_balance = savingsd.total_balance + coin_value;
        // 检查地址是否在Table中
        if (savingsd.savings.contains(ctx.sender())) { //取款后下一个用这个节点的需要删除33333333333333333333333333333
            // 存在：获取当前值并加1
            let current_count = table::borrow(&savingsd.savings,ctx.sender()); //下一个 取款必须加入空列表
            if(*current_count == 0){
                    //是否有空节点可用    
                if(vector::length(&savingsd.null_node) > 0){
                    use_null_nodes(savingsd,coin_value,clock,ctx.sender())
                }else{
                        //按照新增节点
                    add_new_node(savingsd,coin_value,clock,ctx.sender())
                };
            }else{
                //修改节点数据
                let node_ = table::borrow(&savingsd.adder_node,ctx.sender());
                modify_node_nodes(*node_,savingsd,coin_value,clock,ctx.sender())
            };
            let current_count_ = table::borrow_mut(&mut savingsd.savings,ctx.sender());
            *current_count_ = *current_count_ + coin_value;   //来一个返回左右 与树高，所在层级
        } else {
            //是否有空节点可用  切记最后必须 remove_by_value(&mut savingsd.null_node, *node_);
            if(vector::length(&savingsd.null_node) > 0){
                use_null_nodes(savingsd,coin_value,clock,ctx.sender())
            }else{
            // 新增节点..
                table::add(&mut savingsd.savings, ctx.sender(), coin_value);  
                add_new_node(savingsd,coin_value,clock,ctx.sender())
            }
        };
        lending_core::incentive_v3::deposit_with_account_cap(clock, storage, pool_a, savingsd.index, deposit_coin, inc_v1, inc_v2, &savingsd.account_cap);
    }

    public entry fun withdraw<A> (
        savingsd: &mut SavingsData<A>,
        storage: &mut Storage,
        pool_a: &mut Pool<A>,
        inc_v1: &mut IncentiveV2,
        inc_v2: &mut Incentive,
        oracle: &PriceOracle,
        minter:&mut Minter,
        hc:&mut Halving_cycle,
        g_s:&mut Get_sgc<A>,
        clock: &Clock,
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext
    ){
        assert!(savingsd.version == VERSION, ERRVERSION);
        let balance_d = table::borrow(&mut savingsd.savings,ctx.sender());
        assert!(*balance_d > 0, E_ZERO_WEIGHT);
        get_sgc_coin(minter,hc,savingsd,g_s,true,clock,ctx);
        let coinv_ = *balance_d / COINDS;
        savingsd.total_balance = savingsd.total_balance - *balance_d;
        let withdrawn_balance = lending_core::incentive_v3::withdraw_with_account_cap_v2(clock, oracle, storage, pool_a,savingsd.index, *balance_d, inc_v1, inc_v2,
        &savingsd.account_cap,system_state,ctx);
        let coin_ = coin::from_balance(withdrawn_balance, ctx);
        transfer::public_transfer(coin_,ctx.sender());
        let node_  = table::borrow(&savingsd.adder_node,ctx.sender());
        savingsd.null_node.push_back(*node_); //找到是左叶还是又叶 下面开始修改节点内容  使用空节点时候查询节点有没有秒均余额，或秒均是否过期  2循环修改父节点
        let time_ = clock.timestamp_ms() / TIMEDS;
        let data_ = table::borrow_mut(&mut savingsd.leaf_node_data,*node_); 
        let p_v = calculate_node_weight(data_,time_,savingsd.start_time);
        data_.balance_right = 0;
        data_.change_time = 0;
        data_.previous_value = 0;
        let parent_node = get_parent_node(*node_,savingsd.leaf_node,savingsd.tree_height);
        modify_parent_node(time_,parent_node,savingsd,coinv_,false,p_v);
        let balance_  = table::borrow_mut(&mut savingsd.savings,ctx.sender());
        *balance_ = 0;  
    }

    fun withdr_<A> (
        sui_withdraw_amount: u64,
        savingsd: &mut SavingsData<A>,
        storage: &mut Storage,
        pool_a: &mut Pool<A>,
        inc_v1: &mut IncentiveV2,
        inc_v2: &mut Incentive,
        clock: &Clock,
        oracle: &PriceOracle, 
        system_state: &mut SuiSystemState,
        ctx: &mut TxContext
    ): Coin<A> {
        let withdrawn_balance = lending_core::incentive_v3::withdraw_with_account_cap_v2(clock, oracle, storage, pool_a,savingsd.index, sui_withdraw_amount,inc_v1, inc_v2,&savingsd.account_cap,system_state,ctx);
        coin::from_balance(withdrawn_balance, ctx)
    }    

    public fun lottery_num<A>(rnum:u128,savingsd: &SavingsData<A>, clock: &Clock):u64{
        let mut i_n = 2;
        let mut rn = rnum;
        let time_ = clock.timestamp_ms() / TIMEDS;
        let mut i_n_lottery = 1;
        while(i_n < savingsd.internal_node){
            i_n_lottery = i_n;
            let data_ = table::borrow(&savingsd.internal_node_data,i_n); 
            let inum = calculate_node_weight(data_,time_,savingsd.start_time);
            if(rn > inum){
                rn = rn - inum;
                i_n = (i_n + 1) * 2;
                if(i_n >= savingsd.internal_node){
                    i_n_lottery = i_n / 2;
                    if(i_n_lottery >= savingsd.internal_node){
                        let node_num = (i_n_lottery - 1) / 2 + 1;
                        return node_num
                    }
                }
            }else{
                i_n = i_n * 2;
            }
        };
        let l_n_lottery_r = i_n_lottery + 1;
        let mut tree_u:u64 = 1 << savingsd.tree_height;
        if(l_n_lottery_r <= tree_u / 2){
            let h = savingsd.tree_height - 1;
            tree_u = 1 << h;
        };
        let l_n_lottery_l = infer_prev_from_tail_single(tree_u,l_n_lottery_r);
        let data_l = table::borrow(&savingsd.leaf_node_data,l_n_lottery_l); 
        let inum_ = calculate_node_weight(data_l,time_,savingsd.start_time);
        if(rn > inum_){
            l_n_lottery_r
        }else{
            l_n_lottery_l
        }
    }
    public fun gas_consume(num:u64){
        let mut i: u64 = 0;
        let mut y: u64 = 0;
        while (i < num) {
            y = y + num;
            i = i + 1;
        }
    }
    entry fun lottery<T,D,A>(a_f:&mut AdminAddr_fee,reward_fund_t: &mut RewardFund<T>,reward_fund_d: &mut RewardFund<D>,oracle: &PriceOracle,inc_v2: &mut Incentive,inc_v1: &mut IncentiveV2,storage: &mut Storage,pool_a: &mut Pool<A>,savingsd: &mut SavingsData<A>,r : &Random,clock: &Clock,system_state: &mut SuiSystemState,ctx: &mut TxContext){ //抽奖
        assert!(clock.timestamp_ms() > savingsd.start_time_day + savingsd.time_per_round, E_TIME_NOT);
        assert!(savingsd.version == VERSION, ERRVERSION);
        savingsd.number_of_draws = savingsd.number_of_draws + 1;
        let time_ = clock.timestamp_ms() / TIMEDS;
        let data_i = table::borrow(&savingsd.internal_node_data,1); 
        let rmax = calculate_node_weight(data_i,time_,savingsd.start_time);
        let mut rg = random::new_generator(r, ctx);
        let ra_gas =  random::generate_u64_in_range(&mut rg, 1, 20);
        gas_consume(ra_gas);
        let random_num =  random::generate_u128_in_range(&mut rg, 1, rmax);
        let win_r_num = lottery_num(random_num,savingsd,clock);
        let win_adder = *table::borrow(&savingsd.node_adder,win_r_num); 
        let amount = info(savingsd, pool_a, storage); //这里INDEX重点测试会不会报错...否则将会清零
        let lottery_amount = amount - savingsd.total_balance;
        let mut win_coin = withdr_(lottery_amount,savingsd,storage,pool_a,inc_v1,inc_v2,clock,oracle,system_state,ctx);
        let win_coin_vol = win_coin.value();
        let fee_amount = win_coin_vol / (a_f.fee as u64);
        let win_coin_percent_1 =  (win_coin_vol - fee_amount) / 100;
        let weekly_prize = win_coin_percent_1 * savingsd.weighting_weekly;
        let monthly_prize = win_coin_percent_1 * savingsd.weighting_monthly;
        let fee_coin = coin::split(&mut win_coin,fee_amount,ctx);
        let weekly_coin = coin::split(&mut win_coin,weekly_prize,ctx);
        let monthly_coin = coin::split(&mut win_coin,monthly_prize,ctx);
        transfer::public_transfer(win_coin,win_adder);
        add_coin_to_bag(&mut savingsd.prize_pool_weekly,weekly_coin);
        add_coin_to_bag(&mut savingsd.prize_pool_monthly,monthly_coin);
        deposit_fee(a_f,fee_coin,ctx);
        //transfer::public_transfer(fee_coin,a_f.adder);
        // 设置一个空对象来匹配奖励类型，可以删除、新建，由管理员或存款超过20%的人
        claim_reward_all(a_f,reward_fund_t,reward_fund_d,inc_v2,storage,savingsd,clock,win_adder,ctx);
        //最后
        if(savingsd.number_of_draws % savingsd.round_weekly == 0){
            if(!savingsd.lottery_draw_weekly){
                savingsd.lottery_draw_weekly = true;
            }
        };
        if(savingsd.number_of_draws % savingsd.round_monthly == 0){
            if(!savingsd.lottery_draw_monthly){
                savingsd.lottery_draw_monthly = true;
            }
        };
        savingsd.start_time_day = clock.timestamp_ms();
        emit(Outcome<A>{
            win:lottery_amount,
            game_type:1,
            adder:win_adder,
            random:random_num
        });
    }

    fun claim_reward_all<T,D,A>(
        a_f:&mut AdminAddr_fee,
        reward_fund_t: &mut RewardFund<T>,
        reward_fund_d: &mut RewardFund<D>,
        inc_v2: &mut Incentive,
        storage: &mut Storage,
        savingsd: &mut SavingsData<A>,
        clock: &Clock,
        win_adder:address,
        ctx: &mut TxContext
    ){
        let (tablestring, tableaddress) = get_rewards_type(savingsd, storage, inc_v2, clock, ctx);
        let count = vector::length(&tablestring);
        if(count > 0){
            let vec_string = *vector::borrow(&tablestring, 0);
            let vec_address = *vector::borrow(&tableaddress, 0);
            let mut reward_coin = claim_reward(savingsd,vec_string,vec_address,inc_v2,storage,reward_fund_t,clock,ctx); 
            assert!(reward_coin.value() > 0, REWARDFUNDERR);
            let reward_coin_vol = reward_coin.value();
            let fee_r_amount = reward_coin_vol / (a_f.fee as u64);
            let reward_coin_percent_1 =  (reward_coin_vol - fee_r_amount) / 100;
            let weekly_prize = reward_coin_percent_1 * savingsd.weighting_weekly;
            let monthly_prize = reward_coin_percent_1 * savingsd.weighting_monthly;
            let weekly_coin = coin::split(&mut reward_coin,weekly_prize,ctx);
            let monthly_coin = coin::split(&mut reward_coin,monthly_prize,ctx);
            let fee_r_coin = coin::split(&mut reward_coin,fee_r_amount,ctx);
            transfer::public_transfer(reward_coin,win_adder);
            add_coin_to_bag(&mut savingsd.prize_pool_weekly,weekly_coin);
            add_coin_to_bag(&mut savingsd.prize_pool_monthly,monthly_coin);
            deposit_fee(a_f,fee_r_coin,ctx);
                //transfer::public_transfer(fee_r_coin,a_f.adder);
            emit(Outcome<T>{
                win:reward_coin_vol,
                game_type:0,
                adder:win_adder,
                random:0
            });
           
            if(count > 1){
                let vec_string_2 = *vector::borrow(&tablestring, 1);
                let vec_address_2 = *vector::borrow(&tableaddress, 1);
                let mut reward_coin = claim_reward(savingsd,vec_string_2,vec_address_2,inc_v2,storage,reward_fund_d,clock,ctx); 
                assert!(reward_coin.value() > 0, REWARDFUNDERROR);
                let reward_coin_vol = reward_coin.value();
                let fee_r_amount = reward_coin_vol / (a_f.fee as u64);
                let reward_coin_percent_1 =  (reward_coin_vol - fee_r_amount) / 100;
                let weekly_prize = reward_coin_percent_1 * savingsd.weighting_weekly;
                let monthly_prize = reward_coin_percent_1 * savingsd.weighting_monthly;
                let weekly_coin = coin::split(&mut reward_coin,weekly_prize,ctx);
                let monthly_coin = coin::split(&mut reward_coin,monthly_prize,ctx);
                let fee_r_coin = coin::split(&mut reward_coin,fee_r_amount,ctx);
                transfer::public_transfer(reward_coin,win_adder);
                add_coin_to_bag(&mut savingsd.prize_pool_weekly,weekly_coin);
                add_coin_to_bag(&mut savingsd.prize_pool_monthly,monthly_coin);
                deposit_fee(a_f,fee_r_coin,ctx);
                    //transfer::public_transfer(fee_r_coin,a_f.adder);
                emit(Outcome<D>{
                    win:reward_coin_vol,
                    game_type:0,
                    adder:win_adder,
                    random:0
                });
            };
        };
    }


    fun claim_reward<RewardCoinType,A>(
        savingsd: &mut SavingsData<A>,
        coin_types: vector<String>,
        rule_ids: vector<address>,
        incentive: &mut Incentive,
        storage: &mut Storage,
        reward_fund: &mut RewardFund<RewardCoinType>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<RewardCoinType>{
        // ① 调用底层函数，拿到 Balance<RewardCoinType>
        let bal = lending_core::incentive_v3::claim_reward_with_account_cap<RewardCoinType>(
            clock,
            incentive,
            storage,
            reward_fund,
            coin_types,
            rule_ids,
            &savingsd.account_cap
        );
        // ② 把 Balance 铸造成真正的 Coin 对象并返回
        coin::from_balance(bal, ctx)
    }

    /// 通用工具：将任意类型的 Coin 存入指定的 Bag 中 (自动累加)
    fun add_coin_to_bag<CoinType>(
        bag: &mut Bag, 
        coin_in: Coin<CoinType>
    ) {
        let bal_in = coin::into_balance(coin_in);
        // 使用 TypeName 作为 Key，保证每种代币唯一
        let key = key_of<CoinType>();

        // 逻辑与你提供的一模一样：有则累加(join)，无则添加(add)
        if (bag::contains(bag, key)) {
            let bal_ref = bag::borrow_mut<String, Balance<CoinType>>(bag, key);
            balance::join(bal_ref, bal_in);
        } else {
            bag::add(bag, key, bal_in);
        };
    }

    fun take_all_from_bag<CoinType>(
        bag: &mut Bag,
        ctx: &mut TxContext
    ): Coin<CoinType> {
        // 1. 同样先生成 String Key
        let key: String = type_name::into_string(type_name::get<CoinType>());
        
        // 2. 用 String 去 Bag 里找
        if (bag::contains(bag, key)) {
            // 移除时，Key 的类型也是 String
            let bal = bag::remove<String, Balance<CoinType>>(bag, key);
            coin::from_balance(bal, ctx)
        } else {
            coin::zero<CoinType>(ctx)
        }
    }

    entry fun lottery_weekly<T,D,A>(savingsd: &mut SavingsData<A>,r : &Random,clock: &Clock,ctx: &mut TxContext){ //抽奖
        assert!(savingsd.version == VERSION, ERRVERSION);
        assert!(savingsd.lottery_draw_weekly, E_TIME_NOT);
        let time_ = clock.timestamp_ms() / TIMEDS;
        let data_i = table::borrow(&savingsd.internal_node_data,1); 
        let rmax = calculate_node_weight(data_i,time_,savingsd.start_time);
        let mut rg = random::new_generator(r, ctx);
        let ra_gas =  random::generate_u64_in_range(&mut rg, 1, 20);
        gas_consume(ra_gas);
        let random_num =  random::generate_u128_in_range(&mut rg, 1, rmax);
        let win_r_num = lottery_num(random_num,savingsd,clock);
        let win_adder = *table::borrow(&savingsd.node_adder,win_r_num);
        let count = bag::length(&savingsd.prize_pool_weekly);
        let coin_vol_A = take_all_from_bag<A>(&mut savingsd.prize_pool_weekly,ctx);
        if(coin_vol_A.value()>0){
            transfer::public_transfer(coin_vol_A,win_adder);
        }else{
            coin::destroy_zero(coin_vol_A);
        };
        if(count > 1){
            let coin_vol_T = take_all_from_bag<T>(&mut savingsd.prize_pool_weekly,ctx);
            if(coin_vol_T.value()>0){
                transfer::public_transfer(coin_vol_T,win_adder);
            }else{
                coin::destroy_zero(coin_vol_T);
            };
            if(count > 2){
                let coin_vol_D = take_all_from_bag<D>(&mut savingsd.prize_pool_weekly,ctx);
                if(coin_vol_D.value()>0){
                    transfer::public_transfer(coin_vol_D,win_adder);
                }else{
                    coin::destroy_zero(coin_vol_D);
                };
            }
        };
        let count_ = bag::length(&savingsd.prize_pool_weekly);
        assert!(count_ == 0, WEEKERR);

        //最后
        savingsd.lottery_draw_weekly = false;
        emit(Outcome<A>{
            win:0,
            game_type:7,
            adder:win_adder,
            random:random_num
        });
    }
    entry fun lottery_monthly<T,D,A>(savingsd: &mut SavingsData<A>,r : &Random,clock: &Clock,ctx: &mut TxContext){ //抽奖
        assert!(savingsd.version == VERSION, ERRVERSION);
        assert!(savingsd.lottery_draw_monthly, E_TIME_NOT);
        let time_ = clock.timestamp_ms() / TIMEDS;
        let data_i = table::borrow(&savingsd.internal_node_data,1); 
        let rmax = calculate_node_weight(data_i,time_,savingsd.start_time);
        let mut rg = random::new_generator(r, ctx);
        let ra_gas =  random::generate_u64_in_range(&mut rg, 1, 20);
        gas_consume(ra_gas);
        let random_num =  random::generate_u128_in_range(&mut rg, 1, rmax);
        let win_r_num = lottery_num(random_num,savingsd,clock);
        let win_adder = *table::borrow(&savingsd.node_adder,win_r_num); 
        let count = bag::length(&savingsd.prize_pool_monthly);
        let coin_vol_A = take_all_from_bag<A>(&mut savingsd.prize_pool_monthly,ctx);
        if(coin_vol_A.value()>0){
            transfer::public_transfer(coin_vol_A,win_adder);
        }else{
            coin::destroy_zero(coin_vol_A);
        };
        if(count > 1){
            let coin_vol_T = take_all_from_bag<T>(&mut savingsd.prize_pool_monthly,ctx);
            if(coin_vol_T.value()>0){
                transfer::public_transfer(coin_vol_T,win_adder);
            }else{
                coin::destroy_zero(coin_vol_T);
            };
            if(count > 2){
                let coin_vol_D = take_all_from_bag<D>(&mut savingsd.prize_pool_monthly,ctx);
                if(coin_vol_D.value()>0){
                    transfer::public_transfer(coin_vol_D,win_adder);
                }else{
                    coin::destroy_zero(coin_vol_D);
                };
            }
        };
        let count_ = bag::length(&savingsd.prize_pool_monthly);
        assert!(count_ == 0, MOONERR);
        //最后
        savingsd.lottery_draw_monthly = false;
        savingsd.start_time = clock.timestamp_ms();
        emit(Outcome<A>{
            win:0,
            game_type:30,
            adder:win_adder,
            random:random_num
        });
    }

    //必须放在取款前-----在添加一个node 余额变动就会修改 清零后删除 Get_sgc只能在添加node？余额  两样 存入 时间 可以代替取币时间 存入时间 通用  余额除去1000 000  时间按秒
    fun get_sgc_coin<A>(minter:&mut Minter,hc:&mut Halving_cycle,savingsd: &SavingsData<A>,g_s:&mut Get_sgc<A>,withdraw_bl:bool,clock: &Clock,ctx: &mut TxContext){
        let time_ = clock.timestamp_ms() / TIMEDS;
        //取款
        if(withdraw_bl){
            let snd_savings = *table::borrow(&savingsd.savings,ctx.sender());
            let get_time = time_ - *table::borrow(&g_s.change_time,ctx.sender());
            let sgc_amout = snd_savings * get_time / g_s.sgc_weight;
            sgc::mint(minter,hc, sgc_amout,ctx);
            let node_ = table::remove(&mut g_s.change_time,ctx.sender());
        }else{
            if(savingsd.savings.contains(ctx.sender())){
                let current_count = table::borrow(&savingsd.savings,ctx.sender()); //下一个 取款必须加入空列表
                if(*current_count == 0){
                    table::add(&mut g_s.change_time, ctx.sender(), time_);
                }else{
                    let snd_savings = *table::borrow(&savingsd.savings,ctx.sender());
                    let get_time = time_ - *table::borrow(&g_s.change_time,ctx.sender());
                    let sgc_amout = snd_savings * get_time / g_s.sgc_weight;
                    sgc::mint(minter,hc, sgc_amout,ctx);
                    let change_get_time = table::borrow_mut(&mut g_s.change_time,ctx.sender());
                    *change_get_time = time_;
                }
            }else{
                table::add(&mut g_s.change_time, ctx.sender(), time_);
            }
        }
    }

    public entry fun entry_get_sgc_coin<A>(minter:&mut Minter,hc:&mut Halving_cycle,savingsd: &SavingsData<A>,g_s:&mut Get_sgc<A>,clock: &Clock,ctx: &mut TxContext){
        assert!(savingsd.version == VERSION, ERRVERSION);
        let time_ = clock.timestamp_ms() / TIMEDS;
        let snd_savings = *table::borrow(&savingsd.savings,ctx.sender());
        let get_time = time_ - *table::borrow(&g_s.change_time,ctx.sender());
        let sgc_amout = snd_savings * get_time / g_s.sgc_weight;
        sgc::mint(minter,hc, sgc_amout,ctx);
        let change_get_time = table::borrow_mut(&mut g_s.change_time,ctx.sender());
        *change_get_time = time_;
    }

    entry fun burn_sgc_sui(minter: &mut Minter,a_f: &mut AdminAddr_fee,cont: &mut Container,ctx: &mut TxContext){
            assert!(a_f.version == VERSION, ERRVERSION);
            let coin = withdraw_burning_sgc<SUI>(a_f,ctx);
            let coin_value = coin.value();
            assert!(coin_value > 0, E_ZERO_WEIGHT);
            let coin_sgc = mini_swap::swap<SUI,SGC>(cont,coin,ctx);
            sgc::burn(minter,coin_sgc);
    }

    entry fun burn_sgc<T>(minter: &mut Minter,a_f: &mut AdminAddr_fee,cont: &mut Container,ctx: &mut TxContext){
            assert!(a_f.version == VERSION, ERRVERSION);
            let coin = withdraw_burning_sgc<T>(a_f,ctx);
            let coin_value = coin.value();
            assert!(coin_value > 0, E_ZERO_WEIGHT);
            let coin_sui = mini_swap::swap<T,SUI>(cont,coin,ctx);
            let coin_sgc = mini_swap::swap<SUI,SGC>(cont,coin_sui,ctx);
            sgc::burn(minter,coin_sgc);
    }


    public entry fun info<A>(savings: &SavingsData<A>, pool_a: &Pool<A>, storage: &mut Storage): u64 {
        let deposited_balance = logic::user_collateral_balance(storage,savings.index, savings.account_cap.account_owner());
        pool_a.unnormal_amount(deposited_balance as u64)
    }
}