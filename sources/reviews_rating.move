// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Module: reviews_rating
/// A decentralized review rating platform for food service industry on Sui blockchain
/// Модуль: reviews_rating
/// Децентрализованная платформа оценки отзывов для сферы общественного питания на блокчейне Sui
module reviews_rating::reviews_rating {
    use std::string::String;
    use sui::table::{Self, Table};
    use sui::vec_map::{Self, VecMap};

    // ======== Constants ========
    // Константы
    
    const MAX_RATING: u8 = 5; // Maximum rating value / Максимальное значение рейтинга
    const MIN_RATING: u8 = 1; // Minimum rating value / Минимальное значение рейтинга

    // ======== Errors ========
    // Ошибки
    
    const EInvalidRating: u64 = 0; // Invalid rating value / Недопустимое значение рейтинга
    const ENotAuthorized: u64 = 1; // User not authorized / Пользователь не авторизован
    const EDishNotFound: u64 = 4; // Dish not found / Блюдо не найдено

    // ======== Types ========
    // Типы
    
    /// Proof of Review NFT -证明用户留下了评论的NFT
    /// NFT-доказательство отзыва - подтверждает, что пользователь оставил отзыв
    public struct ProofOfReview has key, store {
        id: UID,
        restaurant: address, // Restaurant ID / ID ресторана
        reviewer: address, // Reviewer address / Адрес рецензента
        review_id: ID, // Associated review ID / ID связанного отзыва
        timestamp: u64, // Review timestamp / Временная метка отзыва
    }

    /// Review structure - Структура отзыва
    public struct Review has key, store {
        id: UID,
        restaurant: address, // Restaurant being reviewed / Ресторан, на который оставлен отзыв
        reviewer: address, // Person who left the review / Человек, оставивший отзыв
        rating: u8, // Rating (1-5) / Оценка (1-5)
        comment: String, // Text comment / Текстовый комментарий
        timestamp: u64, // Time review was created / Время создания отзыва
        dishes_ordered: vector<String>, // List of dishes ordered / Список заказанных блюд
        service_rating: u8, // Service quality rating / Оценка качества обслуживания
        food_rating: u8, // Food quality rating / Оценка качества еды
        ambiance_rating: u8, // Ambiance rating / Оценка атмосферы
    }

    /// Restaurant/Place structure - Структура ресторана/заведения
    public struct Restaurant has key, store {
        id: UID,
        owner: address, // Restaurant owner / Владелец ресторана
        name: String, // Restaurant name / Название ресторана
        description: String, // Restaurant description / Описание ресторана
        location: String, // Restaurant location / Местоположение ресторана
        cuisine_type: String, // Type of cuisine / Тип кухни
        reviews: vector<ID>, // List of review IDs / Список ID отзывов
        total_rating: u64, // Sum of all ratings / Сумма всех оценок
        review_count: u64, // Number of reviews / Количество отзывов
        menu: VecMap<String, DishInfo>, // Menu items / Элементы меню
    }

    /// Dish information - Информация о блюде
    public struct DishInfo has store, drop, copy {
        price: u64, // Price in smallest unit / Цена в минимальных единицах
        description: String, // Dish description / Описание блюда
        rating_sum: u64, // Sum of ratings for this dish / Сумма оценок для этого блюда
        rating_count: u64, // Number of ratings / Количество оценок
    }

    /// Platform governance and registry
    /// Управление платформой и реестр
    public struct Platform has key {
        id: UID,
        admin: address, // Platform administrator / Администратор платформы
        restaurants: Table<address, bool>, // Registry of all restaurants / Реестр всех ресторанов
        total_reviews: u64, // Total number of reviews on platform / Общее количество отзывов на платформе
        total_restaurants: u64, // Total number of restaurants / Общее количество ресторанов
    }

    /// Dashboard for restaurant owner to manage responses
    /// Панель управления для владельца ресторана для управления ответами
    public struct RestaurantDashboard has key {
        id: UID,
        restaurant: address, // Restaurant address / Адрес ресторана
        owner: address, // Owner address / Адрес владельца
        review_responses: Table<ID, String>, // Responses to reviews / Ответы на отзывы
    }

