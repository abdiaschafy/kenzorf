using FluentValidation;
using KENZORF.Application.DTOs.Cart;

namespace KENZORF.Application.Validators;

public sealed class UpdateCartItemRequestValidator : AbstractValidator<UpdateCartItemRequest>
{
    public UpdateCartItemRequestValidator()
    {
        RuleFor(x => x.Quantity)
            .GreaterThan(0).WithMessage("cart.quantity.min")
            .LessThanOrEqualTo(99).WithMessage("cart.quantity.max");
    }
}
