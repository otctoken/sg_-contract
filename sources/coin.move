module savings_game::sgc {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self};

    const TOTAL_SUPPLY_RAW: u64 = 100_000_000_000_000_000;
    const ADMIN_SUPPLY_RAW: u64 = 25_000_000_000_000_000;
    // One Time Witness
    public struct SGC has drop {}

    public struct Halving_cycle has key, store{
        id: UID,
        current:u64,
        remaining: u64, 
        halved:u64,
    }

    public struct AdminTotal has key, store {
        id: UID,
        total:u64,
        cycle:u64
    }

        /// 将 TreasuryCap<SGC> 私有封装在模块内，外部拿不到该字段
    public struct Minter has key, store {
        id: UID,
        cap: TreasuryCap<SGC>,
    }

    fun init(witness: SGC, ctx: &mut TxContext) {
        // TODO
        let decimals = 6;
        let symbol = b"SGC";
        let name = b"SavingsGameCoin";
        let description = b"Play the savings game and get Coin!";
        let icon_url = url::new_unsafe_from_bytes(b"https://ipfs.io/ipfs/bafkreie5pwb2rcn7fz6sf76ex7hnclrnoblhk3qz33ssrcr3zaer52o5eu");

        let (treasury, metadata) = coin::create_currency(witness, decimals, symbol, name, description, option::some(icon_url), ctx);
        let at = AdminTotal {
            id: object::new(ctx),
            total:ADMIN_SUPPLY_RAW,
            cycle:0,
        };
        let hc = Halving_cycle {
            id: object::new(ctx),
            current:TOTAL_SUPPLY_RAW,
            remaining: TOTAL_SUPPLY_RAW / 5, 
            halved:1,
        };
        transfer::public_freeze_object(metadata);
        // transfer::public_share_object(metadata);
                // 封装 TreasuryCap 到 Minter并共享 Minter
        let minter = Minter { id: object::new(ctx), cap: treasury };
        transfer::share_object(minter);
        transfer::public_share_object(hc);
        transfer::transfer(at, @0x82242fabebc3e6e331c3d5c6de3d34ff965671b75154ec1cb9e00aa437bbfa44);
    }

    public(package) fun mint(
        minter: &mut Minter,hc:&mut Halving_cycle, amount: u64,  ctx: &mut TxContext
    ) {
        let ts: u64 = coin::total_supply<SGC>(&mut minter.cap);
        halved(ts,hc);
        let amount_to = amount / hc.halved;
        if(ts < TOTAL_SUPPLY_RAW && amount_to > 0){
            coin::mint_and_transfer(&mut minter.cap, amount_to, ctx.sender(), ctx)
        }
    }

    public entry fun burn(c: Coin<SGC>) {
        transfer::public_transfer(c, @0x0);
    }

    public entry fun admin_mint(
        minter: &mut Minter, at:&mut AdminTotal,ctx: &mut TxContext
    ) {
        let epoch = ctx.epoch();
        if(epoch >= at.cycle){
            at.cycle = epoch +30;
            at.total = at.total - 1_000_000_000_000_000;
            coin::mint_and_transfer(&mut minter.cap,1_000_000_000_000_000, ctx.sender(), ctx)
        }
    }

    fun halved(total:u64,hc:&mut Halving_cycle){
        if(total >= hc.remaining){
            hc.halved = hc.halved * 2;
            hc.current = TOTAL_SUPPLY_RAW - hc.remaining;
            hc.remaining = hc.current / 5 + hc.remaining;
        }
    }
}