    // ======== Events ========
    // События
    
    /// Emitted when a new restaurant is created
    /// Генерируется при создании нового ресторана
    public struct RestaurantCreated has copy, drop {
        restaurant_id: address,
        owner: address,
        name: String,
    }

    /// Emitted when a new review is submitted
    /// Генерируется при отправке нового отзыва
    public struct ReviewSubmitted has copy, drop {
        review_id: ID,
        restaurant: address,
        reviewer: address,
        rating: u8,
    }

    /// Emitted when a dish is added to menu
    /// Генерируется при добавлении блюда в меню
    public struct DishAdded has copy, drop {
        restaurant: address,
        dish_name: String,
        price: u64,
    }

    // ======== Init Function ========
    // Функция инициализации
    
    /// Initialize the platform - called once on publish
    /// Инициализация платформы - вызывается один раз при публикации
    fun init(ctx: &mut TxContext) {
        let platform = Platform {
            id: object::new(ctx),
            admin: ctx.sender(),
            restaurants: table::new(ctx),
            total_reviews: 0,
            total_restaurants: 0,
        };
        transfer::share_object(platform);
    }

    // ======== Restaurant Management Functions ========
    // Функции управления рестораном
    
    /// Create a new restaurant
    /// Создать новый ресторан
    public fun create_restaurant(
        platform: &mut Platform,
        name: String,
        description: String,
        location: String,
        cuisine_type: String,
        ctx: &mut TxContext
    ) {
        let restaurant_uid = object::new(ctx);
        let restaurant_addr = restaurant_uid.to_address();
        
        let restaurant = Restaurant {
            id: restaurant_uid,
            owner: ctx.sender(),
            name,
            description,
            location,
            cuisine_type,
            reviews: vector::empty(),
            total_rating: 0,
            review_count: 0,
            menu: vec_map::empty(),
        };

        // Create dashboard for restaurant owner
        // Создать панель управления для владельца ресторана
        let dashboard = RestaurantDashboard {
            id: object::new(ctx),
            restaurant: restaurant_addr,
            owner: ctx.sender(),
            review_responses: table::new(ctx),
        };

        // Register restaurant in platform
        // Зарегистрировать ресторан на платформе
        table::add(&mut platform.restaurants, restaurant_addr, true);
        platform.total_restaurants = platform.total_restaurants + 1;

        // Emit event / Сгенерировать событие
        sui::event::emit(RestaurantCreated {
            restaurant_id: restaurant_addr,
            owner: ctx.sender(),
            name: restaurant.name,
        });

        // Transfer ownership / Передать владение
        transfer::transfer(dashboard, ctx.sender());
        transfer::share_object(restaurant);
    }

    /// Add a dish to restaurant menu
    /// Добавить блюдо в меню ресторана
    public fun add_dish_to_menu(
        restaurant: &mut Restaurant,
        dish_name: String,
        price: u64,
        description: String,
        ctx: &mut TxContext
    ) {
        // Only owner can add dishes / Только владелец может добавлять блюда
        assert!(restaurant.owner == ctx.sender(), ENotAuthorized);

        let dish_info = DishInfo {
            price,
            description,
            rating_sum: 0,
            rating_count: 0,
        };

        vec_map::insert(&mut restaurant.menu, dish_name, dish_info);

        // Emit event / Сгенерировать событие
        sui::event::emit(DishAdded {
            restaurant: object::uid_to_address(&restaurant.id),
            dish_name,
            price,
        });
    }

    /// Update dish information
    /// Обновить информацию о блюде
    public fun update_dish(
        restaurant: &mut Restaurant,
        dish_name: String,
        new_price: u64,
        new_description: String,
        ctx: &TxContext
    ) {
        assert!(restaurant.owner == ctx.sender(), ENotAuthorized);
        assert!(vec_map::contains(&restaurant.menu, &dish_name), EDishNotFound);

        let dish_info = vec_map::get_mut(&mut restaurant.menu, &dish_name);
        dish_info.price = new_price;
        dish_info.description = new_description;
    }

