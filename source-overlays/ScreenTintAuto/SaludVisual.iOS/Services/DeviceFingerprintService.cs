using System.Security.Cryptography;
using System.Text;

namespace SaludVisual.iOS.Services;

public sealed class DeviceFingerprintService
{
    private const string InstallationIdKey = "saludvisual.installation.id";

    public async Task<string> GetFingerprintAsync()
    {
        var installationId = await SecureStorage.GetAsync(InstallationIdKey);
        if (string.IsNullOrWhiteSpace(installationId))
        {
            installationId = Guid.NewGuid().ToString("N");
            await SecureStorage.SetAsync(InstallationIdKey, installationId);
        }

        var raw = $"ios:{installationId}";
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(raw));
        return "ios:" + Convert.ToHexString(hash).ToLowerInvariant();
    }
}
