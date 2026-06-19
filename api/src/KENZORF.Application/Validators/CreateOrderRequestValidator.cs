using FluentValidation;
using KENZORF.Application.Common;
using KENZORF.Application.DTOs.Orders;

namespace KENZORF.Application.Validators;

public sealed class CreateOrderRequestValidator : AbstractValidator<CreateOrderRequest>
{
    public CreateOrderRequestValidator(IValidator<DTOs.Addresses.AddressRequest> addressValidator)
    {
        RuleFor(x => x.ShippingAddress)
            .NotNull().WithMessage("orders.shippingAddress.required")
            .SetValidator(addressValidator!);

        RuleFor(x => x.CustomerNote)
            .MaximumLength(1000).WithMessage("orders.customerNote.tooLong")
            .When(x => !string.IsNullOrWhiteSpace(x.CustomerNote));

        RuleFor(x => x.PaymentMethod)
            .Must(PaymentMethods.IsValid).WithMessage("orders.paymentMethod.invalid");
    }
}
