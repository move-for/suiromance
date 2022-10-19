
module romance::tests {

    #[test_only]
    use std::string;

    #[test_only]
    use std::option;

    #[test_only]
    use sui::coin::{Self, Coin};

    // #[test_only]
    // use sui::transfer;

    #[test_only]
    use sui::sui::SUI;

    #[test_only]
    use sui::test_scenario::{Self, Scenario};

    #[test_only]
    use romance::romance::{Self, Romance, MessageBox};
    
    #[test]
    fun test_create_share_pair_ok() {
        let initiator = @0x003;
        
        let lucky_dog = @0x005;

        let name = b"I love you";
        let declaration = b"Love you forever";

        let scenario = &mut test_scenario::begin(&initiator);
        create(name, declaration, scenario);

        test_scenario::next_tx(scenario, &initiator);
        check_name_declaration(name, declaration, scenario);

        // share the romance
        test_scenario::next_tx(scenario, &initiator);
        share_romance(scenario);

        // user pair the romance and check the romance after share
        test_scenario::next_tx(scenario, &lucky_dog);
        pair_romance(scenario);

        // check the romance after pair successfully
        test_scenario::next_tx(scenario, &lucky_dog);
        check_romance_lucky_dog_after_pair(scenario);
    
    }

    #[test]
    fun send_redpack_tests() {

        let initiator: address = @0x007;
        let lucky_dog: address = @0x008;

        let name = b"I love you";
        let declaration = b"Love you forever";

        let scenario = &mut test_scenario::begin(&initiator);
        create(name, declaration, scenario);

        test_scenario::next_tx(scenario, &initiator);
        check_name_declaration(name, declaration, scenario);

        // share the romance
        test_scenario::next_tx(scenario, &initiator);
        share_romance(scenario);

        // pair romance
        test_scenario::next_tx(scenario, &lucky_dog);
        pair_romance(scenario);

        // send redpack
        test_scenario::next_tx(scenario, &lucky_dog);
        send_redpack(scenario, 10);

        // check balance
        // test_scenario::next_tx(scenario, &lucky_dog);
        // check_balance(scenario, 0);

        test_scenario::next_tx(scenario, &initiator);
        check_balance(scenario, 10);
    }

    fun create(name: vector<u8>, declaration: vector<u8>, scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        romance::create(name, declaration, ctx);
    }

    fun check_name_declaration(name: vector<u8>, declaration: vector<u8>, scenario: &mut Scenario) {
        let romance = test_scenario::take_owned<Romance>(scenario);
        let name_str = string::utf8(name);
        let declaration_str = string::utf8(declaration);
        assert!(romance::name(&romance) == name_str, 0);
        assert!(romance::declaration(&romance) == declaration_str, 0);
        test_scenario::return_owned(scenario, romance);
    }

    fun share_romance(scenario: &mut Scenario) {
        let romance = test_scenario::take_owned<Romance>(scenario);
        let msg_box = test_scenario::take_owned<MessageBox>(scenario);
        romance::share(romance, msg_box);
    }
    
    fun pair_romance(scenario: &mut Scenario) {
        let romance = test_scenario::take_shared<Romance>(scenario);
        let romance_ref = test_scenario::borrow_mut(&mut romance);
        let ctx = test_scenario::ctx(scenario);

        assert!(romance::is_share(romance_ref), 0);
        romance::pair(romance_ref, ctx);

        test_scenario::return_shared<Romance>(scenario, romance);
    }

    fun check_romance_lucky_dog_after_pair(scenario: &mut Scenario) {
        let romance_wrapper = test_scenario::take_shared<Romance>(scenario);
        let romance_ref = test_scenario::borrow_mut(&mut romance_wrapper);

        let sender = test_scenario::sender(scenario);

        assert!(option::is_some(&romance::lucky_dog(romance_ref)), 0);
        assert!(option::borrow(&romance::lucky_dog(romance_ref)) == &sender, 0);

        test_scenario::return_shared(scenario, romance_wrapper);
    }

    fun send_redpack(scenario: &mut Scenario, amount: u64) {
        let romance_wrapper = test_scenario::take_shared<Romance>(scenario);
        let romance_ref = test_scenario::borrow_mut(&mut romance_wrapper);
        // let sender = test_scenario::sender(scenario);

        let ctx = test_scenario::ctx(scenario);
        let profit = coin::mint_for_testing<SUI>(amount, ctx);
        // let to_send = coin::take(coin::balance_mut(&mut profit), amount, ctx);

        romance::send_redpack(romance_ref, profit, ctx);

        // transfer::transfer(profit, sender);
        test_scenario::return_shared(scenario, romance_wrapper);
    }

    fun check_balance(scenario: &mut Scenario, amount: u64) {

        let profit = test_scenario::take_owned<Coin<SUI>>(scenario);
        assert!(coin::value(&profit) == amount, 0);

        test_scenario::return_owned(scenario, profit);
    }
}