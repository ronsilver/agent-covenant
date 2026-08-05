# Jetpack Compose Patterns

## State Management
```kotlin
class CheckoutViewModel : ViewModel() {
    private val _state = MutableStateFlow(CheckoutState.Idle)
    val state: StateFlow<CheckoutState> = _state.asStateFlow()

    fun submitPayment(card: CardData) {
        viewModelScope.launch {
            _state.update { CheckoutState.Loading }
            try {
                val result = paymentRepo.createPayment(card)
                _state.update { CheckoutState.Success(result) }
            } catch (e: Exception) {
                _state.update { CheckoutState.Error(e.message ?: "Unknown error") }
            }
        }
    }
}

sealed class CheckoutState {
    object Idle : CheckoutState()
    object Loading : CheckoutState()
    data class Success(val result: Result) : FormState()
    data class Error(val message: String) : CheckoutState()
}
```

## Compose UI
```kotlin
@Composable
fun CheckoutScreen(viewModel: CheckoutViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    when (state) {
        is CheckoutState.Idle -> PaymentForm { viewModel.submitPayment(it) }
        is CheckoutState.Loading -> LoadingIndicator()
        is FormState.Success -> SuccessScreen((state as FormState.Success).result)
        is CheckoutState.Error -> ErrorBanner((state as CheckoutState.Error).message)
    }
}
```

## Navigation
```kotlin
NavHost(navController, startDestination = "form") {
    composable("form") { FormScreen(navController) }
    composable("success/{paymentId}") { backStackEntry ->
        val paymentId = backStackEntry.arguments?.getString("paymentId")
        SuccessScreen(paymentId)
    }
}
```

## Coroutine Scopes
- viewModelScope: auto-cancelled on ViewModel clear
- rememberCoroutineScope: for UI-triggered coroutines
- LaunchedEffect: side effects, lifecycle-aware
