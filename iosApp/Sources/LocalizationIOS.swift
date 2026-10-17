import Foundation

enum IOSAppLanguage: String, CaseIterable {
    case ru = "RU"
    case ua = "UA"
    case en = "EN"

    var next: IOSAppLanguage {
        switch self {
        case .ru: return .ua
        case .ua: return .en
        case .en: return .ru
        }
    }
}

private struct IOSLocalizedText {
    let ru: String
    let ua: String
    let en: String
}

private let iosTranslations: [String: IOSLocalizedText] = [
    "WAITING_FOR_SELLERS_DECISION": IOSLocalizedText(
        ru: "Ожидает решения продавца",
        ua: "Очікує рішення продавця",
        en: "Waiting for seller's decision"
    ),
    "SELLER_IS_PREPARING_THE_SHIPMENT": IOSLocalizedText(
        ru: "Продавец готовит отправление",
        ua: "Продавець готує відправлення",
        en: "Seller is preparing the shipment"
    ),
    "TRACKING_NUMBER_ADDED": IOSLocalizedText(
        ru: "Номер отправления добавлен",
        ua: "Номер відправлення додано",
        en: "Tracking number added"
    ),
    "SHIPPED": IOSLocalizedText(
        ru: "Отправлено",
        ua: "Відправлено",
        en: "Shipped"
    ),
    "IN_TRANSIT": IOSLocalizedText(
        ru: "В пути",
        ua: "У дорозі",
        en: "In transit"
    ),
    "ARRIVED_AT_THE_PICKUP_POINT": IOSLocalizedText(
        ru: "Прибыло в отделение",
        ua: "Прибуло у відділення",
        en: "Arrived at the pickup point"
    ),
    "RECEIVED": IOSLocalizedText(
        ru: "Получено",
        ua: "Отримано",
        en: "Received"
    ),
    "REJECTED_BY_SELLER": IOSLocalizedText(
        ru: "Отклонено продавцом",
        ua: "Відхилено продавцем",
        en: "Rejected by seller"
    ),
    "RETURNING_TO_SELLER": IOSLocalizedText(
        ru: "Возвращается продавцу",
        ua: "Повертається продавцю",
        en: "Returning to seller"
    ),
    "RETURNED_TO_SELLER": IOSLocalizedText(
        ru: "Возвращено продавцу",
        ua: "Повернено продавцю",
        en: "Returned to seller"
    ),
    "CANCELLED": IOSLocalizedText(
        ru: "Отменено",
        ua: "Скасовано",
        en: "Cancelled"
    ),
    "STATUS_IS_BEING_UPDATED": IOSLocalizedText(
        ru: "Статус уточняется",
        ua: "Статус уточнюється",
        en: "Status is being updated"
    ),
    "FAILED_TO_VERIFY_RULES_ACCEPTANCE": IOSLocalizedText(
        ru: "Не удалось проверить принятие правил",
        ua: "Не вдалося перевірити прийняття правил",
        en: "Failed to verify rules acceptance"
    ),
    "FAILED_TO_SAVE_CONSENT_PLEASE_TRY_AGAIN": IOSLocalizedText(
        ru: "Не удалось сохранить согласие. Попробуйте ещё раз.",
        ua: "Не вдалося зберегти згоду. Спробуйте ще раз.",
        en: "Failed to save consent. Please try again."
    ),
    "FAILED_TO_OPEN_THE_ORDER_FROM_THE": IOSLocalizedText(
        ru: "Не удалось открыть заказ из уведомления",
        ua: "Не вдалося відкрити замовлення зі сповіщення",
        en: "Failed to open the order from the notification"
    ),
    "USER": IOSLocalizedText(
        ru: "Пользователь",
        ua: "Користувач",
        en: "User"
    ),
    "GOOGLE_TOKEN_WAS_NOT_RECEIVED": IOSLocalizedText(
        ru: "Не получен токен Google",
        ua: "Не отримано токен Google",
        en: "Google token was not received"
    ),
    "GOOGLE_SIGN_IN_FAILED": IOSLocalizedText(
        ru: "Ошибка входа через Google",
        ua: "Помилка входу через Google",
        en: "Google sign-in failed"
    ),
    "FAILED_TO_GET_USER_DATA": IOSLocalizedText(
        ru: "Не удалось получить данные пользователя",
        ua: "Не вдалося отримати дані користувача",
        en: "Failed to get user data"
    ),
    "FAILED_TO_SAVE_COUNTRY": IOSLocalizedText(
        ru: "Не удалось сохранить страну",
        ua: "Не вдалося зберегти країну",
        en: "Failed to save country"
    ),
    "FAILED_TO_LOAD_PROFILE": IOSLocalizedText(
        ru: "Не удалось загрузить профиль",
        ua: "Не вдалося завантажити профіль",
        en: "Failed to load profile"
    ),
    "GOOGLE_ERROR": IOSLocalizedText(
        ru: "Ошибка Google: %s",
        ua: "Помилка Google: %s",
        en: "Google error: %s"
    ),
    "SIGN_IN_FAILED": IOSLocalizedText(
        ru: "Ошибка входа",
        ua: "Помилка входу",
        en: "Sign-in failed"
    ),
    "ENTER_A_VALID_EMAIL": IOSLocalizedText(
        ru: "Введите корректный email",
        ua: "Введіть коректний email",
        en: "Enter a valid email"
    ),
    "PASSWORD_MUST_CONTAIN_AT_LEAST_6_CHARACTERS": IOSLocalizedText(
        ru: "Пароль должен содержать минимум 6 символов",
        ua: "Пароль має містити щонайменше 6 символів",
        en: "Password must contain at least 6 characters"
    ),
    "AUTHENTICATION_FAILED": IOSLocalizedText(
        ru: "Ошибка авторизации",
        ua: "Помилка авторизації",
        en: "Authentication failed"
    ),
    "FAILED_TO_GET_USER_ID": IOSLocalizedText(
        ru: "Не удалось получить ID пользователя",
        ua: "Не вдалося отримати ID користувача",
        en: "Failed to get user ID"
    ),
    "FAILED_TO_SAVE_PROFILE_DATA": IOSLocalizedText(
        ru: "Не удалось сохранить данные профиля",
        ua: "Не вдалося зберегти дані профілю",
        en: "Failed to save profile data"
    ),
    "SIGN_UP": IOSLocalizedText(
        ru: "Регистрация",
        ua: "Реєстрація",
        en: "Sign up"
    ),
    "SIGN_IN": IOSLocalizedText(
        ru: "Вход",
        ua: "Вхід",
        en: "Sign in"
    ),
    "COUNTRY": IOSLocalizedText(
        ru: "Страна",
        ua: "Країна",
        en: "Country"
    ),
    "PASSWORD": IOSLocalizedText(
        ru: "Пароль",
        ua: "Пароль",
        en: "Password"
    ),
    "SIGN_UP_2": IOSLocalizedText(
        ru: "Зарегистрироваться",
        ua: "Зареєструватися",
        en: "Sign up"
    ),
    "SIGN_IN_2": IOSLocalizedText(
        ru: "Войти",
        ua: "Увійти",
        en: "Sign in"
    ),
    "ALREADY_HAVE_AN_ACCOUNT_SIGN_IN": IOSLocalizedText(
        ru: "Уже есть аккаунт? Войти",
        ua: "Вже є акаунт? Увійти",
        en: "Already have an account? Sign in"
    ),
    "DON_T_HAVE_AN_ACCOUNT_SIGN_UP": IOSLocalizedText(
        ru: "Нет аккаунта? Зарегистрироваться",
        ua: "Немає акаунта? Зареєструватися",
        en: "Don't have an account? Sign up"
    ),
    "SIGN_IN_WITH_GOOGLE": IOSLocalizedText(
        ru: "Войти через Google",
        ua: "Увійти через Google",
        en: "Sign in with Google"
    ),
    "FAILED_TO_LOAD_CHATS": IOSLocalizedText(
        ru: "Ошибка загрузки чатов",
        ua: "Помилка завантаження чатів",
        en: "Failed to load chats"
    ),
    "FAILED_TO_LOAD_THE_NEXT_PAGE": IOSLocalizedText(
        ru: "Ошибка загрузки следующей страницы",
        ua: "Помилка завантаження наступної сторінки",
        en: "Failed to load the next page"
    ),
    "LOADING_ERROR": IOSLocalizedText(
        ru: "Ошибка загрузки",
        ua: "Помилка завантаження",
        en: "Loading error"
    ),
    "HOME": IOSLocalizedText(
        ru: "Главная",
        ua: "Головна",
        en: "Home"
    ),
    "FAVORITES": IOSLocalizedText(
        ru: "Избранное",
        ua: "Обране",
        en: "Favorites"
    ),
    "CHATS": IOSLocalizedText(
        ru: "Чаты",
        ua: "Чати",
        en: "Chats"
    ),
    "PROFILE": IOSLocalizedText(
        ru: "Профиль",
        ua: "Профіль",
        en: "Profile"
    ),
    "SEARCH": IOSLocalizedText(
        ru: "Поиск",
        ua: "Пошук",
        en: "Search"
    ),
    "CREATE_LISTING": IOSLocalizedText(
        ru: "Подать объявление",
        ua: "Подати оголошення",
        en: "Create listing"
    ),
    "SEARCH_LISTINGS": IOSLocalizedText(
        ru: "Поиск объявлений",
        ua: "Пошук оголошень",
        en: "Search listings"
    ),
    "LOADING": IOSLocalizedText(
        ru: "Загрузка...",
        ua: "Завантаження...",
        en: "Loading..."
    ),
    "FAILED_TO_LOAD_FAVORITES": IOSLocalizedText(
        ru: "Ошибка избранного",
        ua: "Помилка обраного",
        en: "Failed to load favorites"
    ),
    "NO_FAVORITE_LISTINGS": IOSLocalizedText(
        ru: "Избранных объявлений нет",
        ua: "Обраних оголошень немає",
        en: "No favorite listings"
    ),
    "PLEASE_SIGN_IN_FIRST": IOSLocalizedText(
        ru: "Сначала войдите в систему",
        ua: "Спочатку увійдіть в систему",
        en: "Please sign in first"
    ),
    "LISTING_ADDED": IOSLocalizedText(
        ru: "Объявление добавлено",
        ua: "Оголошення додано",
        en: "Listing added"
    ),
    "YOU_CAN_T_MESSAGE_YOURSELF": IOSLocalizedText(
        ru: "Нельзя писать самому себе",
        ua: "Не можна писати самому собі",
        en: "You can't message yourself"
    ),
    "FAILED_TO_CREATE_CHAT": IOSLocalizedText(
        ru: "Не удалось создать чат",
        ua: "Не вдалося створити чат",
        en: "Failed to create chat"
    ),
    "LISTING_UPDATED": IOSLocalizedText(
        ru: "Объявление обновлено",
        ua: "Оголошення оновлено",
        en: "Listing updated"
    ),
    "UPDATE_FAILED": IOSLocalizedText(
        ru: "Ошибка обновления",
        ua: "Помилка оновлення",
        en: "Update failed"
    ),
    "DELETE_CHAT": IOSLocalizedText(
        ru: "Удалить чат?",
        ua: "Видалити чат?",
        en: "Delete chat?"
    ),
    "THE_CHAT_AND_ALL_MESSAGES_WILL_BE": IOSLocalizedText(
        ru: "Чат и все сообщения будут удалены безвозвратно.",
        ua: "Чат і всі повідомлення будуть видалені назавжди.",
        en: "The chat and all messages will be permanently deleted."
    ),
    "CHAT_DELETED": IOSLocalizedText(
        ru: "Чат удалён",
        ua: "Чат видалено",
        en: "Chat deleted"
    ),
    "DELETE_FAILED": IOSLocalizedText(
        ru: "Ошибка удаления",
        ua: "Помилка видалення",
        en: "Delete failed"
    ),
    "DELETE": IOSLocalizedText(
        ru: "Удалить",
        ua: "Видалити",
        en: "Delete"
    ),
    "CANCEL": IOSLocalizedText(
        ru: "Отмена",
        ua: "Скасувати",
        en: "Cancel"
    ),
    "DELETE_LISTING": IOSLocalizedText(
        ru: "Удалить объявление?",
        ua: "Видалити оголошення?",
        en: "Delete listing?"
    ),
    "LISTING_DELETED": IOSLocalizedText(
        ru: "Объявление удалено",
        ua: "Оголошення видалено",
        en: "Listing deleted"
    ),
    "ONLY_THE_SELLER_CAN_SEND_PACKAGING_CONFIRMATION": IOSLocalizedText(
        ru: "Подтверждение упаковки может отправить только продавец.",
        ua: "Підтвердження пакування може надіслати лише продавець.",
        en: "Only the seller can send packaging confirmation."
    ),
    "PACKAGING_CONFIRMATION_IS_AVAILABLE_ONLY_AFTER_A": IOSLocalizedText(
        ru: "Подтверждение упаковки доступно только после создания номера отправления для этого заказа.",
        ua: "Підтвердження пакування доступне лише після створення номера відправлення для цього замовлення.",
        en: "Packaging confirmation is available only after a tracking number has been created for this order."
    ),
    "THIS_LISTING_HAS_NO_CAMERA_VERIFICATION_DATA": IOSLocalizedText(
        ru: "У объявления нет данных проверки камеры. Подтверждение упаковки для этого объявления невозможно.",
        ua: "В оголошення немає даних перевірки камери. Підтвердження пакування для цього оголошення неможливе.",
        en: "This listing has no camera verification data. Packaging confirmation is not available for this listing."
    ),
    "PHOTO_REJECTED_REQUIRED_CAMERA_EXIF_METADATA_IS": IOSLocalizedText(
        ru: "Фото отклонено: отсутствуют обязательные EXIF-метаданные камеры.",
        ua: "Фото відхилено: відсутні обов'язкові EXIF-метадані камери.",
        en: "Photo rejected: required camera EXIF metadata is missing."
    ),
    "PHOTO_REJECTED_IT_WAS_TAKEN_WITH_A": IOSLocalizedText(
        ru: "Фото отклонено: оно сделано не тем устройством, которым были сделаны фотографии объявления.",
        ua: "Фото відхилено: його зроблено не тим пристроєм, яким були зроблені фотографії оголошення.",
        en: "Photo rejected: it was taken with a different device from the one used for the listing photos."
    ),
    "FAILED_TO_SEND_PACKAGING_CONFIRMATION": IOSLocalizedText(
        ru: "Не удалось отправить подтверждение упаковки",
        ua: "Не вдалося надіслати підтвердження пакування",
        en: "Failed to send packaging confirmation"
    ),
    "PHOTO_FAILED_VERIFICATION": IOSLocalizedText(
        ru: "Фото не прошло проверку",
        ua: "Фото не пройшло перевірку",
        en: "Photo failed verification"
    ),
    "FAILED_TO_LOAD_MESSAGES": IOSLocalizedText(
        ru: "Ошибка загрузки сообщений",
        ua: "Помилка завантаження повідомлень",
        en: "Failed to load messages"
    ),
    "CHAT_WITH_SELLER": IOSLocalizedText(
        ru: "Чат с продавцом",
        ua: "Чат із продавцем",
        en: "Chat with seller"
    ),
    "PACKAGING_CONFIRMED": IOSLocalizedText(
        ru: "Упаковка подтверждена",
        ua: "Пакування підтверджено",
        en: "Packaging confirmed"
    ),
    "FAILED_TO_CONFIRM_PACKAGING": IOSLocalizedText(
        ru: "Не удалось подтвердить упаковку",
        ua: "Не вдалося підтвердити пакування",
        en: "Failed to confirm packaging"
    ),
    "ATTACH_PHOTO": IOSLocalizedText(
        ru: "Прикрепить фото",
        ua: "Прикріпити фото",
        en: "Attach photo"
    ),
    "MESSAGE": IOSLocalizedText(
        ru: "Сообщение",
        ua: "Повідомлення",
        en: "Message"
    ),
    "PACKAGING_CONFIRMED_BY_BUYER": IOSLocalizedText(
        ru: "Упаковка подтверждена покупателем",
        ua: "Пакування підтверджено покупцем",
        en: "Packaging confirmed by buyer"
    ),
    "CHECK_THE_PACKAGING_PHOTO": IOSLocalizedText(
        ru: "Проверьте фото упаковки",
        ua: "Перевірте фото пакування",
        en: "Check the packaging photo"
    ),
    "PACKAGING_PHOTO_SENT_WAITING_FOR_BUYER_CONFIRMATION": IOSLocalizedText(
        ru: "Фото упаковки отправлено. Ожидаем подтверждения покупателя",
        ua: "Фото пакування надіслано. Очікуємо підтвердження покупця",
        en: "Packaging photo sent. Waiting for buyer confirmation"
    ),
    "CONFIRM_PACKAGING": IOSLocalizedText(
        ru: "Подтвердить упаковку",
        ua: "Підтвердити пакування",
        en: "Confirm packaging"
    ),
    "NO_LISTINGS_FOUND": IOSLocalizedText(
        ru: "Объявления не найдены",
        ua: "Оголошення не знайдені",
        en: "No listings found"
    ),
    "CHECKOUT": IOSLocalizedText(
        ru: "Оформление заказа",
        ua: "Оформлення замовлення",
        en: "Checkout"
    ),
    "IMPORTANT_PURCHASE_RULES": IOSLocalizedText(
        ru: "ВАЖНО: Правила покупки",
        ua: "ВАЖЛИВО: Правила покупки",
        en: "IMPORTANT: Purchase rules"
    ),
    "RULES_DELIVERY_WARNING_DETAILS": IOSLocalizedText(
        ru: "1. Почта/курьерская служба НЕ даст вскрыть посылку до оплаты — вы принимаете товар вслепую.\n2. Продавцы могут просить предоплату за доставку — это обсуждается напрямую с продавцом.\n3. Фото упаковки с номером ТТН является обязательным. Продавец обязан отправить подтверждение упаковки покупателю перед отправкой заказа.\n4. Не соглашайтесь на отправку товара без подтверждения упаковки.\n5. Данные доставки используются только для создания отправления.",
        ua: "1. Пошта/кур'єрська служба НЕ дасть розкрити посилку до оплати — ви приймаєте товар навмання.\n2. Продавці можуть просити передоплату за доставку — це обговорюється безпосередньо з продавцем.\n3. Фото пакування з номером ТТН є обов'язковим. Продавець зобов'язаний надіслати підтвердження пакування покупцеві перед відправленням замовлення.\n4. Не погоджуйтеся на відправлення товару без підтвердження пакування.\n5. Дані доставки використовуються лише для створення відправлення.",
        en: "1. The postal/courier service will NOT allow you to open the parcel before payment — you accept the item without inspecting it.\n2. Sellers may ask for delivery prepayment — this is discussed directly with the seller.\n3. A packaging photo with the tracking number is required. The seller must send packaging confirmation to the buyer before shipping the order.\n4. Do not agree to shipment without packaging confirmation.\n5. Delivery details are used only to create the shipment."
    ),
    "I_HAVE_READ_THE_RULES_AND_ACCEPT": IOSLocalizedText(
        ru: "Я ознакомился с правилами и принимаю риски",
        ua: "Я ознайомився з правилами та приймаю ризики",
        en: "I have read the rules and accept the risks"
    ),
    "ITEM": IOSLocalizedText(
        ru: "Товар:",
        ua: "Товар:",
        en: "Item:"
    ),
    "CASH_ON_DELIVERY": IOSLocalizedText(
        ru: "Наложенный платёж:",
        ua: "Накладений платіж:",
        en: "Cash on delivery:"
    ),
    "DELIVERY_COST": IOSLocalizedText(
        ru: "+ стоимость доставки",
        ua: "+ вартість доставки",
        en: "+ delivery cost"
    ),
    "AUTOMATIC_SHIPPING_IS_NOT_YET_AVAILABLE_FOR": IOSLocalizedText(
        ru: "Автоматическая доставка для этой страны пока не подключена.",
        ua: "Автоматична доставка для цієї країни поки не підключена.",
        en: "Automatic shipping is not yet available for this country."
    ),
    "DELIVERY_SERVICE": IOSLocalizedText(
        ru: "Служба доставки",
        ua: "Служба доставки",
        en: "Delivery service"
    ),
    "NOVA_POSHTA": IOSLocalizedText(
        ru: "Нова пошта",
        ua: "Нова Пошта",
        en: "Nova Poshta"
    ),
    "UKRPOSHTA": IOSLocalizedText(
        ru: "Укрпочта",
        ua: "Укрпошта",
        en: "Ukrposhta"
    ),
    "RECIPIENTS_FULL_NAME": IOSLocalizedText(
        ru: "ФИО получателя",
        ua: "ПІБ отримувача",
        en: "Recipient's full name"
    ),
    "RECIPIENTS_PHONE_NUMBER": IOSLocalizedText(
        ru: "Телефон получателя",
        ua: "Телефон отримувача",
        en: "Recipient's phone number"
    ),
    "ENTER_THE_CITY_AND_NOVA_POSHTA_BRANCH": IOSLocalizedText(
        ru: "Укажите город и отделение Новой почты вручную.",
        ua: "Вкажіть місто та відділення Нової Пошти вручну.",
        en: "Enter the city and Nova Poshta branch manually."
    ),
    "SELECT_THE_CITY_AND_UKRPOSHTA_BRANCH": IOSLocalizedText(
        ru: "Выберите город и отделение Укрпочты.",
        ua: "Оберіть місто та відділення Укрпошти.",
        en: "Select the city and Ukrposhta branch."
    ),
    "ENTER_THE_CITY_AND_MEEST_BRANCH_NUMBER": IOSLocalizedText(
        ru: "Укажите город и номер отделения Meest.",
        ua: "Вкажіть місто та номер відділення Meest.",
        en: "Enter the city and Meest branch number."
    ),
    "ENTER_THE_CITY_AND_CDEK_PICKUP_POINT": IOSLocalizedText(
        ru: "Укажите город и пункт выдачи CDEK.",
        ua: "Вкажіть місто та пункт видачі CDEK.",
        en: "Enter the city and CDEK pickup point."
    ),
    "THE_UKRPOSHTA_DIRECTORY_IS_UNAVAILABLE_ENTER_THE": IOSLocalizedText(
        ru: "Справочник Укрпочты недоступен. Введите город, индекс и отделение вручную.",
        ua: "Довідник Укрпошти недоступний. Введіть місто, індекс і відділення вручну.",
        en: "The Ukrposhta directory is unavailable. Enter the city, postal code, and branch manually."
    ),
    "CITY_OR_POSTAL_CODE": IOSLocalizedText(
        ru: "Город или индекс",
        ua: "Місто або індекс",
        en: "City or postal code"
    ),
    "CITY_LOCALITY": IOSLocalizedText(
        ru: "Город / населённый пункт",
        ua: "Місто / населений пункт",
        en: "City / locality"
    ),
    "START_TYPING_A_CITY": IOSLocalizedText(
        ru: "Начните вводить город",
        ua: "Почніть вводити місто",
        en: "Start typing a city"
    ),
    "FOR_EXAMPLE_KYIV": IOSLocalizedText(
        ru: "Например: Киев",
        ua: "Наприклад: Київ",
        en: "For example: Kyiv"
    ),
    "REGION_OPTIONAL": IOSLocalizedText(
        ru: "Область — необязательно",
        ua: "Область — необов'язково",
        en: "Region — optional"
    ),
    "FOR_EXAMPLE_POLTAVA_REGION": IOSLocalizedText(
        ru: "Например: Полтавская область",
        ua: "Наприклад: Полтавська область",
        en: "For example: Poltava Region"
    ),
    "POSTAL_CODE": IOSLocalizedText(
        ru: "Почтовый индекс",
        ua: "Поштовий індекс",
        en: "Postal code"
    ),
    "UKRPOSHTA_BRANCH": IOSLocalizedText(
        ru: "Отделение Укрпочты",
        ua: "Відділення Укрпошти",
        en: "Ukrposhta branch"
    ),
    "MEEST_BRANCH_NUMBER": IOSLocalizedText(
        ru: "№ отделения Meest",
        ua: "№ відділення Meest",
        en: "Meest branch number"
    ),
    "CDEK_PICKUP_POINT": IOSLocalizedText(
        ru: "Пункт выдачи CDEK",
        ua: "Пункт видачі CDEK",
        en: "CDEK pickup point"
    ),
    "NOVA_POSHTA_BRANCH_PARCEL_LOCKER": IOSLocalizedText(
        ru: "Отделение / почтомат Новой почты",
        ua: "Відділення / поштомат Нової Пошти",
        en: "Nova Poshta branch / parcel locker"
    ),
    "FOR_EXAMPLE_BRANCH_NO_5": IOSLocalizedText(
        ru: "Например: Отделение №5",
        ua: "Наприклад: Відділення №5",
        en: "For example: Branch No. 5"
    ),
    "PLACE_ORDER": IOSLocalizedText(
        ru: "Оформить заказ",
        ua: "Оформити замовлення",
        en: "Place order"
    ),
    "DELIVERY": IOSLocalizedText(
        ru: "Доставка:",
        ua: "Доставка:",
        en: "Delivery:"
    ),
    "STATUS": IOSLocalizedText(
        ru: "Статус:",
        ua: "Статус:",
        en: "Status:"
    ),
    "REJECT": IOSLocalizedText(
        ru: "Отклонить",
        ua: "Відхилити",
        en: "Reject"
    ),
    "ACCEPT": IOSLocalizedText(
        ru: "Принять",
        ua: "Прийняти",
        en: "Accept"
    ),
    "PACKAGING_PHOTO_SENT_TO_THE_BUYER_WAITING": IOSLocalizedText(
        ru: "Фото упаковки отправлено покупателю. Ожидаем подтверждение.",
        ua: "Фото пакування надіслано покупцеві. Очікуємо підтвердження.",
        en: "Packaging photo sent to the buyer. Waiting for confirmation."
    ),
    "BUYER_CONFIRMED_THE_PACKAGING": IOSLocalizedText(
        ru: "Покупатель подтвердил упаковку",
        ua: "Покупець підтвердив пакування",
        en: "Buyer confirmed the packaging"
    ),
    "SEND_PACKAGING_CONFIRMATION": IOSLocalizedText(
        ru: "Отправить подтверждение упаковки",
        ua: "Надіслати підтвердження пакування",
        en: "Send packaging confirmation"
    ),
    "SHOW_RECIPIENT_DETAILS": IOSLocalizedText(
        ru: "Показать данные получателя",
        ua: "Показати дані отримувача",
        en: "Show recipient details"
    ),
    "RECIPIENT_DETAILS": IOSLocalizedText(
        ru: "Данные получателя",
        ua: "Дані отримувача",
        en: "Recipient details"
    ),
    "NAME": IOSLocalizedText(
        ru: "Имя:",
        ua: "Ім'я:",
        en: "Name:"
    ),
    "PHONE": IOSLocalizedText(
        ru: "Телефон:",
        ua: "Телефон:",
        en: "Phone:"
    ),
    "CITY": IOSLocalizedText(
        ru: "Город:",
        ua: "Місто:",
        en: "City:"
    ),
    "REGION": IOSLocalizedText(
        ru: "Область:",
        ua: "Область:",
        en: "Region:"
    ),
    "POSTAL_CODE_2": IOSLocalizedText(
        ru: "Индекс:",
        ua: "Індекс:",
        en: "Postal code:"
    ),
    "MEEST_BRANCH_NO": IOSLocalizedText(
        ru: "№ отделения Meest:",
        ua: "№ відділення Meest:",
        en: "Meest branch No.:"
    ),
    "BRANCH": IOSLocalizedText(
        ru: "Отделение:",
        ua: "Відділення:",
        en: "Branch:"
    ),
    "PACKAGING_CONFIRMED_TAKE_THE_PARCEL_TO_A": IOSLocalizedText(
        ru: "Упаковка подтверждена. Отнесите посылку в отделение Укрпочты, оформите отправление и введите полученный 13-значный трек-номер:",
        ua: "Пакування підтверджено. Віднесіть посилку у відділення Укрпошти, оформіть відправлення та введіть отриманий 13-значний трек-номер:",
        en: "Packaging confirmed. Take the parcel to a Ukrposhta branch, create the shipment, and enter the 13-digit tracking number you receive:"
    ),
    "FIRST_SEND_THE_PACKAGING_PHOTO_TO_THE": IOSLocalizedText(
        ru: "Сначала отправьте фото упаковки покупателю и дождитесь его подтверждения. После этого можно идти в отделение Укрпочты.",
        ua: "Спочатку надішліть фото пакування покупцеві та дочекайтеся його підтвердження. Після цього можна йти у відділення Укрпошти.",
        en: "First send the packaging photo to the buyer and wait for confirmation. After that, you can go to a Ukrposhta branch."
    ),
    "CREATE_THE_SHIPMENT_IN_THE_MEEST_APP": IOSLocalizedText(
        ru: "Создайте отправление в приложении или кабинете Meest, затем введите номер отправления:",
        ua: "Створіть відправлення у застосунку або кабінеті Meest, потім введіть номер відправлення:",
        en: "Create the shipment in the Meest app or account, then enter the shipment number:"
    ),
    "CREATE_THE_SHIPMENT_IN_THE_NOVA_POSHTA": IOSLocalizedText(
        ru: "Создайте отправление в приложении или на сайте Новой почты, затем введите полученную ТТН:",
        ua: "Створіть відправлення у застосунку або на сайті Нової Пошти, потім введіть отриману ТТН:",
        en: "Create the shipment in the Nova Poshta app or website, then enter the tracking number you receive:"
    ),
    "TRACKING_NUMBER": IOSLocalizedText(
        ru: "Номер ТТН",
        ua: "Номер ТТН",
        en: "Tracking number"
    ),
    "UKRPOSHTA_TRACKING_NUMBER": IOSLocalizedText(
        ru: "Трек-номер Укрпочты",
        ua: "Трек-номер Укрпошти",
        en: "Ukrposhta tracking number"
    ),
    "MEEST_SHIPMENT_NUMBER": IOSLocalizedText(
        ru: "Номер отправления Meest",
        ua: "Номер відправлення Meest",
        en: "Meest shipment number"
    ),
    "CDEK_TRACKING_NUMBER": IOSLocalizedText(
        ru: "Трек-номер CDEK",
        ua: "Трек-номер CDEK",
        en: "CDEK tracking number"
    ),
    "TRACKING_NUMBER_2": IOSLocalizedText(
        ru: "Трек-номер",
        ua: "Трек-номер",
        en: "Tracking number"
    ),
    "SAVE_TRACKING_NUMBER": IOSLocalizedText(
        ru: "Сохранить ТТН",
        ua: "Зберегти ТТН",
        en: "Save tracking number"
    ),
    "SAVE_TRACKING_NUMBER_2": IOSLocalizedText(
        ru: "Сохранить трек-номер",
        ua: "Зберегти трек-номер",
        en: "Save tracking number"
    ),
    "THE_TRACKING_NUMBER_WILL_APPEAR_AFTER_THE": IOSLocalizedText(
        ru: "Номер отправления появится после принятия заказа и создания отправления.",
        ua: "Номер відправлення з'явиться після прийняття замовлення та створення відправлення.",
        en: "The tracking number will appear after the order is accepted and the shipment is created."
    ),
    "AFTER_HANDING_THE_PARCEL_OVER_TO_UKRPOSHTA": IOSLocalizedText(
        ru: "После того как передадите посылку в Укрпочту, отметьте заказ как отправленный.",
        ua: "Після того як передасте посилку в Укрпошту, позначте замовлення як відправлене.",
        en: "After handing the parcel over to Ukrposhta, mark the order as shipped."
    ),
    "AFTER_HANDING_THE_PARCEL_OVER_TO_MEEST": IOSLocalizedText(
        ru: "После того как передадите посылку в Meest, отметьте заказ как отправленный.",
        ua: "Після того як передасте посилку в Meest, позначте замовлення як відправлене.",
        en: "After handing the parcel over to Meest, mark the order as shipped."
    ),
    "AFTER_HANDING_THE_PARCEL_OVER_TO_NOVA": IOSLocalizedText(
        ru: "После того как передадите посылку в Новую почту, отметьте заказ как отправленный.",
        ua: "Після того як передасте посилку в Нову Пошту, позначте замовлення як відправлене.",
        en: "After handing the parcel over to Nova Poshta, mark the order as shipped."
    ),
    "PARCEL_SHIPPED": IOSLocalizedText(
        ru: "Посылка отправлена",
        ua: "Посилку відправлено",
        en: "Parcel shipped"
    ),
    "PACKAGING_PHOTO_SENT_TO_THE_BUYER": IOSLocalizedText(
        ru: "Фото упаковки отправлено покупателю",
        ua: "Фото пакування надіслано покупцеві",
        en: "Packaging photo sent to the buyer"
    ),
    "FAILED_TO_LOAD_ORDERS": IOSLocalizedText(
        ru: "Ошибка загрузки заказов",
        ua: "Помилка завантаження замовлень",
        en: "Failed to load orders"
    ),
    "MY_ORDERS": IOSLocalizedText(
        ru: "Мои заказы",
        ua: "Мої замовлення",
        en: "My orders"
    ),
    "NO_ORDERS_YET": IOSLocalizedText(
        ru: "Заказов пока нет",
        ua: "Замовлень поки немає",
        en: "No orders yet"
    ),
    "UNKNOWN_ITEM": IOSLocalizedText(
        ru: "Неизвестный товар",
        ua: "Невідомий товар",
        en: "Unknown item"
    ),
    "ORDER_ACCEPTED": IOSLocalizedText(
        ru: "Заказ принят",
        ua: "Замовлення прийнято",
        en: "Order accepted"
    ),
    "FAILED_TO_ACCEPT_ORDER": IOSLocalizedText(
        ru: "Не удалось принять заказ",
        ua: "Не вдалося прийняти замовлення",
        en: "Failed to accept order"
    ),
    "ORDER_REJECTED": IOSLocalizedText(
        ru: "Заказ отклонён",
        ua: "Замовлення відхилено",
        en: "Order rejected"
    ),
    "FAILED_TO_REJECT_ORDER": IOSLocalizedText(
        ru: "Не удалось отклонить заказ",
        ua: "Не вдалося відхилити замовлення",
        en: "Failed to reject order"
    ),
    "FAILED_TO_GET_RECIPIENT_DETAILS": IOSLocalizedText(
        ru: "Не удалось получить данные получателя",
        ua: "Не вдалося отримати дані отримувача",
        en: "Failed to get recipient details"
    ),
    "TRACKING_NUMBER_SAVED": IOSLocalizedText(
        ru: "Номер отправления сохранён",
        ua: "Номер відправлення збережено",
        en: "Tracking number saved"
    ),
    "FAILED_TO_SAVE_TRACKING_NUMBER": IOSLocalizedText(
        ru: "Не удалось сохранить номер отправления",
        ua: "Не вдалося зберегти номер відправлення",
        en: "Failed to save tracking number"
    ),
    "ORDER_MARKED_AS_SHIPPED": IOSLocalizedText(
        ru: "Заказ отмечен как отправленный",
        ua: "Замовлення позначено як відправлене",
        en: "Order marked as shipped"
    ),
    "FAILED_TO_MARK_AS_SHIPPED": IOSLocalizedText(
        ru: "Не удалось отметить отправку",
        ua: "Не вдалося позначити відправлення",
        en: "Failed to mark as shipped"
    ),
    "FAILED_TO_LOAD_PURCHASES": IOSLocalizedText(
        ru: "Ошибка загрузки покупок",
        ua: "Помилка завантаження покупок",
        en: "Failed to load purchases"
    ),
    "MY_PURCHASES": IOSLocalizedText(
        ru: "Мои покупки",
        ua: "Мої покупки",
        en: "My purchases"
    ),
    "YOU_DON_T_HAVE_ANY_PURCHASES_YET": IOSLocalizedText(
        ru: "У вас пока нет покупок",
        ua: "У вас поки немає покупок",
        en: "You don't have any purchases yet"
    ),
    "THANK_YOU_FOR_YOUR_PURCHASE": IOSLocalizedText(
        ru: "Спасибо за покупку!",
        ua: "Дякуємо за покупку!",
        en: "Thank you for your purchase!"
    ),
    "CONFIRMATION_FAILED": IOSLocalizedText(
        ru: "Ошибка подтверждения",
        ua: "Помилка підтвердження",
        en: "Confirmation failed"
    ),
    "NOVA_POSHTA_2": IOSLocalizedText(
        ru: "Новая Почта",
        ua: "Нова Пошта",
        en: "Nova Poshta"
    ),
    "DELIVERY_2": IOSLocalizedText(
        ru: "Доставка",
        ua: "Доставка",
        en: "Delivery"
    ),
    "STATUS_2": IOSLocalizedText(
        ru: "Статус",
        ua: "Статус",
        en: "Status"
    ),
    "TRACKING_NUMBER_3": IOSLocalizedText(
        ru: "ТТН",
        ua: "ТТН",
        en: "Tracking number"
    ),
    "TRACKING_NUMBER_HAS_NOT_BEEN_ASSIGNED_YET": IOSLocalizedText(
        ru: "Трек-номер пока не назначен",
        ua: "Трек-номер ще не призначено",
        en: "Tracking number has not been assigned yet"
    ),
    "THE_PARCEL_IS_ALREADY_AT_THE_PICKUP": IOSLocalizedText(
        ru: "Посылка уже в отделении. После фактического получения вы можете подтвердить это вручную.",
        ua: "Посилка вже у відділенні. Після фактичного отримання ви можете підтвердити це вручну.",
        en: "The parcel is already at the pickup point. After you actually receive it, you can confirm receipt manually."
    ),
    "THE_PARCEL_IS_BEING_RETURNED_TO_THE": IOSLocalizedText(
        ru: "Посылка оформлена на возврат продавцу.",
        ua: "Посилка оформлена на повернення продавцю.",
        en: "The parcel is being returned to the seller."
    ),
    "THE_SELLER_MARKED_THE_PARCEL_AS_SHIPPED": IOSLocalizedText(
        ru: "Продавец отметил посылку как отправленную. Подтвердите получение только после того, как действительно получите посылку.",
        ua: "Продавець позначив посилку як відправлену. Підтвердьте отримання лише після того, як справді отримаєте посилку.",
        en: "The seller marked the parcel as shipped. Confirm receipt only after you have actually received the parcel."
    ),
    "CONFIRM_RECEIPT": IOSLocalizedText(
        ru: "Подтвердить получение",
        ua: "Підтвердити отримання",
        en: "Confirm receipt"
    ),
    "RULES_AND_DISCLAIMER": IOSLocalizedText(
        ru: "Правила и отказ от ответственности",
        ua: "Правила та відмова від відповідальності",
        en: "Rules and disclaimer"
    ),
    "TEXT_1_ABOUT_THE_SERVICE": IOSLocalizedText(
        ru: "1. О сервисе",
        ua: "1. Про сервіс",
        en: "1. About the service"
    ),
    "RULES_PLATFORM_DISCLAIMER": IOSLocalizedText(
        ru: "«Worn panties shop» является информационной площадкой для размещения объявлений. Администрация не является стороной сделок между пользователями, не хранит и не обрабатывает денежные средства, не осуществляет доставку товаров и не несёт ответственности за содержание объявлений.",
        ua: "«Worn panties shop» є інформаційним майданчиком для розміщення оголошень. Адміністрація не є стороною угод між користувачами, не зберігає і не обробляє грошові кошти, не здійснює доставку товарів і не несе відповідальності за зміст оголошень.",
        en: "“Worn panties shop” is an information platform for posting listings. The administration is not a party to transactions between users, does not hold or process funds, does not deliver goods, and is not responsible for listing content."
    ),
    "TEXT_2_AGE_RESTRICTIONS": IOSLocalizedText(
        ru: "2. Возрастные ограничения",
        ua: "2. Вікові обмеження",
        en: "2. Age restrictions"
    ),
    "RULES_AGE_RESTRICTION": IOSLocalizedText(
        ru: "Сервис предназначен исключительно для лиц старше 18 лет. Регистрируясь, вы подтверждаете, что достигли совершеннолетия. Размещение контента с участием несовершеннолетних строго запрещено и будет немедленно удалено.",
        ua: "Сервіс призначений виключно для осіб старше 18 років. Реєструючись, ви підтверджуєте, що досягли повноліття. Розміщення контенту за участю неповнолітніх суворо заборонено і буде негайно видалено.",
        en: "The service is intended exclusively for persons aged 18 and over. By registering, you confirm that you are of legal age. Content involving minors is strictly prohibited and will be removed immediately."
    ),
    "TEXT_3_PURCHASES_AND_DELIVERY": IOSLocalizedText(
        ru: "3. Покупки и доставка",
        ua: "3. Покупки та доставка",
        en: "3. Purchases and delivery"
    ),
    "RULES_PAYMENTS_AND_DELIVERY": IOSLocalizedText(
        ru: "• Все расчёты между пользователями происходят напрямую (наложенный платёж, перевод на карту).\n• Почта/курьерская служба НЕ позволяет вскрыть посылку до оплаты — вы принимаете этот риск.\n• Фото упаковки с номером накладной является обязательным. Продавец обязан отправить подтверждение упаковки покупателю до отправки заказа.\n• Предоплата за доставку (200-300 грн) — стандартная практика защиты от отказов.",
        ua: "• Всі розрахунки між користувачами відбуваються напряму (накладений платіж, переказ на картку).\n• Пошта НЕ дозволяє розкрити посилку до оплати — ви приймаєте цей ризик.\n• Фото пакування з номером накладної є обов'язковим. Продавець зобов'язаний надіслати підтвердження пакування покупцеві до відправлення замовлення.\n• Передоплата за доставку (200-300 грн) — стандартна практика захисту від відмов.",
        en: "• All payments between users are made directly (cash on delivery, card transfer).\n• The postal/courier service does NOT allow the parcel to be opened before payment — you accept this risk.\n• A packaging photo with the tracking number is required. The seller must send packaging confirmation to the buyer before shipping the order.\n• Delivery prepayment (UAH 200–300) is a standard practice to protect against refusals."
    ),
    "TEXT_4_PHOTO_VERIFICATION_AND_PACKAGING_CONFIRMATION": IOSLocalizedText(
        ru: "4. Проверка фотографий и подтверждение упаковки",
        ua: "4. Перевірка фотографій та підтвердження пакування",
        en: "4. Photo verification and packaging confirmation"
    ),
    "RULES_PHOTO_METADATA_POLICY": IOSLocalizedText(
        ru: "• Фотографии, размещаемые в объявлении, должны содержать исходные EXIF-метаданные камеры.\n• Фотографии без обязательных EXIF-метаданных не допускаются к публикации.\n• Фотографии одного объявления должны пройти проверку и иметь одинаковый отпечаток устройства.\n• Сервис может использовать технические данные камеры для формирования обезличенного отпечатка устройства и проверки фотографий.\n• Геолокационные данные из EXIF не используются и не сохраняются сервисом.\n• При подтверждении упаковки продавец должен загрузить фотографию, сделанную тем же устройством, которым были сделаны фотографии объявления.\n• Фото подтверждения упаковки без обязательных EXIF-метаданных или с несовпадающим отпечатком устройства отклоняется.\n• Запрещается умышленно удалять, изменять, подделывать или обходить проверку метаданных и отпечатка устройства.\n• Проверка метаданных является дополнительным механизмом защиты и не является абсолютной гарантией подлинности фотографии, товара или личности пользователя.",
        ua: "• Фотографії, що розміщуються в оголошенні, повинні містити початкові EXIF-метадані камери.\n• Фотографії без обов'язкових EXIF-метаданих не допускаються до публікації.\n• Фотографії одного оголошення повинні пройти перевірку та мати однаковий відбиток пристрою.\n• Сервіс може використовувати технічні дані камери для формування знеособленого відбитка пристрою та перевірки фотографій.\n• Дані геолокації з EXIF не використовуються та не зберігаються сервісом.\n• Під час підтвердження пакування продавець повинен завантажити фотографію, зроблену тим самим пристроєм, яким були зроблені фотографії оголошення.\n• Фото підтвердження пакування без обов'язкових EXIF-метаданих або з відбитком пристрою, що не збігається, відхиляється.\n• Забороняється навмисно видаляти, змінювати, підробляти або обходити перевірку метаданих та відбитка пристрою.\n• Перевірка метаданих є додатковим механізмом захисту та не є абсолютною гарантією справжності фотографії, товару або особи користувача.",
        en: "• Photos posted in a listing must contain the original camera EXIF metadata.\n• Photos without the required EXIF metadata cannot be published.\n• Photos in the same listing must pass verification and have the same device fingerprint.\n• The service may use technical camera data to create an anonymized device fingerprint and verify photos.\n• Geolocation data from EXIF is not used or stored by the service.\n• When confirming packaging, the seller must upload a photo taken with the same device used for the listing photos.\n• A packaging confirmation photo without the required EXIF metadata or with a mismatched device fingerprint will be rejected.\n• Intentionally removing, changing, falsifying, or bypassing metadata and device fingerprint verification is prohibited.\n• Metadata verification is an additional security measure and is not an absolute guarantee of the authenticity of the photo, item, or user identity."
    ),
    "TEXT_5_PROHIBITED": IOSLocalizedText(
        ru: "5. Запрещено",
        ua: "5. Заборонено",
        en: "5. Prohibited"
    ),
    "RULES_PROHIBITED_CONTENT": IOSLocalizedText(
        ru: "• Контент с участием лиц младше 18 лет\n• Мошенничество, обман, фишинг\n• Продажа запрещённых веществ и предметов\n• Разглашение персональных данных третьих лиц\n\nНарушение ведёт к немедленной блокировке аккаунта без возврата средств.",
        ua: "• Контент за участю осіб молодше 18 років\n• Шахрайство, обман, фішинг\n• Продаж заборонених речовин і предметів\n• Розголошення персональних даних третіх осіб\n\nПорушення веде до негайного блокування акаунта без повернення коштів.",
        en: "• Content involving persons under 18\n• Fraud, deception, phishing\n• Sale of prohibited substances and items\n• Disclosure of third-party personal data\n\nViolations result in immediate account suspension without refunds."
    ),
    "TEXT_6_RESPONSIBILITY": IOSLocalizedText(
        ru: "6. Ответственность",
        ua: "6. Відповідальність",
        en: "6. Responsibility"
    ),
    "RULES_USER_RESPONSIBILITY": IOSLocalizedText(
        ru: "Используя сервис, вы принимаете на себя полную ответственность за свои действия, размещаемые материалы и достоверность предоставленной информации. Проверка EXIF-метаданных и совпадения отпечатка устройства является дополнительной технической мерой защиты и не гарантирует отсутствие мошенничества. Пользователь самостоятельно принимает решение о совершении сделки и оценивает связанные с ней риски. Администрация оставляет за собой право удалять объявления и блокировать пользователей при нарушении правил сервиса.",
        ua: "Використовуючи сервіс, ви берете на себе повну відповідальність за свої дії, розміщені матеріали та достовірність наданої інформації. Перевірка EXIF-метаданих та збігу відбитка пристрою є додатковим технічним заходом захисту та не гарантує відсутність шахрайства. Користувач самостійно приймає рішення щодо здійснення угоди та оцінює пов'язані з нею ризики. Адміністрація залишає за собою право видаляти оголошення та блокувати користувачів у разі порушення правил сервісу.",
        en: "By using the service, you accept full responsibility for your actions, posted materials, and the accuracy of the information you provide. EXIF metadata and device fingerprint matching are additional technical security measures and do not guarantee the absence of fraud. Users independently decide whether to enter into a transaction and assess the associated risks. The administration reserves the right to remove listings and block users who violate the service rules."
    ),
    "I_HAVE_READ_AND_ACCEPT_THE_RULES": IOSLocalizedText(
        ru: "Я ознакомился(ась) и принимаю правила",
        ua: "Я ознайомився(лась) і приймаю правила",
        en: "I have read and accept the rules"
    ),
    "GOT_IT": IOSLocalizedText(
        ru: "Понятно",
        ua: "Зрозуміло",
        en: "Got it"
    ),
    "CLOSE": IOSLocalizedText(
        ru: "Закрыть",
        ua: "Закрити",
        en: "Close"
    ),
    "TEXT_1_DAY": IOSLocalizedText(
        ru: "1 день",
        ua: "1 день",
        en: "1 day"
    ),
    "TEXT_3_DAYS_BEST_VALUE": IOSLocalizedText(
        ru: "3 дня (выгодно)",
        ua: "3 дні (вигідно)",
        en: "3 days (best value)"
    ),
    "TEXT_7_DAYS_MAXIMUM": IOSLocalizedText(
        ru: "7 дней (максимум)",
        ua: "7 днів (максимум)",
        en: "7 days (maximum)"
    ),
    "BOOST_LISTING": IOSLocalizedText(
        ru: "Поднять в топ",
        ua: "Підняти в топ",
        en: "Boost listing"
    ),
    "LISTING": IOSLocalizedText(
        ru: "Объявление:",
        ua: "Оголошення:",
        en: "Listing:"
    ),
    "ACTIVE_UNTIL": IOSLocalizedText(
        ru: "Активно до:",
        ua: "Активно до:",
        en: "Active until:"
    ),
    "CHOOSE_A_PROMOTION_PERIOD_PAYMENT_IS_PROCESSED": IOSLocalizedText(
        ru: "Выберите срок продвижения. Оплата через Paymegate — принимаем карты Visa/Mastercard и криптовалюту USDC.",
        ua: "Оберіть термін просування. Оплата через Paymegate — приймаємо картки Visa/Mastercard та криптовалюту USDC.",
        en: "Choose a promotion period. Payment is processed through Paymegate — Visa/Mastercard cards and USDC cryptocurrency are accepted."
    ),
    "FAILED_TO_CREATE_PAYMENT": IOSLocalizedText(
        ru: "Ошибка создания платежа",
        ua: "Помилка створення платежу",
        en: "Failed to create payment"
    ),
    "PAY": IOSLocalizedText(
        ru: "Оплатить",
        ua: "Оплатити",
        en: "Pay"
    ),
    "SUGGESTIONS_AND_FEEDBACK": IOSLocalizedText(
        ru: "Предложения и пожелания",
        ua: "Пропозиції та побажання",
        en: "Suggestions and feedback"
    ),
    "TELL_US_WHAT_SHOULD_BE_ADDED_CHANGED": IOSLocalizedText(
        ru: "Расскажите, что стоит добавить, изменить или улучшить в приложении.",
        ua: "Розкажіть, що варто додати, змінити або покращити в застосунку.",
        en: "Tell us what should be added, changed, or improved in the app."
    ),
    "YOUR_MESSAGE": IOSLocalizedText(
        ru: "Ваше сообщение...",
        ua: "Ваше повідомлення...",
        en: "Your message..."
    ),
    "THANK_YOU_YOUR_MESSAGE_HAS_BEEN_SENT": IOSLocalizedText(
        ru: "Спасибо! Сообщение отправлено.",
        ua: "Дякуємо! Повідомлення надіслано.",
        en: "Thank you! Your message has been sent."
    ),
    "FAILED_TO_SEND_MESSAGE": IOSLocalizedText(
        ru: "Не удалось отправить сообщение",
        ua: "Не вдалося надіслати повідомлення",
        en: "Failed to send message"
    ),
    "SEND": IOSLocalizedText(
        ru: "Отправить",
        ua: "Надіслати",
        en: "Send"
    ),
    "UPLOAD_PHOTO": IOSLocalizedText(
        ru: "Загрузить фото",
        ua: "Завантажити фото",
        en: "Upload photo"
    ),
    "SERVICE_RULES": IOSLocalizedText(
        ru: "Правила сервиса",
        ua: "Правила сервісу",
        en: "Service rules"
    ),
    "MY_LISTINGS_COUNT": IOSLocalizedText(
        ru: "Мои объявления: %s",
        ua: "Мої оголошення: %s",
        en: "My listings: %s"
    ),
    "YOU_DON_T_HAVE_ANY_LISTINGS_YET": IOSLocalizedText(
        ru: "У вас пока нет объявлений",
        ua: "У вас поки немає оголошень",
        en: "You don't have any listings yet"
    ),
    "NOVA_POSHTA_CONNECTED_SUCCESSFULLY": IOSLocalizedText(
        ru: "Нова пошта успешно подключена",
        ua: "Нову пошту успішно підключено",
        en: "Nova Poshta connected successfully"
    ),
    "OPENING_PAYMENT_PAGE": IOSLocalizedText(
        ru: "Открываем страницу оплаты...",
        ua: "Відкриваємо сторінку оплати...",
        en: "Opening payment page..."
    ),
    "RESERVED": IOSLocalizedText(
        ru: "Зарезервировано",
        ua: "Зарезервовано",
        en: "Reserved"
    ),
    "SOLD": IOSLocalizedText(
        ru: "Продано",
        ua: "Продано",
        en: "Sold"
    ),
    "BOOSTED_UNTIL": IOSLocalizedText(
        ru: "В топе до:",
        ua: "В топі до:",
        en: "Boosted until:"
    ),
    "EDIT": IOSLocalizedText(
        ru: "Редактировать",
        ua: "Редагувати",
        en: "Edit"
    ),
    "NOVA_POSHTA_DID_NOT_RETURN_THE_SENDERS": IOSLocalizedText(
        ru: "Нова пошта не вернула город отправителя",
        ua: "Нова пошта не повернула місто відправника",
        en: "Nova Poshta did not return the sender's city"
    ),
    "FAILED_TO_LOAD_BRANCHES": IOSLocalizedText(
        ru: "Не удалось загрузить отделения",
        ua: "Не вдалося завантажити відділення",
        en: "Failed to load branches"
    ),
    "CONNECT_NOVA_POSHTA": IOSLocalizedText(
        ru: "Подключение Новой почты",
        ua: "Підключення Нової пошти",
        en: "Connect Nova Poshta"
    ),
    "ENTER_THE_API_KEY_FROM_YOUR_NOVA": IOSLocalizedText(
        ru: "Введите API Key из личного кабинета Новой почты. Остальные данные приложение получит автоматически.",
        ua: "Введіть API Key з особистого кабінету Нової пошти. Інші дані застосунок отримає автоматично.",
        en: "Enter the API Key from your Nova Poshta account. The app will retrieve the remaining details automatically."
    ),
    "FAILED_TO_VERIFY_API_KEY": IOSLocalizedText(
        ru: "Не удалось проверить API Key",
        ua: "Не вдалося перевірити API Key",
        en: "Failed to verify API Key"
    ),
    "VERIFY_KEY": IOSLocalizedText(
        ru: "Проверить ключ",
        ua: "Перевірити ключ",
        en: "Verify key"
    ),
    "SENDER": IOSLocalizedText(
        ru: "Отправитель",
        ua: "Відправник",
        en: "Sender"
    ),
    "SELECT_SENDER": IOSLocalizedText(
        ru: "Выберите отправителя",
        ua: "Оберіть відправника",
        en: "Select sender"
    ),
    "SHIPPING_BRANCH": IOSLocalizedText(
        ru: "Отделение отправки",
        ua: "Відділення відправлення",
        en: "Shipping branch"
    ),
    "SELECT_BRANCH": IOSLocalizedText(
        ru: "Выберите отделение",
        ua: "Оберіть відділення",
        en: "Select branch"
    ),
    "FAILED_TO_CONNECT_NOVA_POSHTA": IOSLocalizedText(
        ru: "Не удалось подключить Новую почту",
        ua: "Не вдалося підключити Нову пошту",
        en: "Failed to connect Nova Poshta"
    ),
    "CONNECT": IOSLocalizedText(
        ru: "Подключить",
        ua: "Підключити",
        en: "Connect"
    ),
    "EDIT_LISTING": IOSLocalizedText(
        ru: "Редактирование объявления",
        ua: "Редагування оголошення",
        en: "Edit listing"
    ),
    "TITLE": IOSLocalizedText(
        ru: "Заголовок",
        ua: "Заголовок",
        en: "Title"
    ),
    "DESCRIPTION": IOSLocalizedText(
        ru: "Описание",
        ua: "Опис",
        en: "Description"
    ),
    "PRICE_UAH": IOSLocalizedText(
        ru: "Цена (грн)",
        ua: "Ціна (грн)",
        en: "Price (UAH)"
    ),
    "MODEL_AGE": IOSLocalizedText(
        ru: "Возраст модели",
        ua: "Вік моделі",
        en: "Model age"
    ),
    "DAYS_WORN": IOSLocalizedText(
        ru: "Дней ношения",
        ua: "Днів носіння",
        en: "Days worn"
    ),
    "TYPE": IOSLocalizedText(
        ru: "Тип",
        ua: "Тип",
        en: "Type"
    ),
    "SIZE": IOSLocalizedText(
        ru: "Размер",
        ua: "Розмір",
        en: "Size"
    ),
    "COLOR": IOSLocalizedText(
        ru: "Цвет",
        ua: "Колір",
        en: "Color"
    ),
    "VIRGIN": IOSLocalizedText(
        ru: "Девственница",
        ua: "Незаймана",
        en: "Virgin"
    ),
    "ENTER_A_TITLE": IOSLocalizedText(
        ru: "Введите заголовок",
        ua: "Введіть заголовок",
        en: "Enter a title"
    ),
    "ENTER_A_VALID_PRICE": IOSLocalizedText(
        ru: "Введите корректную цену",
        ua: "Введіть коректну ціну",
        en: "Enter a valid price"
    ),
    "AGE_MUST_BE_AT_LEAST_18": IOSLocalizedText(
        ru: "Возраст должен быть не менее 18 лет",
        ua: "Вік має бути не менше 18 років",
        en: "Age must be at least 18"
    ),
    "ENTER_A_VALID_NUMBER_OF_DAYS": IOSLocalizedText(
        ru: "Введите корректное число дней",
        ua: "Введіть коректну кількість днів",
        en: "Enter a valid number of days"
    ),
    "SELECT_AT_LEAST_ONE_DELIVERY_SERVICE": IOSLocalizedText(
        ru: "Выберите хотя бы одну службу доставки",
        ua: "Оберіть хоча б одну службу доставки",
        en: "Select at least one delivery service"
    ),
    "SAVE": IOSLocalizedText(
        ru: "Сохранить",
        ua: "Зберегти",
        en: "Save"
    ),
    "FILTERS": IOSLocalizedText(
        ru: "Фильтры",
        ua: "Фільтри",
        en: "Filters"
    ),
    "ALL": IOSLocalizedText(
        ru: "Все",
        ua: "Усі",
        en: "All"
    ),
    "VIRGIN_ONLY": IOSLocalizedText(
        ru: "Только девственница",
        ua: "Тільки незаймана",
        en: "Virgin only"
    ),
    "RESET": IOSLocalizedText(
        ru: "Сбросить",
        ua: "Скинути",
        en: "Reset"
    ),
    "APPLY": IOSLocalizedText(
        ru: "Применить",
        ua: "Застосувати",
        en: "Apply"
    ),
    "FROM": IOSLocalizedText(
        ru: "От",
        ua: "Від",
        en: "From"
    ),
    "TO": IOSLocalizedText(
        ru: "До",
        ua: "До",
        en: "To"
    ),
    "PHOTO": IOSLocalizedText(
        ru: "Фото",
        ua: "Фото",
        en: "Photo"
    ),
    "PENDING": IOSLocalizedText(
        ru: "Ожидает",
        ua: "Очікує",
        en: "Pending"
    ),
    "READY": IOSLocalizedText(
        ru: "Готово",
        ua: "Готово",
        en: "Ready"
    ),
    "ERROR": IOSLocalizedText(
        ru: "Ошибка",
        ua: "Помилка",
        en: "Error"
    ),
    "UP": IOSLocalizedText(
        ru: "Вверх",
        ua: "Вгору",
        en: "Up"
    ),
    "DOWN": IOSLocalizedText(
        ru: "Вниз",
        ua: "Вниз",
        en: "Down"
    ),
    "I_CAN_SHIP_VIA": IOSLocalizedText(
        ru: "Могу отправить:",
        ua: "Можу відправити:",
        en: "I can ship via:"
    ),
    "PUBLICATION_BLOCKED_ONE_OR_MORE_PHOTOS_ARE": IOSLocalizedText(
        ru: "Публикация запрещена: у одной или нескольких фотографий отсутствуют обязательные EXIF-метаданные камеры.",
        ua: "Публікацію заборонено: в однієї або декількох фотографій відсутні обов'язкові EXIF-метадані камери.",
        en: "Publication blocked: one or more photos are missing the required camera EXIF metadata."
    ),
    "PUBLICATION_BLOCKED_THE_PHOTOS_WERE_TAKEN_WITH": IOSLocalizedText(
        ru: "Публикация запрещена: фотографии сделаны разными устройствами.",
        ua: "Публікацію заборонено: фотографії зроблені різними пристроями.",
        en: "Publication blocked: the photos were taken with different devices."
    ),
    "MAXIMUM_5_PHOTOS": IOSLocalizedText(
        ru: "Максимум 5 фото",
        ua: "Максимум 5 фото",
        en: "Maximum 5 photos"
    ),
    "PHOTOS_ADDED_LIMIT": IOSLocalizedText(
        ru: "Добавлено только %s из %s (макс. 5)",
        ua: "Додано тільки %s із %s (макс. 5)",
        en: "Only %s of %s added (max. 5)"
    ),
    "ADD_PHOTOS_COUNT": IOSLocalizedText(
        ru: "Добавить фото (%s/%s)",
        ua: "Додати фото (%s/%s)",
        en: "Add photos (%s/%s)"
    ),
    "SELECTED_PHOTOS": IOSLocalizedText(
        ru: "Выбранные фото:",
        ua: "Вибрані фото:",
        en: "Selected photos:"
    ),
    "VERIFYING_PHOTO_AUTHENTICITY": IOSLocalizedText(
        ru: "Проверяем оригинальность фотографий...",
        ua: "Перевіряємо оригінальність фотографій...",
        en: "Verifying photo authenticity..."
    ),
    "PHOTO_METADATA_VERIFIED": IOSLocalizedText(
        ru: "✓ Метаданные фотографий подтверждены",
        ua: "✓ Метадані фотографій підтверджено",
        en: "✓ Photo metadata verified"
    ),
    "SELECT_1_TO_5_PHOTOS": IOSLocalizedText(
        ru: "Выберите от 1 до 5 фото",
        ua: "Виберіть від 1 до 5 фото",
        en: "Select 1 to 5 photos"
    ),
    "ENTER_A_PRICE_GREATER_THAN_ZERO": IOSLocalizedText(
        ru: "Введите цену больше нуля",
        ua: "Введіть ціну більше нуля",
        en: "Enter a price greater than zero"
    ),
    "PHOTO_UPLOAD_FAILED": IOSLocalizedText(
        ru: "Ошибка загрузки фото",
        ua: "Помилка завантаження фото",
        en: "Photo upload failed"
    ),
    "ADD": IOSLocalizedText(
        ru: "Добавить",
        ua: "Додати",
        en: "Add"
    ),
    "PHOTO_UNAVAILABLE": IOSLocalizedText(
        ru: "Фото недоступно",
        ua: "Фото недоступне",
        en: "Photo unavailable"
    ),
    "BACK": IOSLocalizedText(
        ru: "Назад",
        ua: "Назад",
        en: "Back"
    ),
    "NEXT": IOSLocalizedText(
        ru: "Далее",
        ua: "Далі",
        en: "Next"
    ),
    "NO_PHOTOS": IOSLocalizedText(
        ru: "Без фотографий",
        ua: "Без фотографій",
        en: "No photos"
    ),
    "LISTING_INFORMATION": IOSLocalizedText(
        ru: "Информация об объявлении",
        ua: "Інформація про оголошення",
        en: "Listing information"
    ),
    "YES": IOSLocalizedText(
        ru: "Да",
        ua: "Так",
        en: "Yes"
    ),
    "NO": IOSLocalizedText(
        ru: "Нет",
        ua: "Ні",
        en: "No"
    ),
    "PUBLICATION_DATE": IOSLocalizedText(
        ru: "Дата публикации",
        ua: "Дата публікації",
        en: "Publication date"
    ),
    "MESSAGE_SELLER": IOSLocalizedText(
        ru: "Написать продавцу",
        ua: "Писати продавцю",
        en: "Message seller"
    ),
    "HELLO_I_D_LIKE_TO_BUY_THIS": IOSLocalizedText(
        ru: "Здравствуйте! Я хочу купить этот товар.",
        ua: "Вітаю! Я хочу купити цей товар.",
        en: "Hello! I'd like to buy this item."
    ),
    "BUY": IOSLocalizedText(
        ru: "Купить",
        ua: "Купити",
        en: "Buy"
    ),
    "ORDER_PLACED_AND_SENT_TO_THE_SELLER": IOSLocalizedText(
        ru: "Заказ оформлен и отправлен продавцу на подтверждение.",
        ua: "Замовлення оформлено та надіслано продавцю на підтвердження.",
        en: "Order placed and sent to the seller for confirmation."
    ),
    "FAILED_TO_PLACE_ORDER": IOSLocalizedText(
        ru: "Не удалось оформить заказ",
        ua: "Не вдалося оформити замовлення",
        en: "Failed to place order"
    ),
    "LISTING_2": IOSLocalizedText(
        ru: "Объявление",
        ua: "Оголошення",
        en: "Listing"
    ),
    "NO_MESSAGES": IOSLocalizedText(
        ru: "Нет сообщений",
        ua: "Немає повідомлень",
        en: "No messages"
    ),
    "NO_CHATS_YET": IOSLocalizedText(
        ru: "Чатов пока нет",
        ua: "Чатів поки немає",
        en: "No chats yet"
    ),
    "AGE": IOSLocalizedText(
        ru: "Возраст",
        ua: "Вік",
        en: "Age"
    ),
    "YEARS": IOSLocalizedText(
        ru: "лет",
        ua: "років",
        en: "years"
    ),
    "PHOTOS": IOSLocalizedText(
        ru: "фото",
        ua: "фото",
        en: "photos"
    ),
    "BOOSTED": IOSLocalizedText(
        ru: "В топе",
        ua: "В топі",
        en: "Boosted"
    ),
    "NOTIFICATIONS": IOSLocalizedText(
        ru: "Уведомления",
        ua: "Сповіщення",
        en: "Notifications"
    ),
    "NOTIFICATION_CHANNEL_DESCRIPTION": IOSLocalizedText(
        ru: "Сообщения и изменения статуса заказов",
        ua: "Повідомлення та зміни статусу замовлень",
        en: "Messages and order status updates"
    ),
    "USER_NOT_AUTHORIZED": IOSLocalizedText(
        ru: "Пользователь не авторизован.",
        ua: "Користувач не авторизований.",
        en: "User is not signed in."
    ),
    "FAILED_TO_PREPARE_CHAT_DELETION": IOSLocalizedText(
        ru: "Не удалось подготовить удаление чата.",
        ua: "Не вдалося підготувати видалення чату.",
        en: "Failed to prepare chat deletion."
    ),
    "FAILED_TO_DELETE_CHAT": IOSLocalizedText(
        ru: "Не удалось удалить чат.",
        ua: "Не вдалося видалити чат.",
        en: "Failed to delete chat."
    ),
    "FAILED_TO_LOAD_CHATS_TITLE": IOSLocalizedText(
        ru: "Не удалось загрузить чаты",
        ua: "Не вдалося завантажити чати",
        en: "Failed to load chats"
    ),
    "RETRY": IOSLocalizedText(
        ru: "Повторить",
        ua: "Повторити",
        en: "Retry"
    ),
    "DELETE_CHAT_ACTION": IOSLocalizedText(
        ru: "Удалить чат",
        ua: "Видалити чат",
        en: "Delete chat"
    ),
    "PHOTO_COMPRESSION_FAILED_400KB": IOSLocalizedText(
        ru: "Не удалось сжать фото до 400 КБ.",
        ua: "Не вдалося стиснути фото до 400 КБ.",
        en: "Failed to compress the photo to 400 KB."
    ),
    "FAILED_TO_GET_FIREBASE_ID_TOKEN": IOSLocalizedText(
        ru: "Не удалось получить Firebase ID Token.",
        ua: "Не вдалося отримати Firebase ID Token.",
        en: "Failed to get Firebase ID Token."
    ),
    "INVALID_PHOTO_UPLOAD_URL": IOSLocalizedText(
        ru: "Некорректный адрес загрузки фото.",
        ua: "Некоректна адреса завантаження фото.",
        en: "Invalid photo upload URL."
    ),
    "SERVER_DID_NOT_RETURN_HTTP_RESPONSE": IOSLocalizedText(
        ru: "Сервер не вернул HTTP-ответ.",
        ua: "Сервер не повернув HTTP-відповідь.",
        en: "The server did not return an HTTP response."
    ),
    "PHOTO_UPLOAD_HTTP_ERROR": IOSLocalizedText(
        ru: "Ошибка загрузки фото %s",
        ua: "Помилка завантаження фото %s",
        en: "Photo upload error %s"
    ),
    "WORKER_DID_NOT_RETURN_FILE_ID": IOSLocalizedText(
        ru: "Worker не вернул fileId.",
        ua: "Worker не повернув fileId.",
        en: "Worker did not return fileId."
    ),
    "PHOTO_MESSAGE": IOSLocalizedText(
        ru: "📷 Фото",
        ua: "📷 Фото",
        en: "📷 Photo"
    ),
    "CHAT": IOSLocalizedText(
        ru: "Чат",
        ua: "Чат",
        en: "Chat"
    ),
    "REPORT": IOSLocalizedText(
        ru: "Пожаловаться",
        ua: "Поскаржитися",
        en: "Report"
    ),
    "BLOCK_USER": IOSLocalizedText(
        ru: "Заблокировать пользователя",
        ua: "Заблокувати користувача",
        en: "Block user"
    ),
    "REPORT_REASON": IOSLocalizedText(
        ru: "Причина жалобы",
        ua: "Причина скарги",
        en: "Report reason"
    ),
    "PROHIBITED_CONTENT": IOSLocalizedText(
        ru: "Запрещённый контент",
        ua: "Заборонений контент",
        en: "Prohibited content"
    ),
    "FRAUD": IOSLocalizedText(
        ru: "Мошенничество",
        ua: "Шахрайство",
        en: "Fraud"
    ),
    "HARASSMENT_OR_THREATS": IOSLocalizedText(
        ru: "Оскорбления или угрозы",
        ua: "Образи або погрози",
        en: "Harassment or threats"
    ),
    "SPAM": IOSLocalizedText(
        ru: "Спам",
        ua: "Спам",
        en: "Spam"
    ),
    "OTHER": IOSLocalizedText(
        ru: "Другое",
        ua: "Інше",
        en: "Other"
    ),
    "BLOCK_USER_QUESTION": IOSLocalizedText(
        ru: "Заблокировать пользователя?",
        ua: "Заблокувати користувача?",
        en: "Block user?"
    ),
    "BLOCK": IOSLocalizedText(
        ru: "Заблокировать",
        ua: "Заблокувати",
        en: "Block"
    ),
    "BLOCKED_USER_CONTENT_HIDDEN": IOSLocalizedText(
        ru: "Чаты и объявления этого пользователя будут скрыты.",
        ua: "Чати та оголошення цього користувача будуть приховані.",
        en: "This user's chats and listings will be hidden."
    ),
    "USER_BLOCKED": IOSLocalizedText(
        ru: "Пользователь заблокирован.",
        ua: "Користувача заблоковано.",
        en: "User blocked."
    ),
    "PACKAGING_CONFIRMATION": IOSLocalizedText(
        ru: "✅ Подтверждение упаковки",
        ua: "✅ Підтвердження пакування",
        en: "✅ Packaging confirmation"
    ),    "FAILED_TO_SEND_REPORT": IOSLocalizedText(
        ru: "Не удалось отправить жалобу.",
        ua: "Не вдалося надіслати скаргу.",
        en: "Failed to send report."
    ),
    "REPORT_SENT_FOR_REVIEW": IOSLocalizedText(
        ru: "Жалоба отправлена на проверку.",
        ua: "Скаргу надіслано на перевірку.",
        en: "Report sent for review."
    ),
    "FAILED_TO_BLOCK_USER": IOSLocalizedText(
        ru: "Не удалось заблокировать пользователя.",
        ua: "Не вдалося заблокувати користувача.",
        en: "Failed to block user."
    ),
    "LOADING_PROGRESS": IOSLocalizedText(
        ru: "Загрузка…",
        ua: "Завантаження…",
        en: "Loading…"
    ),
    "FAILED_TO_LOAD_LIST": IOSLocalizedText(
        ru: "Не удалось загрузить список",
        ua: "Не вдалося завантажити список",
        en: "Failed to load list"
    ),
    "NO_BLOCKED_USERS": IOSLocalizedText(
        ru: "Нет заблокированных пользователей",
        ua: "Немає заблокованих користувачів",
        en: "No blocked users"
    ),
    "BLOCKED_USERS_APPEAR_HERE": IOSLocalizedText(
        ru: "Заблокированные пользователи появятся здесь.",
        ua: "Заблоковані користувачі з'являться тут.",
        en: "Blocked users will appear here."
    ),
    "UNBLOCK": IOSLocalizedText(
        ru: "Разблокировать",
        ua: "Розблокувати",
        en: "Unblock"
    ),
    "BLOCKED_USERS": IOSLocalizedText(
        ru: "Заблокированные",
        ua: "Заблоковані",
        en: "Blocked users"
    ),
    "UNBLOCK_USER_QUESTION": IOSLocalizedText(
        ru: "Разблокировать пользователя?",
        ua: "Розблокувати користувача?",
        en: "Unblock user?"
    ),
    "UNBLOCKED_CONTENT_VISIBLE": IOSLocalizedText(
        ru: "Его объявления и чаты снова будут видны.",
        ua: "Його оголошення та чати знову будуть видимі.",
        en: "Their listings and chats will be visible again."
    ),
    "FAILED_TO_LOAD_REPORTS": IOSLocalizedText(
        ru: "Не удалось загрузить жалобы",
        ua: "Не вдалося завантажити скарги",
        en: "Failed to load reports"
    ),
    "NO_REPORTS_YET": IOSLocalizedText(
        ru: "Жалоб пока нет",
        ua: "Скарг поки немає",
        en: "No reports yet"
    ),
    "SUBMITTED_REPORTS_APPEAR_HERE": IOSLocalizedText(
        ru: "Отправленные жалобы и их статусы появятся здесь.",
        ua: "Надіслані скарги та їхні статуси з'являться тут.",
        en: "Submitted reports and their statuses will appear here."
    ),
    "MY_REPORTS": IOSLocalizedText(
        ru: "Мои жалобы",
        ua: "Мої скарги",
        en: "My reports"
    ),
    "REPORT_STATUS_OPEN": IOSLocalizedText(
        ru: "На проверке",
        ua: "На перевірці",
        en: "Pending review"
    ),
    "REPORT_STATUS_REVIEWING": IOSLocalizedText(
        ru: "Рассматривается",
        ua: "Розглядається",
        en: "Under review"
    ),
    "REPORT_STATUS_RESOLVED": IOSLocalizedText(
        ru: "Рассмотрена",
        ua: "Розглянута",
        en: "Resolved"
    ),
    "REPORT_STATUS_REJECTED": IOSLocalizedText(
        ru: "Отклонена",
        ua: "Відхилена",
        en: "Rejected"
    ),
    "REPORT_STATUS_CLOSED": IOSLocalizedText(
        ru: "Закрыта",
        ua: "Закрита",
        en: "Closed"
    ),
    "LISTING_ID_LABEL": IOSLocalizedText(
        ru: "Объявление: %s",
        ua: "Оголошення: %s",
        en: "Listing: %s"
    ),
    "CHAT_ID_LABEL": IOSLocalizedText(
        ru: "Чат: %s",
        ua: "Чат: %s",
        en: "Chat: %s"
    ),
    "USER_ID_LABEL": IOSLocalizedText(
        ru: "Пользователь: %s",
        ua: "Користувач: %s",
        en: "User: %s"
    ),    "FAILED_TO_PREPARE_REQUEST": IOSLocalizedText(
        ru: "Не удалось подготовить запрос.",
        ua: "Не вдалося підготувати запит.",
        en: "Failed to prepare request."
    ),
    "SERVER_ERROR_HTTP": IOSLocalizedText(
        ru: "Ошибка сервера %s",
        ua: "Помилка сервера %s",
        en: "Server error %s"
    ),
    "OPERATION_FAILED": IOSLocalizedText(
        ru: "Операция не выполнена.",
        ua: "Операцію не виконано.",
        en: "Operation failed."
    ),
    "PHOTO_MUST_BE_UNDER_400KB": IOSLocalizedText(
        ru: "Фото должно быть не больше 400 КБ.",
        ua: "Фото має бути не більше 400 КБ.",
        en: "The photo must be no larger than 400 KB."
    ),
    "WORKER_DID_NOT_RETURN_DELIVERY_DATA": IOSLocalizedText(
        ru: "Worker не вернул данные доставки.",
        ua: "Worker не повернув дані доставки.",
        en: "Worker did not return delivery data."
    ),
    "LISTING_HAS_NO_CAMERA_DATA": IOSLocalizedText(
        ru: "У объявления нет данных проверки камеры.",
        ua: "В оголошення немає даних перевірки камери.",
        en: "The listing has no camera verification data."
    ),
    "PHOTO_REJECTED_EXIF_AND_DATE_REQUIRED": IOSLocalizedText(
        ru: "Фото отклонено: нужны EXIF-данные камеры и дата съёмки.",
        ua: "Фото відхилено: потрібні EXIF-дані камери та дата зйомки.",
        en: "Photo rejected: camera EXIF data and capture date are required."
    ),
    "PHOTO_REJECTED_DIFFERENT_CAMERA": IOSLocalizedText(
        ru: "Фото отклонено: оно сделано другой камерой.",
        ua: "Фото відхилено: його зроблено іншою камерою.",
        en: "Photo rejected: it was taken with a different camera."
    ),
    "FAILED_TO_PREPARE_PHOTO_400KB": IOSLocalizedText(
        ru: "Не удалось подготовить фото до 400 КБ.",
        ua: "Не вдалося підготувати фото до 400 КБ.",
        en: "Failed to prepare the photo to 400 KB."
    ),
    "CHECK_TRACKING_NUMBER": IOSLocalizedText(
        ru: "Проверьте номер отправления.",
        ua: "Перевірте номер відправлення.",
        en: "Check the tracking number."
    ),
    "RECIPIENT": IOSLocalizedText(
        ru: "Получатель",
        ua: "Отримувач",
        en: "Recipient"
    ),
    "FULL_NAME": IOSLocalizedText(
        ru: "ФИО",
        ua: "ПІБ",
        en: "Full name"
    ),
    "PHONE_LABEL": IOSLocalizedText(
        ru: "Телефон",
        ua: "Телефон",
        en: "Phone"
    ),
    "CITY_LABEL": IOSLocalizedText(
        ru: "Город",
        ua: "Місто",
        en: "City"
    ),
    "AREA": IOSLocalizedText(
        ru: "Область",
        ua: "Область",
        en: "Region"
    ),
    "INDEX": IOSLocalizedText(
        ru: "Индекс",
        ua: "Індекс",
        en: "Postal code"
    ),
    "BRANCH_LABEL": IOSLocalizedText(
        ru: "Отделение",
        ua: "Відділення",
        en: "Branch"
    ),
    "SAVE_SHIPMENT_NUMBER": IOSLocalizedText(
        ru: "Сохранить номер отправления",
        ua: "Зберегти номер відправлення",
        en: "Save shipment number"
    ),
    "BUYER_MUST_CONFIRM_PACKAGING_FIRST": IOSLocalizedText(
        ru: "Сначала покупатель должен подтвердить фото упаковки.",
        ua: "Спочатку покупець має підтвердити фото пакування.",
        en: "The buyer must confirm the packaging photo first."
    ),
    "PACKAGING_CONFIRMED_CHECKMARK": IOSLocalizedText(
        ru: "✓ Упаковка подтверждена",
        ua: "✓ Пакування підтверджено",
        en: "✓ Packaging confirmed"
    ),
    "PARCEL_ALREADY_AT_BRANCH": IOSLocalizedText(
        ru: "Посылка уже в отделении.",
        ua: "Посилка вже у відділенні.",
        en: "The parcel is already at the pickup point."
    ),
    "PARCEL_RETURNING_TO_SELLER": IOSLocalizedText(
        ru: "Посылка возвращается продавцу.",
        ua: "Посилка повертається продавцю.",
        en: "The parcel is returning to the seller."
    ),
    "RECEIVED_CHECKMARK": IOSLocalizedText(
        ru: "✓ Получено",
        ua: "✓ Отримано",
        en: "✓ Received"
    ),
    "AWAITING_SELLER": IOSLocalizedText(
        ru: "Ожидает продавца",
        ua: "Очікує продавця",
        en: "Waiting for seller"
    ),
    "AWAITING_SHIPMENT_NUMBER": IOSLocalizedText(
        ru: "Ожидает номер отправления",
        ua: "Очікує номер відправлення",
        en: "Waiting for shipment number"
    ),
    "SHIPMENT_CREATED": IOSLocalizedText(
        ru: "Отправление создано",
        ua: "Відправлення створено",
        en: "Shipment created"
    ),
    "REJECTED": IOSLocalizedText(
        ru: "Отклонено",
        ua: "Відхилено",
        en: "Rejected"
    ),
    "RETURNING": IOSLocalizedText(
        ru: "Возвращается",
        ua: "Повертається",
        en: "Returning"
    ),
    "RETURNED": IOSLocalizedText(
        ru: "Возвращено",
        ua: "Повернено",
        en: "Returned"
    ),
    "NOVA_POSHTA_RU_NAME": IOSLocalizedText(
        ru: "Новая почта",
        ua: "Нова пошта",
        en: "Nova Poshta"
    ),
    "GENERIC_SHIPMENT_NUMBER": IOSLocalizedText(
        ru: "Номер отправления",
        ua: "Номер відправлення",
        en: "Shipment number"
    ),    "UNTITLED": IOSLocalizedText(
        ru: "Без названия",
        ua: "Без назви",
        en: "Untitled"
    ),
    "THIS_IS_YOUR_LISTING": IOSLocalizedText(
        ru: "Это ваше объявление",
        ua: "Це ваше оголошення",
        en: "This is your listing"
    ),
    "AUTO_DELIVERY_ONLY_UKRAINE": IOSLocalizedText(
        ru: "Автоматическое оформление доставки пока доступно только для Украины.",
        ua: "Автоматичне оформлення доставки поки доступне лише для України.",
        en: "Automatic shipping setup is currently available only for Ukraine."
    ),
    "BLOCK_SELLER_QUESTION": IOSLocalizedText(
        ru: "Заблокировать продавца?",
        ua: "Заблокувати продавця?",
        en: "Block seller?"
    ),
    "SELLER_CONTENT_WILL_BE_HIDDEN": IOSLocalizedText(
        ru: "Его объявления и чаты будут скрыты для вас.",
        ua: "Його оголошення та чати будуть приховані для вас.",
        en: "Their listings and chats will be hidden from you."
    ),
    "ORDER_PLACED_CHAT_USER_NOT_AUTHORIZED": IOSLocalizedText(
        ru: "Заказ оформлен, но не удалось открыть чат: пользователь не авторизован.",
        ua: "Замовлення оформлено, але не вдалося відкрити чат: користувач не авторизований.",
        en: "Order placed, but the chat could not be opened: user is not signed in."
    ),
    "ORDER_PLACED_CHAT_OPEN_FAILED": IOSLocalizedText(
        ru: "Заказ оформлен, но не удалось открыть чат.",
        ua: "Замовлення оформлено, але не вдалося відкрити чат.",
        en: "Order placed, but the chat could not be opened."
    ),
    "ORDER_PLACED_CHAT_ERROR": IOSLocalizedText(
        ru: "Заказ оформлен, но чат не открылся: %s",
        ua: "Замовлення оформлено, але чат не відкрився: %s",
        en: "Order placed, but the chat did not open: %s"
    ),
    "ORDER_PLACED_FIRST_MESSAGE_FAILED": IOSLocalizedText(
        ru: "Заказ оформлен, но первое сообщение не отправилось: %s",
        ua: "Замовлення оформлено, але перше повідомлення не надіслалося: %s",
        en: "Order placed, but the first message was not sent: %s"
    ),
    "CHECKOUT_SHORT": IOSLocalizedText(
        ru: "Оформление",
        ua: "Оформлення",
        en: "Checkout"
    ),
    "PHONE_EXAMPLE": IOSLocalizedText(
        ru: "Телефон, например +380...",
        ua: "Телефон, наприклад +380...",
        en: "Phone, for example +380..."
    ),
    "AREA_OPTIONAL": IOSLocalizedText(
        ru: "Область (необязательно)",
        ua: "Область (необов'язково)",
        en: "Region (optional)"
    ),
    "MEEST_BRANCH_NUMBER_LONG": IOSLocalizedText(
        ru: "Номер отделения Meest",
        ua: "Номер відділення Meest",
        en: "Meest branch number"
    ),
    "CHECKED_RECIPIENT_DATA_ACCEPT_RULES": IOSLocalizedText(
        ru: "Я проверил данные получателя и принимаю правила оформления заказа",
        ua: "Я перевірив дані отримувача та приймаю правила оформлення замовлення",
        en: "I checked the recipient details and accept the order rules"
    ),    "NEW_LISTING": IOSLocalizedText(
        ru: "Новое объявление",
        ua: "Нове оголошення",
        en: "New listing"
    ),
    "EDITING": IOSLocalizedText(
        ru: "Редактирование",
        ua: "Редагування",
        en: "Editing"
    ),
    "PRICE": IOSLocalizedText(
        ru: "Цена",
        ua: "Ціна",
        en: "Price"
    ),
    "PUBLISH": IOSLocalizedText(
        ru: "Опубликовать",
        ua: "Опублікувати",
        en: "Publish"
    ),
    "MY_LISTINGS": IOSLocalizedText(
        ru: "Мои объявления",
        ua: "Мої оголошення",
        en: "My listings"
    ),
    "ONLY_OWN_LISTING_CAN_BE_DELETED": IOSLocalizedText(
        ru: "Можно удалить только своё объявление.",
        ua: "Можна видалити лише своє оголошення.",
        en: "You can delete only your own listing."
    ),
    "ADD_MAXIMUM_5_PHOTOS": IOSLocalizedText(
        ru: "Можно добавить максимум 5 фото.",
        ua: "Можна додати максимум 5 фото.",
        en: "You can add a maximum of 5 photos."
    ),
    "NEED_1_TO_5_PHOTOS": IOSLocalizedText(
        ru: "Нужно добавить от 1 до 5 фото.",
        ua: "Потрібно додати від 1 до 5 фото.",
        en: "You need to add 1 to 5 photos."
    ),
    "PHOTOS_MISSING_REQUIRED_EXIF": IOSLocalizedText(
        ru: "Одно или несколько фото не содержат нужные EXIF-данные камеры.",
        ua: "Одне або кілька фото не містять потрібних EXIF-даних камери.",
        en: "One or more photos are missing the required camera EXIF data."
    ),
    "ALL_PHOTOS_SAME_CAMERA": IOSLocalizedText(
        ru: "Все фото должны быть сделаны одной камерой.",
        ua: "Усі фото мають бути зроблені однією камерою.",
        en: "All photos must be taken with the same camera."
    ),
    "FAILED_TO_PREPARE_PHOTOS_400KB": IOSLocalizedText(
        ru: "Не удалось подготовить одно или несколько фото до 400 КБ.",
        ua: "Не вдалося підготувати одне або кілька фото до 400 КБ.",
        en: "Failed to prepare one or more photos to 400 KB."
    ),
    "EDIT_PHOTOS_UNCHANGED": IOSLocalizedText(
        ru: "Фото при редактировании остаются прежними, как в Android-версии.",
        ua: "Фото під час редагування залишаються без змін, як в Android-версії.",
        en: "Photos remain unchanged while editing, as in the Android version."
    ),
    "PHOTOS_COUNT": IOSLocalizedText(
        ru: "Фото: %s / 5",
        ua: "Фото: %s / 5",
        en: "Photos: %s / 5"
    ),
    "ADD_PHOTO": IOSLocalizedText(
        ru: "Добавить фото",
        ua: "Додати фото",
        en: "Add photo"
    ),
    "PHOTO_EXIF_REQUIREMENTS": IOSLocalizedText(
        ru: "Нужно 1–5 фото. Все фото должны содержать EXIF и быть сделаны одной камерой.",
        ua: "Потрібно 1–5 фото. Усі фото мають містити EXIF і бути зроблені однією камерою.",
        en: "You need 1–5 photos. All photos must contain EXIF and be taken with the same camera."
    ),
    "FAILED_TO_PREPARE_PHOTO_UPLOAD": IOSLocalizedText(
        ru: "Не удалось подготовить загрузку фото.",
        ua: "Не вдалося підготувати завантаження фото.",
        en: "Failed to prepare photo upload."
    ),
    "TYPE_SHORTS": IOSLocalizedText(
        ru: "Шортики",
        ua: "Шортики",
        en: "Boyshorts"
    ),
    "TYPE_THONGS": IOSLocalizedText(
        ru: "Стринги",
        ua: "Стрінги",
        en: "Thongs"
    ),
    "TYPE_TANGA": IOSLocalizedText(
        ru: "Танга",
        ua: "Танга",
        en: "Tanga"
    ),
    "TYPE_BIKINI": IOSLocalizedText(
        ru: "Бикини",
        ua: "Бікіні",
        en: "Bikini"
    ),
    "TYPE_BRIEFS": IOSLocalizedText(
        ru: "Слипы",
        ua: "Сліпи",
        en: "Briefs"
    ),
    "TYPE_BRAZILIAN": IOSLocalizedText(
        ru: "Бразилиана",
        ua: "Бразиліана",
        en: "Brazilian"
    ),
    "TYPE_LACE": IOSLocalizedText(
        ru: "Кружевные",
        ua: "Мереживні",
        en: "Lace"
    ),
    "COLOR_BLACK": IOSLocalizedText(
        ru: "Черный",
        ua: "Чорний",
        en: "Black"
    ),
    "COLOR_RED": IOSLocalizedText(
        ru: "Красный",
        ua: "Червоний",
        en: "Red"
    ),
    "COLOR_PINK": IOSLocalizedText(
        ru: "Розовый",
        ua: "Рожевий",
        en: "Pink"
    ),
    "COLOR_WHITE": IOSLocalizedText(
        ru: "Белый",
        ua: "Білий",
        en: "White"
    ),
    "COLOR_BLUE": IOSLocalizedText(
        ru: "Синий",
        ua: "Синій",
        en: "Blue"
    ),
    "COLOR_OTHER": IOSLocalizedText(
        ru: "Другой",
        ua: "Інший",
        en: "Other"
    ),    "LOG_OUT": IOSLocalizedText(
        ru: "Выйти из аккаунта",
        ua: "Вийти з акаунта",
        en: "Log out"
    ),
    "UKRAINE": IOSLocalizedText(
        ru: "Украина",
        ua: "Україна",
        en: "Ukraine"
    ),
    "LOADING_LISTINGS": IOSLocalizedText(
        ru: "Загрузка объявлений…",
        ua: "Завантаження оголошень…",
        en: "Loading listings…"
    ),
    "FAILED_TO_LOAD_DATA": IOSLocalizedText(
        ru: "Не удалось загрузить данные",
        ua: "Не вдалося завантажити дані",
        en: "Failed to load data"
    ),
    "COUNTRY_VALUE": IOSLocalizedText(
        ru: "Страна: %s",
        ua: "Країна: %s",
        en: "Country: %s"
    ),
    "SIZE_VALUE": IOSLocalizedText(
        ru: "Размер: %s",
        ua: "Розмір: %s",
        en: "Size: %s"
    ),    "ACCEPT_AND_CONTINUE": IOSLocalizedText(
        ru: "Принять и продолжить",
        ua: "Прийняти та продовжити",
        en: "Accept and continue"
    ),
    "MESSAGE_TOO_SHORT": IOSLocalizedText(
        ru: "Сообщение слишком короткое.",
        ua: "Повідомлення надто коротке.",
        en: "The message is too short."
    ),
    "MESSAGE_TOO_LONG": IOSLocalizedText(
        ru: "Сообщение слишком длинное.",
        ua: "Повідомлення надто довге.",
        en: "The message is too long."
    ),
    "FEEDBACK_PROMPT": IOSLocalizedText(
        ru: "Напишите предложение, сообщите об ошибке или оставьте отзыв о сервисе.",
        ua: "Напишіть пропозицію, повідомте про помилку або залиште відгук про сервіс.",
        en: "Share a suggestion, report a bug, or leave feedback about the service."
    ),
    "FEEDBACK_TITLE": IOSLocalizedText(
        ru: "Предложения и обратная связь",
        ua: "Пропозиції та зворотний зв'язок",
        en: "Suggestions and feedback"
    ),    "INVALID_BOOST_PERIOD": IOSLocalizedText(
        ru: "Недопустимый срок поднятия.",
        ua: "Недопустимий строк підняття.",
        en: "Invalid boost period."
    ),
    "FAILED_TO_PREPARE_PAYMENT": IOSLocalizedText(
        ru: "Не удалось подготовить оплату.",
        ua: "Не вдалося підготувати оплату.",
        en: "Failed to prepare payment."
    ),
    "GO_TO_PAYMENT": IOSLocalizedText(
        ru: "Перейти к оплате",
        ua: "Перейти до оплати",
        en: "Go to payment"
    ),
    "PROMOTION": IOSLocalizedText(
        ru: "Продвижение",
        ua: "Просування",
        en: "Promotion"
    ),    "NO_LISTINGS_YET": IOSLocalizedText(
        ru: "Пока нет объявлений",
        ua: "Поки немає оголошень",
        en: "No listings yet"
    ),
    "NOTHING_FOUND": IOSLocalizedText(
        ru: "Ничего не найдено",
        ua: "Нічого не знайдено",
        en: "Nothing found"
    ),    "RUSSIA": IOSLocalizedText(
        ru: "Россия",
        ua: "Росія",
        en: "Russia"
    ),
    "FAILED_TO_GET_GOOGLE_CLIENT_ID": IOSLocalizedText(
        ru: "Не удалось получить Google Client ID.",
        ua: "Не вдалося отримати Google Client ID.",
        en: "Failed to get Google Client ID."
    ),
    "FAILED_TO_OPEN_GOOGLE_SIGN_IN": IOSLocalizedText(
        ru: "Не удалось открыть окно входа Google.",
        ua: "Не вдалося відкрити вікно входу Google.",
        en: "Failed to open Google sign-in."
    ),
    "PACKAGING_PHOTO_EXIF_SAME_CAMERA_HINT": IOSLocalizedText(
        ru: "Фото должно содержать EXIF камеры и быть сделано той же камерой, что использовалась для объявления.",
        ua: "Фото має містити EXIF камери та бути зроблене тією самою камерою, що використовувалася для оголошення.",
        en: "The photo must contain camera EXIF data and be taken with the same camera used for the listing."
    ),
]

func iosT(
    _ language: IOSAppLanguage,
    _ key: String,
    _ arguments: CVarArg...
) -> String {
    guard let value = iosTranslations[key] else {
        return key
    }

    let template: String

    switch language {
    case .ru: template = value.ru
    case .ua: template = value.ua
    case .en: template = value.en
    }

    guard !arguments.isEmpty else {
        return template
    }

    return String(
        format: template,
        locale: Locale(identifier: "en_US_POSIX"),
        arguments: arguments
    )
}

func iosLanguage(
    from rawValue: String
) -> IOSAppLanguage {
    IOSAppLanguage(rawValue: rawValue) ?? .ru
}
func iosCurrentLanguage() -> IOSAppLanguage {
    iosLanguage(
        from: UserDefaults.standard.string(
            forKey: "appLanguage"
        ) ?? "RU"
    )
}
