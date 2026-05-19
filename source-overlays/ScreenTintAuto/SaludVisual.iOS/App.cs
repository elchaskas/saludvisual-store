using SaludVisual.iOS.Pages;
using SaludVisual.iOS.Services;
using SaludVisual.Shared.Licensing;

namespace SaludVisual.iOS;

public sealed class App : Application
{
    private readonly LicenseApiClient _licenseApiClient;
    private readonly IosLicenseStateStore _stateStore;
    private readonly DeviceFingerprintService _fingerprintService;

    public App(
        LicenseApiClient licenseApiClient,
        IosLicenseStateStore stateStore,
        DeviceFingerprintService fingerprintService)
    {
        _licenseApiClient = licenseApiClient;
        _stateStore = stateStore;
        _fingerprintService = fingerprintService;

        MainPage = new NavigationPage(new StartupPage());
    }

    protected override async void OnStart()
    {
        base.OnStart();
        await NavigateToInitialPageAsync().ConfigureAwait(false);
    }

    private async Task NavigateToInitialPageAsync()
    {
        var state = await _stateStore.LoadAsync().ConfigureAwait(false);
        var isValid = false;

        if (state is not null)
        {
            var validation = await _licenseApiClient
                .ValidateAsync(state.LicenseKey, state.DeviceFingerprint)
                .ConfigureAwait(false);

            isValid = validation.Valid;
            if (isValid)
            {
                await _stateStore.SaveAsync(state with
                {
                    LastValidatedUtc = DateTimeOffset.UtcNow
                }).ConfigureAwait(false);
            }
        }

        await MainThread.InvokeOnMainThreadAsync(() =>
        {
            MainPage = new NavigationPage(
                isValid
                    ? new DashboardPage(_licenseApiClient, _stateStore, _fingerprintService)
                    : new LicenseActivationPage(_licenseApiClient, _stateStore, _fingerprintService));
        });
    }
}
