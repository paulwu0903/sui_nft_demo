module advanced_nft:: rich_cat{

    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self ,Clock,};
    use sui::package::{Self};
    use sui::sui::SUI;
    use std::string::{Self,String};
    use sui::display::{Self,Display};
    use sui::coin::{Self, Coin,};

    const VERSION: u64 = 0;
    const TOTAL_SUPPLY: u64 = 1000;
    

    const EVersionError: u64 = 0;
    const EBalanceNotEnough: u64 = 1;
    const ETimeError: u64 = 2;
    const EBlindBoxAlreadyOpened: u64 = 3;

    //OTW
    struct RICH_CAT has drop{} 

    struct GlobalConfig has key {
        id: UID, 
        version: u64,
        sale_amount: u64,
        total_supply: u64,
        is_open_blind_box: bool,
        blind_box_url: String,
        nft_url: String,
    }

    struct DutchAuctionParam has key {
        id: UID,
        start_time: u64,
        end_time: u64,
        step_num: u64,
        start_price: u64,
        end_price: u64,
    }

    struct RichCatNFT has key, store{
        id: UID,
        name: String,
        description: String,
        creator: String,
        no: u64,
    }
    

    fun init (otw: RICH_CAT, ctx: &mut TxContext,){
        let publisher = package::claim(otw, ctx);
        
        let global_config = GlobalConfig{
            id: object::new(ctx),
            version: VERSION,
            sale_amount: 0,
            total_supply: TOTAL_SUPPLY,
            is_open_blind_box: false,
            blind_box_url: string::utf8(b"ipfs://QmdJ5HeNcokLzywkZdq85kD7PqdbpMGgsUpmYkb43aDoYG"),
            nft_url:string::utf8(b"ipfs://QmT9NstiMMq8BNgzbSDxy3o5aMcGNujr7Cong84Wa1SQtN/"),
        };

        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"link"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"project_url"),
            string::utf8(b"creator"),
        ];

        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"https://github.com/paulwu0903/sui_nft_demo"),
            string::utf8(b"ipfs://QmdJ5HeNcokLzywkZdq85kD7PqdbpMGgsUpmYkb43aDoYG"),
            string::utf8(b"{description}"),
            string::utf8(b"https://github.com/paulwu0903/sui_nft_demo"),
            string::utf8(b"{creator}")
        ];

        let display = display::new_with_fields<RichCatNFT>(
            &publisher, 
            keys,
            values,
            ctx,
        );

        display::update_version(&mut display);

        transfer::public_share_object(display);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::share_object(global_config);
    }

    entry fun create_and_set_auction_param(
        config: &GlobalConfig,
        start_time: u64,
        end_time: u64,
        step_num: u64,
        start_price: u64,
        end_price: u64,
        ctx: &mut TxContext,
    ){
        check_version(config);
        let auction = DutchAuctionParam{
            id: object::new(ctx),
            start_time,
            end_time,
            step_num,
            start_price,
            end_price,
        };
        transfer::share_object(auction);
    }

    fun get_auction_price(
        auction: &DutchAuctionParam,
        clock: &Clock,
    ): u64{
        let current_time = clock::timestamp_ms(clock);
        if (current_time <= auction.start_price){
            return auction.start_price
        }else if (current_time >= auction.end_time){
            return auction.end_price
        };
        let time_step = (auction.start_time - current_time) / auction.step_num;
        let price_step = (auction.start_price - auction.end_price) / auction.step_num;
        let level = (auction.start_time - current_time) / time_step;

        auction.start_price - (price_step * level)
    }



    entry fun publish_mint_nft(
        config: &mut GlobalConfig,
        auction: &DutchAuctionParam,
        payments: &mut Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext,
    ){
        let publish_price = get_auction_price(auction, clock);
        check_version(config);
        check_time(auction.start_time, clock);
        check_value(publish_price, payments, ctx);

        let rich_cat = RichCatNFT{
            id: object::new(ctx),
            name: string::utf8(b"Rich Cat"),
            description: string::utf8(b"Rich Cat is a demo NFT project."),
            creator: string::utf8(b"Paul"),
            no: config.sale_amount + 1,
        };

        config.sale_amount = config.sale_amount + 1;
        transfer::public_transfer(rich_cat, tx_context::sender(ctx));

    }

    entry fun open_blind_box(
        config: &mut GlobalConfig,
        metadata: &mut Display<RichCatNFT>,
    ){
        check_version(config);
        assert!(!config.is_open_blind_box, EBlindBoxAlreadyOpened);
        display::edit<RichCatNFT>(metadata, string::utf8(b"image_url"), string::utf8(b"ipfs://QmT9NstiMMq8BNgzbSDxy3o5aMcGNujr7Cong84Wa1SQtN/{no}.png"));
        display::update_version(metadata);
        config.is_open_blind_box = true;
    }

    fun check_time(
        time_threshold: u64,
        clock: &Clock,
    ){
        assert!(time_threshold <= clock::timestamp_ms(clock), ETimeError);
    }

    fun check_version(
        config: &GlobalConfig,
    ){
        assert!(config.version == VERSION, EVersionError);
    }

    fun check_value (
        price: u64,
        payments: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ){
        assert!(coin::value(payments) >= price, EBalanceNotEnough);
        if(price < coin::value(payments)){
            let remain_value = coin::value(payments) - price;
            let remain_coin = coin::split(payments, remain_value, ctx);
            transfer::public_transfer(remain_coin, tx_context::sender(ctx));
        }
    }

}