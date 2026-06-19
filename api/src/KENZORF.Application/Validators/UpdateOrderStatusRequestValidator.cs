using FluentValidation;
using KENZORF.Application.DTOs.Admin;

namespace KENZORF.Application.Validators;

public sealed class UpdateOrderStatusRequestValidator : AbstractValidator<UpdateOrderStatusRequest>
{
    public UpdateOrderStatusRequestValidator()
    {
        RuleFor(x => x.Status)
            .IsInEnum().WithMessage("orders.status.invalid");
    }
}
