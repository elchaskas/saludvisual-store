using System.Text.Json.Serialization;

namespace SaludVisual.Shared.Licensing;

public sealed record LicenseActivationRequest(
    [property: JsonPropertyName("licenseKey")] string LicenseKey,
    [property: JsonPropertyName("deviceFingerprint")] string DeviceFingerprint);

public sealed record LicenseValidationRequest(
    [property: JsonPropertyName("licenseKey")] string LicenseKey,
    [property: JsonPropertyName("deviceFingerprint")] string DeviceFingerprint);

public sealed record LicenseDeactivationRequest(
    [property: JsonPropertyName("licenseKey")] string LicenseKey,
    [property: JsonPropertyName("deviceFingerprint")] string DeviceFingerprint);

public sealed record LicenseActivationResult(
    bool Success,
    string? Error,
    int? MaxActivations);

public sealed record LicenseValidationResult(
    bool Valid,
    string? Error);

public sealed record LocalLicenseState(
    string LicenseKey,
    string DeviceFingerprint,
    DateTimeOffset ActivatedUtc,
    DateTimeOffset LastValidatedUtc);

internal sealed record LicenseApiResponse(
    [property: JsonPropertyName("ok")] bool? Ok,
    [property: JsonPropertyName("valid")] bool? Valid,
    [property: JsonPropertyName("error")] string? Error,
    [property: JsonPropertyName("maxActivations")] int? MaxActivations);
