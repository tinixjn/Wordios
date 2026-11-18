# Wordios

Wordios — навчальний iOS-застосунок для вивчення англійської лексики за допомогою тематичних карток. Цільова аудиторія — люди, які вивчають англійську на рівнях A1–C2.

## Практична робота №1: основи Swift, проєкт та Git

- `Models.swift` (Крістіна): `EnglishLevel` і `LearningStatus` (`enum`), `WordCard` (`struct` із `Optional`-транскрипцією, синонімами та методом `updateStatus(to:)`), протокол `DeckManageable`.
- `WordModule.swift` (Діана): `class WordModule`, що реалізує `DeckManageable`; зберігає тему (`title`), рівень (`level`) та колекцію карток (`cards`). Містить `addCard(_:)`, `filterCards(by:)`, `calculateProgress()`, `findCard(term:)`, `updateCardStatus(id:to:)` та `displayTranscription(for:)`.
- `DemoData.swift` (Діана): приклад модуля «Подорожі» з чотирма словами, зміною статусу, фільтрацією та виведенням результатів у консоль.

## Використані конструкції Swift

| Конструкція         | Де знайти                                                             |
| ------------------- | --------------------------------------------------------------------- |
| `enum`              | `Models.swift`: `EnglishLevel`, `LearningStatus`                      |
| `struct`            | `Models.swift`: `WordCard`                                            |
| `class`             | `WordModule.swift`: `WordModule`                                      |
| `protocol`          | `Models.swift`: `DeckManageable`                                      |
| `Optional`          | `Models.swift`: `transcription: String?`                              |
| `if let`            | `WordModule.swift`: `displayTranscription(for:)`                      |
| `guard`             | `WordModule.swift`: `calculateProgress()`, `updateCardStatus(id:to:)` |
| Масив та фільтрація | `WordModule.swift`: `cards`, `filterCards(by:)`                       |

## Як запустити

1. Відкрити проєкт Wordios у Xcode.
2. Додати `Models.swift`, `WordModule.swift` та `DemoData.swift` до цільового застосунку (target), якщо вони ще не включені.
3. У вже наявному `WordiosApp.swift` викликати `DemoData.runPracticalOneDemo()` в `init()` під `#if DEBUG` (не створювати другий `@main`).
4. Обрати сумісний iOS Simulator, натиснути **Run**, перевірити консоль Xcode.

Очікуваний результат: 4 слова у модулі, 1 вивчене слово, прогрес `25.0%`, безпечне виведення відсутньої транскрипції.

## Git

Робота ведеться в окремих `feat/...` гілках із Pull Request у `main`. Тег `practical-1` ставиться після злиття і перевірки **обох** частин практичної роботи №1.
