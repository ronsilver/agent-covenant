# Android/Kotlin Testing

## Unit Tests (JUnit 5 + MockK)
```kotlin
class CheckoutViewModelTest {
    @MockK
    private lateinit var paymentRepo: PaymentRepository

    @BeforeEach
    fun setup() {
        MockKAnnotations.init(this)
    }

    @Test
    fun `submitPayment updates state to Success on approval`() = runTest {
        coEvery { paymentRepo.createPayment(any()) } returns Payment("pay_123", "approved")
        val viewModel = CheckoutViewModel(paymentRepo)
        viewModel.submitPayment(CardData("4111111111111111", "12/30", "123"))
        advanceUntilIdle()
        val state = viewModel.state.value
        assertIs<CheckoutState.Success>(state)
    }
}
```

## Instrumented Tests (Espresso)
```kotlin
@RunWith(AndroidJUnit4::class)
class CheckoutUITest {
    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun payButton_showsLoadingIndicator_onClick() {
        composeTestRule.setContent { CheckoutScreen() }
        composeTestRule
            .onNodeWithText("Pay")
            .performClick()
        composeTestRule
            .onNodeWithTag("loading-spinner")
            .assertIsDisplayed()
    }
}
```

## Test Rules
- NEVER block main thread in tests
- runTest for coroutine testing (virtual time)
- advanceUntilIdle() after launching coroutines
- Use test dispatchers (StandardTestDispatcher)