    // ======== Review Functions ========
    // Функции отзывов
    
    /// Submit a review for a restaurant
    /// Отправить отзыв на ресторан
    public fun submit_review(
        platform: &mut Platform,
        restaurant: &mut Restaurant,
        rating: u8,
        comment: String,
        dishes_ordered: vector<String>,
        service_rating: u8,
        food_rating: u8,
        ambiance_rating: u8,
        clock: &sui::clock::Clock,
        ctx: &mut TxContext
    ): ProofOfReview {
        // Validate ratings / Проверить оценки
        assert!(rating >= MIN_RATING && rating <= MAX_RATING, EInvalidRating);
        assert!(service_rating >= MIN_RATING && service_rating <= MAX_RATING, EInvalidRating);
        assert!(food_rating >= MIN_RATING && food_rating <= MAX_RATING, EInvalidRating);
        assert!(ambiance_rating >= MIN_RATING && ambiance_rating <= MAX_RATING, EInvalidRating);

        let reviewer = ctx.sender();
        let timestamp = sui::clock::timestamp_ms(clock);

        // Create review / Создать отзыв
        let review_uid = object::new(ctx);
        let review_id = object::uid_to_inner(&review_uid);
        
        let review = Review {
            id: review_uid,
            restaurant: object::uid_to_address(&restaurant.id),
            reviewer,
            rating,
            comment,
            timestamp,
            dishes_ordered,
            service_rating,
            food_rating,
            ambiance_rating,
        };

        // Update restaurant ratings / Обновить рейтинги ресторана
        restaurant.total_rating = restaurant.total_rating + (rating as u64);
        restaurant.review_count = restaurant.review_count + 1;
        vector::push_back(&mut restaurant.reviews, review_id);

        // Update platform statistics / Обновить статистику платформы
        platform.total_reviews = platform.total_reviews + 1;

        // Create Proof of Review NFT / Создать NFT-доказательство отзыва
        let proof = ProofOfReview {
            id: object::new(ctx),
            restaurant: object::uid_to_address(&restaurant.id),
            reviewer,
            review_id,
            timestamp,
        };

        // Emit event / Сгенерировать событие
        sui::event::emit(ReviewSubmitted {
            review_id,
            restaurant: object::uid_to_address(&restaurant.id),
            reviewer,
            rating,
        });

        // Share review and return proof / Поделиться отзывом и вернуть доказательство
        transfer::share_object(review);
        proof
    }

    /// Restaurant owner responds to a review
    /// Владелец ресторана отвечает на отзыв
    public fun respond_to_review(
        dashboard: &mut RestaurantDashboard,
        review_id: ID,
        response: String,
        ctx: &TxContext
    ) {
        // Only owner can respond / Только владелец может отвечать
        assert!(dashboard.owner == ctx.sender(), ENotAuthorized);
        
        table::add(&mut dashboard.review_responses, review_id, response);
    }

    // ======== View Functions ========
    // Функции просмотра
    
    /// Get average rating for a restaurant
    /// Получить средний рейтинг для ресторана
    public fun get_average_rating(restaurant: &Restaurant): u64 {
        if (restaurant.review_count == 0) {
            return 0
        };
        restaurant.total_rating / restaurant.review_count
    }

    /// Get total number of reviews for a restaurant
    /// Получить общее количество отзывов для ресторана
    public fun get_review_count(restaurant: &Restaurant): u64 {
        restaurant.review_count
    }

    /// Get restaurant name
    /// Получить название ресторана
    public fun get_restaurant_name(restaurant: &Restaurant): String {
        restaurant.name
    }

    /// Get review rating
    /// Получить оценку отзыва
    public fun get_review_rating(review: &Review): u8 {
        review.rating
    }

    /// Get review comment
    /// Получить комментарий отзыва
    public fun get_review_comment(review: &Review): String {
        review.comment
    }

    // ======== Test-only Functions ========
    // Функции только для тестов
    
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}