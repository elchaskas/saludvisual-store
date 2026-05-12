using SaludVisual.iOS.Services;
using SaludVisual.Shared;
using SaludVisual.Shared.Licensing;

namespace SaludVisual.iOS.Pages;

public sealed class DashboardPage : ContentPage
{
    private readonly LicenseApiClient _licenseApiClient;
    private readonly IosLicenseStateStore _stateStore;
    private readonly DeviceFingerprintService _fingerprintService;

    public DashboardPage(
        LicenseApiClient licenseApiClient,
        IosLicenseStateStore stateStore,
        DeviceFingerprintService fingerprintService)
    {
        _licenseApiClient = licenseApiClient;
        _stateStore = stateStore;
        _fingerprintService = fingerprintService;
        Title = "Salud Visual";
        BackgroundColor = Color.FromArgb("#F5F7FB");

        var filtersButton = Ui.PrimaryButton("Configurar filtros de iOS");
        filtersButton.Clicked += async (_, _) => await Navigation.PushAsync(new FilterGuidePage());

        var shortcutsButton = Ui.SecondaryButton("Automatizar con Atajos");
        shortcutsButton.Clicked += async (_, _) => await Navigation.PushAsync(new ShortcutGuidePage());

        var supportButton = Ui.SecondaryButton("Web y soporte");
        supportButton.Clicked += async (_, _) => await Launcher.OpenAsync(ProductInfo.WebsiteUrl);

        Content = new ScrollView
        {
            Content = new VerticalStackLayout
            {
                Padding = new Thickness(24),
                Spacing = 16,
                Children =
                {
                    Ui.Header("Salud Visual iPhone", $"Version {ProductInfo.Version}"),
                    Ui.Card(
                        new Label
                        {
                            Text = "Licencia activa en este iPhone.",
                            FontAttributes = FontAttributes.Bold,
                            TextColor = Color.FromArgb("#0F766E")
                        },
                        new Label
                        {
                            Text = "iOS no permite a apps de terceros aplicar un filtro encima de todo el sistema. Esta app te guia para usar los filtros nativos y crear automatizaciones seguras.",
                            TextColor = Color.FromArgb("#374151")
                        }),
                    filtersButton,
                    shortcutsButton,
                    supportButton,
                    Ui.SecondaryButton("Desactivar licencia en este iPhone", async () => await ClearLicenseAsync())
                }
            }
        };
    }

    private async Task ClearLicenseAsync()
    {
        var confirm = await DisplayAlert(
            "Desactivar licencia",
            "Se borrara la activacion local. Podras volver a activar introduciendo la clave.",
            "Continuar",
            "Cancelar");

        if (!confirm)
        {
            return;
        }

        await _stateStore.ClearAsync();
        Application.Current!.MainPage = new NavigationPage(
            new LicenseActivationPage(_licenseApiClient, _stateStore, _fingerprintService));
    }
}
