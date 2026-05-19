using SaludVisual.iOS.Services;
using SaludVisual.Shared;
using SaludVisual.Shared.Licensing;

namespace SaludVisual.iOS.Pages;

public sealed class LicenseActivationPage : ContentPage
{
    private readonly LicenseApiClient _licenseApiClient;
    private readonly IosLicenseStateStore _stateStore;
    private readonly DeviceFingerprintService _fingerprintService;
    private readonly Entry _licenseEntry;
    private readonly Button _activateButton;
    private readonly Label _statusLabel;

    public LicenseActivationPage(
        LicenseApiClient licenseApiClient,
        IosLicenseStateStore stateStore,
        DeviceFingerprintService fingerprintService)
    {
        _licenseApiClient = licenseApiClient;
        _stateStore = stateStore;
        _fingerprintService = fingerprintService;

        Title = "Activacion";
        BackgroundColor = Color.FromArgb("#F5F7FB");

        _licenseEntry = new Entry
        {
            Placeholder = "SV-XXXX-XXXX-XXXX",
            TextTransform = TextTransform.Uppercase,
            Keyboard = Keyboard.Text,
            ReturnType = ReturnType.Done
        };

        _activateButton = new Button
        {
            Text = "Activar licencia",
            BackgroundColor = Color.FromArgb("#1D6F91"),
            TextColor = Colors.White,
            CornerRadius = 12
        };
        _activateButton.Clicked += async (_, _) => await ActivateAsync();

        _statusLabel = new Label
        {
            TextColor = Color.FromArgb("#6B7280"),
            FontSize = 14
        };

        Content = new ScrollView
        {
            Content = new VerticalStackLayout
            {
                Padding = new Thickness(24),
                Spacing = 16,
                Children =
                {
                    Ui.Header("Salud Visual para iPhone", "Activa tu licencia y configura los filtros nativos de iOS."),
                    Ui.Card(
                        new Label
                        {
                            Text = "En iPhone usamos las herramientas propias de iOS: Filtros de color, Reducir punto blanco, Night Shift y Atajos.",
                            TextColor = Color.FromArgb("#374151"),
                            FontSize = 15
                        }),
                    Ui.Card(
                        new Label { Text = "Clave de licencia", FontAttributes = FontAttributes.Bold },
                        _licenseEntry,
                        _activateButton,
                        _statusLabel),
                    Ui.LinkButton("Comprar o recuperar licencia", ProductInfo.WebsiteUrl)
                }
            }
        };
    }

    private async Task ActivateAsync()
    {
        var licenseKey = _licenseEntry.Text?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(licenseKey))
        {
            _statusLabel.Text = "Introduce una clave de licencia.";
            return;
        }

        _activateButton.IsEnabled = false;
        _statusLabel.Text = "Activando...";

        var fingerprint = await _fingerprintService.GetFingerprintAsync();
        var result = await _licenseApiClient.ActivateAsync(licenseKey, fingerprint);

        if (!result.Success)
        {
            _statusLabel.Text = $"No se pudo activar: {result.Error ?? "error desconocido"}";
            _activateButton.IsEnabled = true;
            return;
        }

        await _stateStore.SaveAsync(new LocalLicenseState(
            LicenseApiClient.NormalizeLicenseKey(licenseKey),
            fingerprint,
            DateTimeOffset.UtcNow,
            DateTimeOffset.UtcNow));

        await Navigation.PushAsync(new DashboardPage(_licenseApiClient, _stateStore, _fingerprintService));
        Navigation.RemovePage(this);
    }
}
