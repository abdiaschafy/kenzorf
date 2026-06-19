using FluentValidation;
using KENZORF.Application.DTOs.Admin;

namespace KENZORF.Application.Validators;

public sealed class VariantRequestValidator : AbstractValidator<VariantRequest>
{
    public VariantRequestValidator()
    {
        RuleFor(x => x.Sku)
            .NotEmpty().WithMessage("products.variant.sku.required")
            .MaximumLength(64).WithMessage("products.variant.sku.tooLong");

        RuleFor(x => x.Color)
            .NotEmpty().WithMessage("products.variant.color.required")
            .MaximumLength(60).WithMessage("products.variant.color.tooLong");

        RuleFor(x => x.Size)
            .MaximumLength(30).WithMessage("products.variant.size.tooLong");

        RuleFor(x => x.ColorHex)
            .Matches("^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$").WithMessage("products.variant.colorHex.invalid")
            .When(x => !string.IsNullOrWhiteSpace(x.ColorHex));

        RuleFor(x => x.Price)
            .GreaterThanOrEqualTo(0).WithMessage("products.variant.price.min")
            .When(x => x.Price.HasValue);

        RuleFor(x => x.StockQuantity)
            .GreaterThanOrEqualTo(0).WithMessage("products.variant.stock.min");
    }
}
