using System.Net.Http.Json;

namespace SaludVisual.Shared.Licensing;

public sealed class LicenseApiClient
{
    private readonly HttpClient _httpClient;

    public LicenseApiClient(HttpClient? httpClient = null)
    {
        _httpClient = httpClient ?? new HttpClient();
        _httpClient.BaseAddress ??= new Uri(ProductInfo.LicenseApiBaseUrl);

        if (!_httpClient.DefaultRequestHeaders.UserAgent.Any())
        {
            _httpClient.DefaultRequestHeaders.UserAgent.ParseAdd("SaludVisual-iOS/license");
        }
    }

    public async Task<LicenseActivationResult> ActivateAsync(
        string licenseKey,
        string deviceFingerprint,
        CancellationToken cancellationToken = default)
    {
        var request = new LicenseActivationRequest(
            NormalizeLicenseKey(licenseKey),
            NormalizeDeviceFingerprint(deviceFingerprint));

        try
        {
            using var response = await _httpClient
                .PostAsJsonAsync("/v1/licenses/activate", request, cancellationToken)
                .ConfigureAwait(false);

            var body = await ReadResponseAsync(response, cancellationToken).ConfigureAwait(false);
            return response.IsSuccessStatusCode
                ? new LicenseActivationResult(true, null, body?.MaxActivations)
                : new LicenseActivationResult(false, body?.Error ?? response.ReasonPhrase, body?.MaxActivations);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            return new LicenseActivationResult(false, ex.Message, null);
        }
    }

    public async Task<LicenseValidationResult> ValidateAsync(
        string licenseKey,
        string deviceFingerprint,
        CancellationToken cancellationToken = default)
    {
        var request = new LicenseValidationRequest(
            NormalizeLicenseKey(licenseKey),
            NormalizeDeviceFingerprint(deviceFingerprint));

        try
        {
            using var response = await _httpClient
                .PostAsJsonAsync("/v1/licenses/validate", request, cancellationToken)
                .ConfigureAwait(false);

            var body = await ReadResponseAsync(response, cancellationToken).ConfigureAwait(false);
            var valid = response.IsSuccessStatusCode && (body?.Valid ?? body?.Ok ?? true);
            return new LicenseValidationResult(valid, valid ? null : body?.Error ?? response.ReasonPhrase);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            return new LicenseValidationResult(false, ex.Message);
        }
    }

    public async Task<bool> DeactivateAsync(
        string licenseKey,
        string deviceFingerprint,
        CancellationToken cancellationToken = default)
    {
        var request = new LicenseDeactivationRequest(
            NormalizeLicenseKey(licenseKey),
            NormalizeDeviceFingerprint(deviceFingerprint));

        try
        {
            using var response = await _httpClient
                .PostAsJsonAsync("/v1/licenses/deactivate", request, cancellationToken)
                .ConfigureAwait(false);

            return response.IsSuccessStatusCode;
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
        {
            return false;
        }
    }

    public static string NormalizeLicenseKey(string licenseKey)
    {
        return licenseKey.Trim().ToUpperInvariant();
    }

    public static string NormalizeDeviceFingerprint(string deviceFingerprint)
    {
        return deviceFingerprint.Trim();
    }

    private static async Task<LicenseApiResponse?> ReadResponseAsync(
        HttpResponseMessage response,
        CancellationToken cancellationToken)
    {
        try
        {
            return await response.Content
                .ReadFromJsonAsync<LicenseApiResponse>(cancellationToken: cancellationToken)
                .ConfigureAwait(false);
        }
        catch
        {
            return null;
        }
    }
}
