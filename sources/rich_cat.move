module advanced_nft:: rich_cat{

    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui:: clock::{Self ,Clock,};
    use sui::package::{Self};
    use sui::sui::SUI;
    use std::string::{Self,String};
    use sui::display;
    use sui::coin::{Self, Coin,};

    const VERSION: u64 = 0;

    const EVersionError: u64 = 0;
    const EBalanceNotEnough: u64 = 1;
    const ETimeError: u64 = 2;

    //OTW
    struct RICH_CAT has drop{} 

    struct GlobalConfig has key {
        id: UID, 
        version: u64,
        start_white_list_time: u64,
        white_list_price: u64,
        start_publish_time: u64,
        publish_price: u64,
        sale_amount: u64,
    }
    
    struct Ticket has key {
        id: UID,
    }

    struct RichCatNFT has key, store{
        id: UID,
        name: String,
        description: String,
        image_url: String,
        creator: String,
        link: String,
    }
    

    fun init (otw: RICH_CAT, ctx: &mut TxContext,){
        let publisher = package::claim(otw, ctx);
        
        let global_config = GlobalConfig{
            id: object::new(ctx),
            version: VERSION,
            start_white_list_time: 0,
            white_list_price: 100000000,
            start_publish_time: 0,
            publish_price: 1000000000,
            sale_amount: 0,
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
            // For `name` we can use the `Hero.name` property
            string::utf8(b"{name}"),
            // For `link` we can build a URL using an `id` property
            string::utf8(b"{link}"),
            // For `image_url` we use an ipfs :// + `img_url` or https:// + `img_url`.
            string::utf8(b"{img_url}"),
            // Description is static for all `Hero` objects.
            string::utf8(b"{description}"),
            // Project URL is usually static
            string::utf8(b"{project_url}"),
            // Creator field can be any
            string::utf8(b"{creator}")
        ];



        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::share_object(global_config);
    }

    entry fun publish_mint_nft(
        config: &GlobalConfig,
        payments: Coin<SUI>,
        clock: &mut Clock,
        ctx: &mut TxContext,
    ){
        check_version(config);
        check_time(config.start_publish_time, clock);
        check_value(config, config.publish_price, &mut payments, ctx);



        
        
    }

    fun check_time(
        time_threshold: u64,
        clock: &mut Clock,
    ){
        assert!(time_threshold >= clock::timestamp_ms(clock), ETimeError);
    }

    fun check_version(
        config: &GlobalConfig,
    ){
        assert!(config.version == VERSION, EVersionError);
    }

    fun check_value (
        config: &GlobalConfig,
        list_price: u64,
        payments: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ){
        assert!(coin::value(payments) >= config.publish_price, EBalanceNotEnough);
        if(list_price < coin::value(payments)){
            let remain_value = coin::value(payments) - list_price;
            let remain_coin = coin::split(payments, remain_value, ctx);
            transfer::public_transfer(remain_coin, tx_context::sender(ctx));
        }
    }

}