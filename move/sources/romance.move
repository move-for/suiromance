
module romance::romance {

    use sui::object::{Self, ID, UID};
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::vec_map;
    use sui::vec_set;

    struct Romance has key, store {
        id: UID,
        name: String,
        initiator: address, // creator
        declaration: String,    // declaration of love
        lucky_dog: Option<address>  // matched person
    }

    struct Message has store {
        id: UID,
        msg: String,
        from: address,
        to: address,
        created_at: u64,
    }

    struct MessageBox has key {
        id: UID,
        belongs: vec_set::VecSet<address>,
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

    // Create a new romance contract
    public entry fun create(name: vector<u8>, declaration: vector<u8>, ctx: &mut TxContext) {

        let initiator = tx_context::sender(ctx);

        let romance = Romance {
            id: object::new(ctx),
            name: string::utf8(name),
            initiator: initiator,
            declaration: string::utf8(declaration),
            lucky_dog: option::none(),
        };

        transfer::transfer(romance, initiator);
    }

    public entry fun share(romance: Romance) {
        transfer::share_object(romance);
    }

    public entry fun pair(romance: &mut Romance, ctx: &mut TxContext) {
        let lucky_dog = tx_context::sender(ctx);

        assert!(!is_initiator(romance, lucky_dog), ECANT_PAIR_SELF);
        assert!(option::is_none(&romance.lucky_dog), EAREADLY_PAIRED);

        option::fill(&mut romance.lucky_dog, lucky_dog);
    }

    public entry fun send_message(romance_ref: &Romance, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        
        let is_initiator = is_initiator(romance_ref, sender);
        let is_lucky_dog = is_lucky_dog(romance_ref, sender);

        assert!(is_initiator|| is_lucky_dog, ENOT_INITIATOR_OR_LUCKEY_DOG);

        let to = if (is_initiator) {
            initiator(romance_ref)
        } else {
            *option::borrow(&romance_ref.lucky_dog)
        };


    }
}

module romance::tests {

    #[test_only]
    use std::string;

    #[test_only]
    use std::option;

    #[test_only]
    use sui::test_scenario;

    #[test_only]
    use romance::romance::{Self, Romance};
    
    #[test]
    fun test_create_share_pair_ok() {
        let initiator = @0x003;
        
        let lucky_dog = @0x005;

        let name = b"I love you";
        let declaration = b"Love you forever";

        let scenario = &mut test_scenario::begin(&initiator);
        {
            let ctx = test_scenario::ctx(scenario);
            romance::create(name, declaration, ctx);
        };

        test_scenario::next_tx(scenario, &initiator);
        {
            // let ctx = test_scenario::ctx(scenario);
            let romance = test_scenario::take_owned<Romance>(scenario);
            let name_str = string::utf8(name);
            assert!(romance::name(&romance) == name_str, 0);
            test_scenario::return_owned(scenario, romance);
        };

        test_scenario::next_tx(scenario, &initiator);
        {
            let romance = test_scenario::take_owned<Romance>(scenario);
            romance::share(romance);
        };

        test_scenario::next_tx(scenario, &lucky_dog);
        {
            let romance = test_scenario::take_shared<Romance>(scenario);
            let romance_ref = test_scenario::borrow_mut(&mut romance);
            let ctx = test_scenario::ctx(scenario);

            romance::pair(romance_ref, ctx);

            test_scenario::return_shared<Romance>(scenario, romance);
        };

        test_scenario::next_tx(scenario, &initiator);
        {
            let romance_wrapper = test_scenario::take_shared<Romance>(scenario);
            let romance_ref = test_scenario::borrow_mut(&mut romance_wrapper);

            // let ctx = test_scenario::ctx(scenario);
            let sender = test_scenario::sender(scenario);
            assert!(option::is_some(&romance::lucky_dog(romance_ref)), 0);
            assert!(romance::initiator(romance_ref) == sender, 0);

            test_scenario::return_shared(scenario, romance_wrapper);
        };

        test_scenario::next_tx(scenario, &lucky_dog);
        {
            let romance_wrapper = test_scenario::take_shared<Romance>(scenario);
            let romance_ref = test_scenario::borrow_mut(&mut romance_wrapper);

            // let ctx = test_scenario::ctx(scenario);
            let sender = test_scenario::sender(scenario);
            
            assert!(option::is_some(&romance::lucky_dog(romance_ref)), 0);
            
            assert!(option::borrow(&romance::lucky_dog(romance_ref)) == &sender, 0);

            test_scenario::return_shared(scenario, romance_wrapper);
        }
    }

    
}