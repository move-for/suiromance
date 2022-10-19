
module romance::romance {

    use sui::object::{Self, ID, UID};
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::transfer;
    use sui::vec_map;
    use sui::vec_set;

    struct Romance has key, store {
        id: UID,
        name: String,
        initiator: address, // creator
        declaration: String,    // declaration of love
        lucky_dog: Option<address>,  // matched person
        msgbox_id: ID,
        is_share: bool,
    }

    struct Message has key, store {
        id: UID,
        msg: String,
        from: address,
        to: address,
        // created_at: u64,
    }

    struct MessageBox has key {
        id: UID,
        belongs: vec_set::VecSet<address>,  // the messge box belongs the initiator and lucky_dog, only the two can put messge 
        messages: vec_map::VecMap<ID, Message>,
    }

    // Romance already paired
    const EAREADLY_PAIRED: u64 = 0;

    const ENOT_INITIATOR_OR_LUCKEY_DOG: u64 = 1;

    const ECANT_PAIR_SELF: u64 = 2;

    // Getters
    public fun name(romance: &Romance): String {
        romance.name
    }

    public fun initiator(romance: &Romance): address {
        romance.initiator
    }

    public fun declaration(romance: &Romance): String {
        romance.declaration
    }

    public fun lucky_dog(romance: &Romance): Option<address> {
        romance.lucky_dog
    }

    public fun is_initiator(romance_ref: &Romance, sender: address): bool {
        initiator(romance_ref) == sender
    }

    public fun is_lucky_dog(romance_ref: &Romance, sender: address): bool {
        option::borrow(&lucky_dog(romance_ref)) == &sender
    }

    public fun is_share(romance_ref: &Romance): bool {
        romance_ref.is_share
    }

    // Create a new romance contract
    public entry fun create(name: vector<u8>, declaration: vector<u8>, ctx: &mut TxContext) {

        let initiator = tx_context::sender(ctx);

        let msg_box = MessageBox {
            id: object::new(ctx),
            belongs: vec_set::empty<address>(),
            messages: vec_map::empty<ID, Message>(),
        };
        let msgbox_id = object::id(&msg_box);

        let romance = Romance {
            id: object::new(ctx),
            name: string::utf8(name),
            initiator: initiator,
            declaration: string::utf8(declaration),
            lucky_dog: option::none(),
            msgbox_id,
            is_share: false,
        };

        transfer::transfer(romance, initiator);
        transfer::transfer(msg_box, initiator);
    }

    // the romance owner share this romance
    public entry fun share(romance: Romance, msg_box: MessageBox) {
        romance.is_share = true;
        transfer::share_object(romance);
        transfer::share_object(msg_box);
    }

    // another person pair the romance, if the romance doesn't already pair or not the owner
    public entry fun pair(romance: &mut Romance, ctx: &mut TxContext) {
        let lucky_dog = tx_context::sender(ctx);

        assert!(!is_initiator(romance, lucky_dog), ECANT_PAIR_SELF);
        assert!(option::is_none(&romance.lucky_dog), EAREADLY_PAIRED);

        option::fill(&mut romance.lucky_dog, lucky_dog);
    }

    /// send a message to another
    public entry fun send_message(romance_ref: &Romance, msg_box: &mut MessageBox, msg: vector<u8>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        

        let to = get_romance_recipient(romance_ref, sender);

        let msg = Message {
            id: object::new(ctx),
            msg: string::utf8(msg),
            from: sender,
            to,
            // created_at: epoch::
        };

        let msg_id = object::id(&msg);
        vec_map::insert(&mut msg_box.messages, msg_id, msg);
    }

    /// Send redpack
    public entry fun send_redpack(romance_ref: &mut Romance, coin: Coin<SUI>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        

        let is_initiator = is_initiator(romance_ref, sender);
        let is_lucky_dog = is_lucky_dog(romance_ref, sender);

        assert!(is_initiator|| is_lucky_dog, ENOT_INITIATOR_OR_LUCKEY_DOG);

        let to = get_romance_recipient(romance_ref, sender);

        transfer::transfer(coin, to);
    }

    fun get_romance_recipient(romance_ref: &Romance, sender: address): address {
        let is_initiator = is_initiator(romance_ref, sender);
        let is_lucky_dog = is_lucky_dog(romance_ref, sender);

        assert!(is_initiator|| is_lucky_dog, ENOT_INITIATOR_OR_LUCKEY_DOG);

        if (is_initiator) {
            *option::borrow(&romance_ref.lucky_dog)
        } else {
            initiator(romance_ref)
        }

    }
}

