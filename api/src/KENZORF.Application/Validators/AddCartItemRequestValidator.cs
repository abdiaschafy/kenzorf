using FluentValidation;
using KENZORF.Application.DTOs.Cart;

namespace KENZORF.Application.Validators;

public sealed class AddCartItemRequestValidator : AbstractValidator<AddCartItemRequest>
{
    public AddCartItemRequestValidator()
    {
        RuleFor(x => x.ProductVariantId)
            .NotEmpty().WithMessage("cart.productVariantId.required");

        RuleFor(x => x.Quantity)
            .GreaterThan(0).WithMessage("cart.quantity.min")
            .LessThanOrEqualTo(99).WithMessage("cart.quantity.max");
    }
}
