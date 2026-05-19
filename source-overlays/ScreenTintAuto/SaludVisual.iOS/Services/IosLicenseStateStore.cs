using System.Text.Json;
using SaludVisual.Shared.Licensing;

namespace SaludVisual.iOS.Services;

public sealed class IosLicenseStateStore
{
    private const string LicenseStateKey = "saludvisual.license.state";
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public async Task<LocalLicenseState?> LoadAsync()
    {
        var json = await SecureStorage.GetAsync(LicenseStateKey);
        if (string.IsNullOrWhiteSpace(json))
        {
            return null;
        }

        try
        {
            return JsonSerializer.Deserialize<LocalLicenseState>(json, JsonOptions);
        }
        catch
        {
            await ClearAsync();
            return null;
        }
    }

    public async Task SaveAsync(LocalLicenseState state)
    {
        var json = JsonSerializer.Serialize(state, JsonOptions);
        await SecureStorage.SetAsync(LicenseStateKey, json);
    }

    public Task ClearAsync()
    {
        SecureStorage.Remove(LicenseStateKey);
        return Task.CompletedTask;
    }
}
