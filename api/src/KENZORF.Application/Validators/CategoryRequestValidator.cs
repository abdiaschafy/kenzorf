using FluentValidation;
using KENZORF.Application.DTOs.Admin;

namespace KENZORF.Application.Validators;

public sealed class CategoryRequestValidator : AbstractValidator<CategoryRequest>
{
    public CategoryRequestValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage("categories.name.required")
            .MaximumLength(120).WithMessage("categories.name.tooLong");

        RuleFor(x => x.Slug)
            .MaximumLength(140).WithMessage("categories.slug.tooLong")
            .When(x => !string.IsNullOrWhiteSpace(x.Slug));

        RuleFor(x => x.Description)
            .MaximumLength(600).WithMessage("categories.description.tooLong")
            .When(x => !string.IsNullOrWhiteSpace(x.Description));
    }
}
