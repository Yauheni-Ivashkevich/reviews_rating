// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module reviews_rating::reviews_rating_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::clock::{Self, Clock};
    use std::string::{Self, String};
    use reviews_rating::reviews_rating::{
        Self,
        Platform,
        Restaurant,
        Review,
        ProofOfReview,
        RestaurantDashboard
    };

    // Test addresses / Тестовые адреса
    const ADMIN: address = @0xAD;
    const RESTAURANT_OWNER: address = @0xB0B;
    const REVIEWER1: address = @0xC1;
    const REVIEWER2: address = @0xC2;

    // Helper function to create a test scenario
    // Вспомогательная функция для создания тестового сценария
    fun setup_test(): Scenario {
        let mut scenario = ts::begin(ADMIN);
        {
            reviews_rating::init_for_testing(ts::ctx(&mut scenario));
        };
        scenario
    }

    // Helper to create a string / Вспомогательная для создания строки
    fun utf8(bytes: vector<u8>): String {
        string::utf8(bytes)
    }

    #[test]
    /// Test platform initialization
    /// Тест инициализации платформы
    fun test_init() {
        let mut scenario = setup_test();
        
        ts::next_tx(&mut scenario, ADMIN);
        {
            // Check that platform was created / Проверить, что платформа создана
            assert!(ts::has_most_recent_shared<Platform>(), 0);
        };
        
        ts::end(scenario);
    }

    #[test]
    /// Test restaurant creation
    /// Тест создания ресторана
    fun test_create_restaurant() {
        let mut scenario = setup_test();
        
        // Restaurant owner creates a restaurant
        // Владелец ресторана создает ресторан
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            
            reviews_rating::create_restaurant(
                &mut platform,
                utf8(b"Test Restaurant"),
                utf8(b"A great place to eat"),
                utf8(b"123 Test Street"),
                utf8(b"Italian"),
                ts::ctx(&mut scenario)
            );
            
            ts::return_shared(platform);
        };

        // Verify restaurant was created
        // Проверить, что ресторан создан
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            assert!(ts::has_most_recent_shared<Restaurant>(), 1);
            assert!(ts::has_most_recent_for_address<RestaurantDashboard>(RESTAURANT_OWNER), 2);
        };
        
        ts::end(scenario);
    }

    #[test]
    /// Test adding dishes to menu
    /// Тест добавления блюд в меню
    fun test_add_dish_to_menu() {
        let mut scenario = setup_test();
        
        // Create restaurant / Создать ресторан
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            reviews_rating::create_restaurant(
                &mut platform,
                utf8(b"Test Restaurant"),
                utf8(b"A great place"),
                utf8(b"123 Test St"),
                utf8(b"Italian"),
                ts::ctx(&mut scenario)
            );
            ts::return_shared(platform);
        };

        // Add dish to menu / Добавить блюдо в меню
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut restaurant = ts::take_shared<Restaurant>(&scenario);
            
            reviews_rating::add_dish_to_menu(
                &mut restaurant,
                utf8(b"Pasta Carbonara"),
                1500, // Price in cents / Цена в центах
                utf8(b"Classic Italian pasta"),
                ts::ctx(&mut scenario)
            );
            
            ts::return_shared(restaurant);
        };
        
        ts::end(scenario);
    }

    #[test]
    /// Test submitting a review
    /// Тест отправки отзыва
    fun test_submit_review() {
        let mut scenario = setup_test();
        
        // Create restaurant / Создать ресторан
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            reviews_rating::create_restaurant(
                &mut platform,
                utf8(b"Test Restaurant"),
                utf8(b"Great food"),
                utf8(b"123 Test St"),
                utf8(b"Italian"),
                ts::ctx(&mut scenario)
            );
            ts::return_shared(platform);
        };

        // Create clock for timestamp / Создать часы для временной метки
        ts::next_tx(&mut scenario, REVIEWER1);
        {
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            clock::share_for_testing(clock);
        };

        // Submit review / Отправить отзыв
        ts::next_tx(&mut scenario, REVIEWER1);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            let mut restaurant = ts::take_shared<Restaurant>(&scenario);
            let clock = ts::take_shared<Clock>(&scenario);
            
            let dishes = vector[utf8(b"Pasta Carbonara")];
            
            let proof = reviews_rating::submit_review(
                &mut platform,
                &mut restaurant,
                5, // Overall rating / Общая оценка
                utf8(b"Excellent food and service!"),
                dishes,
                5, // Service rating / Оценка обслуживания
                5, // Food rating / Оценка еды
                4, // Ambiance rating / Оценка атмосферы
                &clock,
                ts::ctx(&mut scenario)
            );
            
            // Transfer proof to reviewer / Передать доказательство рецензенту
            transfer::public_transfer(proof, REVIEWER1);
            
            ts::return_shared(platform);
            ts::return_shared(restaurant);
            ts::return_shared(clock);
        };

        // Verify review was created and NFT proof was minted
        // Проверить, что отзыв создан и NFT-доказательство выпущено
        ts::next_tx(&mut scenario, REVIEWER1);
        {
            assert!(ts::has_most_recent_shared<Review>(), 3);
            assert!(ts::has_most_recent_for_address<ProofOfReview>(REVIEWER1), 4);
            
            let restaurant = ts::take_shared<Restaurant>(&scenario);
            assert!(reviews_rating::get_review_count(&restaurant) == 1, 5);
            assert!(reviews_rating::get_average_rating(&restaurant) == 5, 6);
            ts::return_shared(restaurant);
        };
        
        ts::end(scenario);
    }

    #[test]
    /// Test multiple reviews and average rating calculation
    /// Тест нескольких отзывов и расчета среднего рейтинга
    fun test_multiple_reviews() {
        let mut scenario = setup_test();
        
        // Create restaurant / Создать ресторан
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            reviews_rating::create_restaurant(
                &mut platform,
                utf8(b"Test Restaurant"),
                utf8(b"Great food"),
                utf8(b"123 Test St"),
                utf8(b"Italian"),
                ts::ctx(&mut scenario)
            );
            ts::return_shared(platform);
        };

        // Create clock / Создать часы
        ts::next_tx(&mut scenario, ADMIN);
        {
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            clock::share_for_testing(clock);
        };

        // First review - 5 stars / Первый отзыв - 5 звезд
        ts::next_tx(&mut scenario, REVIEWER1);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            let mut restaurant = ts::take_shared<Restaurant>(&scenario);
            let clock = ts::take_shared<Clock>(&scenario);
            
            let proof = reviews_rating::submit_review(
                &mut platform,
                &mut restaurant,
                5,
                utf8(b"Great!"),
                vector[],
                5, 5, 5,
                &clock,
                ts::ctx(&mut scenario)
            );
            
            transfer::public_transfer(proof, REVIEWER1);
            
            ts::return_shared(platform);
            ts::return_shared(restaurant);
            ts::return_shared(clock);
        };

        // Second review - 3 stars / Второй отзыв - 3 звезды
        ts::next_tx(&mut scenario, REVIEWER2);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            let mut restaurant = ts::take_shared<Restaurant>(&scenario);
            let clock = ts::take_shared<Clock>(&scenario);
            
            let proof = reviews_rating::submit_review(
                &mut platform,
                &mut restaurant,
                3,
                utf8(b"Good but not great"),
                vector[],
                3, 3, 3,
                &clock,
                ts::ctx(&mut scenario)
            );
            
            transfer::public_transfer(proof, REVIEWER2);
            
            ts::return_shared(platform);
            ts::return_shared(restaurant);
            ts::return_shared(clock);
        };

        // Verify average rating is 4 (5 + 3 / 2)
        // Проверить, что средний рейтинг равен 4 (5 + 3 / 2)
        ts::next_tx(&mut scenario, ADMIN);
        {
            let restaurant = ts::take_shared<Restaurant>(&scenario);
            assert!(reviews_rating::get_review_count(&restaurant) == 2, 7);
            assert!(reviews_rating::get_average_rating(&restaurant) == 4, 8);
            ts::return_shared(restaurant);
        };
        
        ts::end(scenario);
    }

    #[test]
    /// Test restaurant owner response to review
    /// Тест ответа владельца ресторана на отзыв
    fun test_respond_to_review() {
        let mut scenario = setup_test();
        let review_id: sui::object::ID;
        
        // Create restaurant / Создать ресторан
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            reviews_rating::create_restaurant(
                &mut platform,
                utf8(b"Test Restaurant"),
                utf8(b"Great food"),
                utf8(b"123 Test St"),
                utf8(b"Italian"),
                ts::ctx(&mut scenario)
            );
            ts::return_shared(platform);
        };

        // Create clock / Создать часы
        ts::next_tx(&mut scenario, ADMIN);
        {
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            clock::share_for_testing(clock);
        };

        // Submit review / Отправить отзыв
        ts::next_tx(&mut scenario, REVIEWER1);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            let mut restaurant = ts::take_shared<Restaurant>(&scenario);
            let clock = ts::take_shared<Clock>(&scenario);
            
            let proof = reviews_rating::submit_review(
                &mut platform,
                &mut restaurant,
                4,
                utf8(b"Good service"),
                vector[],
                4, 4, 4,
                &clock,
                ts::ctx(&mut scenario)
            );
            
            transfer::public_transfer(proof, REVIEWER1);
            
            ts::return_shared(platform);
            ts::return_shared(restaurant);
            ts::return_shared(clock);
        };

        // Get review ID / Получить ID отзыва
        ts::next_tx(&mut scenario, REVIEWER1);
        {
            let review = ts::take_shared<Review>(&scenario);
            review_id = sui::object::id(&review);
            ts::return_shared(review);
        };

        // Restaurant owner responds / Владелец ресторана отвечает
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut dashboard = ts::take_from_sender<RestaurantDashboard>(&scenario);
            
            reviews_rating::respond_to_review(
                &mut dashboard,
                review_id,
                utf8(b"Thank you for your feedback!"),
                ts::ctx(&mut scenario)
            );
            
            ts::return_to_sender(&scenario, dashboard);
        };
        
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)] // EInvalidRating
    /// Test that invalid rating (>5) fails
    /// Тест, что недопустимый рейтинг (>5) приводит к ошибке
    fun test_invalid_rating_high() {
        let mut scenario = setup_test();
        
        // Create restaurant / Создать ресторан
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            reviews_rating::create_restaurant(
                &mut platform,
                utf8(b"Test Restaurant"),
                utf8(b"Great food"),
                utf8(b"123 Test St"),
                utf8(b"Italian"),
                ts::ctx(&mut scenario)
            );
            ts::return_shared(platform);
        };

        // Create clock / Создать часы
        ts::next_tx(&mut scenario, ADMIN);
        {
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            clock::share_for_testing(clock);
        };

        // Try to submit review with invalid rating (6)
        // Попытка отправить отзыв с недопустимым рейтингом (6)
        ts::next_tx(&mut scenario, REVIEWER1);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            let mut restaurant = ts::take_shared<Restaurant>(&scenario);
            let clock = ts::take_shared<Clock>(&scenario);
            
            let proof = reviews_rating::submit_review(
                &mut platform,
                &mut restaurant,
                6, // Invalid rating / Недопустимый рейтинг
                utf8(b"Test"),
                vector[],
                5, 5, 5,
                &clock,
                ts::ctx(&mut scenario)
            );
            
            transfer::public_transfer(proof, REVIEWER1);
            
            ts::return_shared(platform);
            ts::return_shared(restaurant);
            ts::return_shared(clock);
        };
        
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)] // EInvalidRating
    /// Test that invalid rating (<1) fails
    /// Тест, что недопустимый рейтинг (<1) приводит к ошибке
    fun test_invalid_rating_low() {
        let mut scenario = setup_test();
        
        // Create restaurant / Создать ресторан
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            reviews_rating::create_restaurant(
                &mut platform,
                utf8(b"Test Restaurant"),
                utf8(b"Great food"),
                utf8(b"123 Test St"),
                utf8(b"Italian"),
                ts::ctx(&mut scenario)
            );
            ts::return_shared(platform);
        };

        // Create clock / Создать часы
        ts::next_tx(&mut scenario, ADMIN);
        {
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            clock::share_for_testing(clock);
        };

        // Try to submit review with invalid rating (0)
        // Попытка отправить отзыв с недопустимым рейтингом (0)
        ts::next_tx(&mut scenario, REVIEWER1);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            let mut restaurant = ts::take_shared<Restaurant>(&scenario);
            let clock = ts::take_shared<Clock>(&scenario);
            
            let proof = reviews_rating::submit_review(
                &mut platform,
                &mut restaurant,
                0, // Invalid rating / Недопустимый рейтинг
                utf8(b"Test"),
                vector[],
                5, 5, 5,
                &clock,
                ts::ctx(&mut scenario)
            );
            
            transfer::public_transfer(proof, REVIEWER1);
            
            ts::return_shared(platform);
            ts::return_shared(restaurant);
            ts::return_shared(clock);
        };
        
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)] // ENotAuthorized
    /// Test that non-owner cannot add dishes
    /// Тест, что не владелец не может добавлять блюда
    fun test_unauthorized_dish_add() {
        let mut scenario = setup_test();
        
        // Create restaurant / Создать ресторан
        ts::next_tx(&mut scenario, RESTAURANT_OWNER);
        {
            let mut platform = ts::take_shared<Platform>(&scenario);
            reviews_rating::create_restaurant(
                &mut platform,
                utf8(b"Test Restaurant"),
                utf8(b"Great food"),
                utf8(b"123 Test St"),
                utf8(b"Italian"),
                ts::ctx(&mut scenario)
            );
            ts::return_shared(platform);
        };

        // Try to add dish as non-owner
        // Попытка добавить блюдо не владельцем
        ts::next_tx(&mut scenario, REVIEWER1);
        {
            let mut restaurant = ts::take_shared<Restaurant>(&scenario);
            
            reviews_rating::add_dish_to_menu(
                &mut restaurant,
                utf8(b"Unauthorized Dish"),
                1000,
                utf8(b"This should fail"),
                ts::ctx(&mut scenario)
            );
            
            ts::return_shared(restaurant);
        };
        
        ts::end(scenario);
    }
}