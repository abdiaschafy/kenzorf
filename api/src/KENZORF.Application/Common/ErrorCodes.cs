namespace KENZORF.Application.Common;

/// <summary>Codes/clés d'erreur stables renvoyés par l'API (traduits côté client via i18n).</summary>
public static class ErrorCodes
{
    public const string ValidationFailed = "common.validationFailed";
    public const string InternalError = "common.internalError";
    public const string Unauthorized = "auth.unauthorized";
    public const string Forbidden = "common.forbidden";

    public const string AuthInvalidCredentials = "auth.invalidCredentials";
    public const string AuthEmailAlreadyUsed = "auth.emailAlreadyUsed";
    public const string AuthInvalidRefreshToken = "auth.invalidRefreshToken";
    public const string AuthRegistrationFailed = "auth.registrationFailed";
    public const string AuthUserNotFound = "auth.userNotFound";

    public const string CategoryNotFound = "categories.notFound";
    public const string CategorySlugTaken = "categories.slugTaken";
    public const string CategoryHasProducts = "categories.hasProducts";

    public const string ProductNotFound = "products.notFound";
    public const string ProductSlugTaken = "products.slugTaken";
    public const string ProductVariantNotFound = "products.variantNotFound";
    public const string ProductVariantSkuTaken = "products.variantSkuTaken";

    public const string CartNotFound = "cart.notFound";
    public const string CartItemNotFound = "cart.itemNotFound";
    public const string CartEmpty = "cart.empty";
    public const string CartInsufficientStock = "cart.insufficientStock";

    public const string OrderNotFound = "orders.notFound";
    public const string OrderNotCancelable = "orders.notCancelable";
    public const string OrderInvalidStatusTransition = "orders.invalidStatusTransition";
    public const string OrderInsufficientStock = "orders.insufficientStock";

    public const string AddressNotFound = "addresses.notFound";

    public const string PaymentNotFound = "payments.notFound";
    public const string PaymentGatewayUnavailable = "payments.gatewayUnavailable";
    public const string PaymentInitiationFailed = "payments.initiationFailed";
    public const string PaymentInvalidSignature = "payments.invalidSignature";

    public const string CustomerNotFound = "customers.notFound";

    public const string UploadInvalidFile = "uploads.invalidFile";
}
