using SaludVisual.iOS.Services;
using SaludVisual.Shared.Licensing;

namespace SaludVisual.iOS;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();
        builder
            .UseMauiApp<App>();

        builder.Services.AddSingleton<LicenseApiClient>();
        builder.Services.AddSingleton<IosLicenseStateStore>();
        builder.Services.AddSingleton<DeviceFingerprintService>();
        builder.Services.AddSingleton<App>();

        return builder.Build();
    }
}
